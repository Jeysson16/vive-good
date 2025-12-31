import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'formatted_text_widget.dart';
import 'typewriter_text_widget.dart';

import 'enhanced_habits_dropdown_widget.dart';
import '../../pages/habits/new_habit_screen.dart';
import '../../blocs/assistant/assistant_bloc.dart';
import '../../blocs/assistant/assistant_state.dart';
import '../../blocs/assistant/assistant_event.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget para mostrar mensajes de chat individuales
class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final List<UserHabit> existingUserHabits;
  final Function(String messageId, String newContent)? onEdit;
  final Function(String messageId)? onDelete;
  final Function(String habitName, Map<String, dynamic> habitData)?
  onCreateHabit;
  final Function()? onViewMoreAdvice;
  final Function()? onHabitsUpdated;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.existingUserHabits = const [],
    this.onEdit,
    this.onDelete,
    this.onCreateHabit,
    this.onViewMoreAdvice,
    this.onHabitsUpdated,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _editFocusNode = FocusNode();
  final bool _showSuggestedHabits = false;
  List<Map<String, dynamic>>? _cachedSuggestedHabits;
  
  // Estado del feedback
  String? _currentFeedback; // 'like' o 'dislike'
  bool _isLoadingFeedback = false;
  
  // Control del efecto typewriter
  bool _shouldShowTypewriter = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _loadExistingFeedback();
    
    // Determinar si debe mostrar efecto typewriter
    _shouldShowTypewriter = _shouldUseTypewriterEffect();
  }

  Future<void> _loadExistingFeedback() async {
    // Solo cargar feedback para mensajes del asistente
    if (widget.message.type != MessageType.assistant) return;
    
    try {
      final chatRepository = context.read<ChatRepository>();
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user != null) {
        final feedback = await chatRepository.getMessageFeedback(
          userId: user.id,
          messageId: widget.message.id,
        );
        
        if (mounted) {
          setState(() {
            _currentFeedback = feedback;
          });
        }
      }
    } catch (e) {
      print('Error loading feedback: $e');
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.message.content;
    });
  }

  void _saveEdit() {
    final newContent = _editController.text.trim();
    if (newContent.isNotEmpty && newContent != widget.message.content) {
      widget.onEdit?.call(widget.message.id, newContent);
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensaje copiado'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.type == MessageType.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mensaje principal
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isUser) ..._buildAssistantMessage(),
            if (isUser) ..._buildUserMessage(),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildUserMessage() {
    return [
      // Espaciador para alinear a la derecha
      const SizedBox(width: 48),

      // Contenido del mensaje
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mensaje
            GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _isEditing ? _buildEditField() : _buildMessageContent(),
              ),
            ),

            // Botones de edición (si está editando)
            if (_isEditing) ..._buildEditButtons(),

            // Timestamp
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.message.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),

      const SizedBox(width: 8),

      // Avatar del usuario
      _buildUserAvatar(),
    ];
  }

  List<Widget> _buildAssistantMessage() {
    return [
      // Avatar del asistente
      _buildAssistantAvatar(),

      const SizedBox(width: 8),

      // Contenido del mensaje
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje
            GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: _buildMessageContent(),
              ),
            ),

            // Timestamp
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.message.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),

      // Espaciador para alinear a la izquierda
      const SizedBox(width: 48),
    ];
  }

  Widget _buildMessageContent() {
    final isUser = widget.message.type == MessageType.user;
    final meta = widget.message.metadata;
    final isImage =
        meta != null && meta['type'] == 'image' && meta['url'] is String;
    final imageUrl = isImage ? meta['url'] as String : null;

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: 240,
          // Altura dinámica según relación de aspecto, limitar por diseño
          height: 180,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              'No se pudo cargar la imagen',
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : const Color(0xFF333333),
              ),
            );
          },
        ),
      );
    }

    if (isUser) {
      return Text(
        widget.message.content,
        style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
      );
    } else {
      // Para mensajes del asistente, usar el widget de formato con efecto typewriter si es necesario
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shouldShowTypewriter
              ? TypewriterTextWidget(
                  key: ValueKey('typewriter_${widget.message.id}'),
                  text: widget.message.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    height: 1.4,
                  ),
                  speed: const Duration(milliseconds: 30),
                  autoStart: true,
                )
              : FormattedTextWidget(
                  text: widget.message.content,
                  baseStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    height: 1.4,
                  ),
                ),

          // Desplegable de hábitos recomendados
          _buildSuggestedHabitsDropdown(),

          // Botones de acción para mensajes del asistente (movidos debajo)
          if (_shouldShowActionButtons()) ..._buildActionButtons(),
        ],
      );
    }
  }

  bool _shouldShowActionButtons() {
    // Mostrar botones si el mensaje contiene consejos de salud o recomendaciones
    final content = widget.message.content.toLowerCase();

    // Palabras clave que indican consejos de salud digestiva
    final healthKeywords = [
      'dolor',
      'estómago',
      'gastritis',
      'acidez',
      'reflujo',
      'comidas',
      'comer',
      'alimentación',
      'dieta',
      'evita',
      'evitar',
      'reduce',
      'elimina',
      'hábito',
      'rutina',
      'horario',
      'recomend',
      'consejo',
      'sugiero',
      'importante',
      'agua',
      'hidrat',
      'bebe',
      'ejercicio',
      'camina',
      'actividad',
      'estrés',
      'relajación',
      'descanso',
      'sueño',
      'probióticos',
      'suplementos',
      'medicamento',
    ];

    // Verificar si contiene al menos 2 palabras clave para mayor precisión
    final keywordCount = healthKeywords
        .where((keyword) => content.contains(keyword))
        .length;

    // También mostrar si el mensaje es largo (más de 100 caracteres) y contiene al menos una palabra clave
    final isLongMessage = content.length > 100;
    final hasHealthKeyword = healthKeywords.any(
      (keyword) => content.contains(keyword),
    );

    return keywordCount >= 2 || (isLongMessage && hasHealthKeyword);
  }

  bool _hasSuggestedHabits() {
    print(
      '🔥 DEBUG WIDGET: Verificando hábitos sugeridos para mensaje ${widget.message.id}',
    );
    print('🔥 DEBUG WIDGET: Metadata: ${widget.message.metadata}');

    final hasMetadata = widget.message.metadata != null;
    print('🔥 DEBUG WIDGET: Tiene metadata: $hasMetadata');

    if (hasMetadata) {
      final hasSuggestedHabits =
          widget.message.metadata!['suggestedHabits'] != null;
      print('🔥 DEBUG WIDGET: Tiene suggestedHabits: $hasSuggestedHabits');

      if (hasSuggestedHabits) {
        final habitsList = widget.message.metadata!['suggestedHabits'] as List;
        final isNotEmpty = habitsList.isNotEmpty;
        print(
          '🔥 DEBUG WIDGET: Lista de hábitos no vacía: $isNotEmpty (${habitsList.length} hábitos)',
        );
        return isNotEmpty;
      }
    }

    print('🔥 DEBUG WIDGET: No se encontraron hábitos sugeridos');
    return false;
  }

  List<Widget> _buildActionButtons() {
    return [
      const SizedBox(height: 8),
      // Botones pequeños de acción
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildFeedbackButton(
            icon: _currentFeedback == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
            onPressed: _isLoadingFeedback ? null : () => _likeMessage(),
            tooltip: _currentFeedback == 'like' ? 'Quitar me gusta' : 'Me gusta',
            isActive: _currentFeedback == 'like',
            isLoading: _isLoadingFeedback,
          ),
          const SizedBox(width: 8),
          _buildFeedbackButton(
            icon: _currentFeedback == 'dislike' ? Icons.thumb_down : Icons.thumb_down_outlined,
            onPressed: _isLoadingFeedback ? null : () => _dislikeMessage(),
            tooltip: _currentFeedback == 'dislike' ? 'Quitar no me gusta' : 'No me gusta',
            isActive: _currentFeedback == 'dislike',
            isLoading: _isLoadingFeedback,
          ),
          const SizedBox(width: 8),
          BlocBuilder<AssistantBloc, AssistantState>(
            builder: (context, state) {
              IconData icon;
              String tooltip;
              
              if (widget.message.type == MessageType.assistant) {
                // Para mensajes del asistente, mostrar play/pause
                if (state.isPlayingAudio) {
                  icon = Icons.pause;
                  tooltip = 'Pausar lectura';
                } else {
                  icon = Icons.play_arrow;
                  tooltip = 'Reproducir mensaje';
                }
              } else {
                // Para otros mensajes, mostrar mute/unmute
                icon = state.isTTSMuted ? Icons.volume_off : Icons.volume_up;
                tooltip = state.isTTSMuted ? 'Activar voz' : 'Silenciar voz';
              }
              
              return _buildSmallActionButton(
                icon: icon,
                onPressed: () => _toggleTTS(),
                tooltip: tooltip,
              );
            },
          ),
          const SizedBox(width: 8),
          _buildSmallActionButton(
            icon: Icons.refresh,
            onPressed: () => _regenerateResponse(),
            tooltip: 'Regenerar',
          ),
        ],
      ),
    ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required bool isActive,
    required bool isLoading,
  }) {
    Color backgroundColor;
    Color iconColor;
    Color borderColor;

    if (isActive) {
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.2);
      iconColor = const Color(0xFF4CAF50);
      borderColor = const Color(0xFF4CAF50).withOpacity(0.5);
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
      iconColor = Colors.grey[600]!;
      borderColor = Colors.grey.withOpacity(0.3);
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: isLoading
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField() {
    return TextField(
      controller: _editController,
      focusNode: _editFocusNode,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
      maxLines: null,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _saveEdit(),
    );
  }

  List<Widget> _buildEditButtons() {
    return [
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón Cancelar
          TextButton(
            onPressed: _cancelEditing,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cancelar'),
          ),

          const SizedBox(width: 8),

          // Botón Guardar y Enviar
          ElevatedButton(
            onPressed: _saveEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Guardar y Enviar'),
          ),
        ],
      ),
    ];
  }

  Widget _buildUserAvatar() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        if (profileState is ProfileLoaded) {
          final profile = profileState.profile;
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: _buildSmallProfileImage(profile),
            ),
          );
        } else {
          // Fallback al icono genérico si no hay perfil cargado
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          );
        }
      },
    );
  }

  Widget _buildSmallProfileImage(dynamic profile) {
    if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
      return Image.network(
        profile.profileImageUrl!,
        fit: BoxFit.cover,
        width: 34,
        height: 34,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar(profile);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitialsAvatar(profile);
        },
      );
    } else {
      return _buildInitialsAvatar(profile);
    }
  }

  Widget _buildInitialsAvatar(dynamic profile) {
    String initials = '';
    
    if (profile.firstName != null && profile.firstName!.isNotEmpty) {
      initials += profile.firstName![0].toUpperCase();
    }
    
    if (profile.lastName != null && profile.lastName!.isNotEmpty) {
      initials += profile.lastName![0].toUpperCase();
    }
    
    // Si no hay nombre, usar 'U' de Usuario
    if (initials.isEmpty) {
      initials = 'U';
    }

    return Container(
      width: 34,
      height: 34,
      color: const Color(0xFF4CAF50),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          color: Colors.white,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 20,
            );
          },
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isUser = widget.message.type == MessageType.user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Opciones
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFF666666)),
              title: const Text('Copiar mensaje'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage();
              },
            ),

            if (isUser) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF666666)),
                title: const Text('Editar mensaje'),
                onTap: () {
                  Navigator.pop(context);
                  _startEditing();
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar mensaje',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este mensaje? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call(widget.message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showCreateHabitDialog() {
    final extractedHabits = _extractHabitsFromMessage();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Crear Hábitos Saludables',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lista de hábitos extraídos
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: extractedHabits.length,
                  itemBuilder: (context, index) {
                    final habit = extractedHabits[index];
                    return _buildHabitCard(habit);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  habit['icon'] as IconData? ?? Icons.health_and_safety,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              habit['description'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToCustomizeHabit(habit);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Personalizar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCreateHabit?.call(
                        habit['name'] as String,
                        habit,
                      );
                      _showHabitCreatedSnackbar(habit['name'] as String);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Configurar Recordatorio'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona cuándo quieres recibir recordatorios para seguir estos consejos de salud:',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 16),
            // Aquí se podrían agregar opciones de tiempo
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showReminderSetSnackbar();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractHabitsFromMessage() {
    final content = widget.message.content.toLowerCase();
    final habits = <Map<String, dynamic>>[];

    // Detección inteligente de hábitos alimentarios
    if (_containsAny(content, [
      'comidas pequeñas',
      'porciones pequeñas',
      'comer poco',
      'frecuentes',
      'cada 2-3 horas',
    ])) {
      habits.add({
        'name': 'Comidas pequeñas y frecuentes',
        'description':
            'Comer porciones más pequeñas cada 2-3 horas para reducir la carga en el estómago',
        'icon': Icons.restaurant,
        'frequency': 'Diario',
        'category': 'Alimentación',
        'times_per_day': 5,
        'suggested_times': ['08:00', '10:30', '13:00', '15:30', '18:00'],
      });
    }

    // Detección de alimentos a evitar
    if (_containsAny(content, [
          'evita',
          'evitar',
          'no comas',
          'elimina',
          'reduce',
        ]) &&
        _containsAny(content, [
          'café',
          'alcohol',
          'cítricos',
          'picante',
          'grasa',
          'frituras',
          'condimentos',
        ])) {
      final irritants = _extractIrritants(content);
      habits.add({
        'name': 'Evitar alimentos irritantes',
        'description':
            'Reducir o eliminar ${irritants.join(', ')} que pueden empeorar los síntomas digestivos',
        'icon': Icons.block,
        'frequency': 'Diario',
        'category': 'Alimentación',
        'times_per_day': 1,
        'irritants': irritants,
      });
    }

    // Detección de hidratación
    if (_containsAny(content, [
      'agua',
      'hidrat',
      'bebe',
      'líquidos',
      'infusiones',
    ])) {
      habits.add({
        'name': 'Mantener hidratación adecuada',
        'description':
            'Beber 8 vasos de agua al día para ayudar en la digestión y reducir la acidez',
        'icon': Icons.water_drop,
        'frequency': 'Diario',
        'category': 'Hidratación',
        'times_per_day': 8,
        'suggested_times': [
          '07:00',
          '09:00',
          '11:00',
          '13:00',
          '15:00',
          '17:00',
          '19:00',
          '21:00',
        ],
      });
    }

    // Detección de ejercicio y actividad física
    if (_containsAny(content, [
      'ejercicio',
      'camina',
      'actividad física',
      'movimiento',
      'yoga',
    ])) {
      habits.add({
        'name': 'Actividad física suave',
        'description':
            'Realizar ejercicio ligero como caminar o yoga para mejorar la digestión',
        'icon': Icons.directions_walk,
        'frequency': 'Diario',
        'category': 'Ejercicio',
        'times_per_day': 1,
        'suggested_times': ['18:00'],
        'duration': 30,
      });
    }

    // Detección de manejo del estrés
    if (_containsAny(content, [
      'estrés',
      'relajación',
      'ansiedad',
      'calma',
      'respiración',
      'meditación',
    ])) {
      habits.add({
        'name': 'Técnicas de relajación',
        'description':
            'Practicar técnicas de respiración y relajación para reducir el estrés que afecta la digestión',
        'icon': Icons.self_improvement,
        'frequency': 'Diario',
        'category': 'Bienestar',
        'times_per_day': 2,
        'suggested_times': ['08:00', '20:00'],
        'duration': 10,
      });
    }

    // Detección de horarios de comida
    if (_containsAny(content, [
      'horarios',
      'rutina',
      'mismo horario',
      'regular',
    ])) {
      habits.add({
        'name': 'Horarios regulares de comida',
        'description':
            'Mantener horarios fijos para las comidas principales para mejorar la digestión',
        'icon': Icons.schedule,
        'frequency': 'Diario',
        'category': 'Alimentación',
        'times_per_day': 3,
        'suggested_times': ['08:00', '13:00', '19:00'],
      });
    }

    // Detección de sueño y descanso
    if (_containsAny(content, [
      'dormir',
      'sueño',
      'descanso',
      'acostarse temprano',
    ])) {
      habits.add({
        'name': 'Mejorar calidad del sueño',
        'description':
            'Mantener un horario regular de sueño para permitir que el sistema digestivo se recupere',
        'icon': Icons.bedtime,
        'frequency': 'Diario',
        'category': 'Sueño',
        'times_per_day': 1,
        'suggested_times': ['22:00'],
        'duration': 480, // 8 horas
      });
    }

    // Detección de medicamentos y suplementos
    if (_containsAny(content, [
      'probióticos',
      'suplementos',
      'vitaminas',
      'medicamento',
    ])) {
      habits.add({
        'name': 'Tomar suplementos digestivos',
        'description':
            'Tomar probióticos o suplementos recomendados para mejorar la salud digestiva',
        'icon': Icons.medication,
        'frequency': 'Diario',
        'category': 'Salud',
        'times_per_day': 1,
        'suggested_times': ['08:00'],
      });
    }

    // Si no se encontraron hábitos específicos, agregar uno genérico basado en el contexto
    if (habits.isEmpty) {
      if (_containsAny(content, ['dolor', 'estómago', 'gastritis', 'acidez'])) {
        habits.add({
          'name': 'Cuidado digestivo diario',
          'description':
              'Seguir las recomendaciones del asistente para aliviar los síntomas digestivos',
          'icon': Icons.health_and_safety,
          'frequency': 'Diario',
          'category': 'Salud',
          'times_per_day': 1,
          'suggested_times': ['09:00'],
        });
      } else {
        habits.add({
          'name': 'Implementar consejos de salud',
          'description':
              'Seguir las recomendaciones del asistente para mejorar el bienestar general',
          'icon': Icons.health_and_safety,
          'frequency': 'Diario',
          'category': 'Salud',
          'times_per_day': 1,
          'suggested_times': ['09:00'],
        });
      }
    }

    return habits;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  List<String> _extractIrritants(String content) {
    final irritants = <String>[];
    final irritantMap = {
      'café': ['café', 'cafeína'],
      'alcohol': ['alcohol', 'bebidas alcohólicas'],
      'cítricos': ['cítricos', 'naranja', 'limón', 'toronja'],
      'picante': ['picante', 'chile', 'condimentos'],
      'frituras': ['frituras', 'fritos', 'grasa'],
      'chocolate': ['chocolate'],
      'tomate': ['tomate', 'jitomate'],
    };

    irritantMap.forEach((key, keywords) {
      if (_containsAny(content, keywords)) {
        irritants.add(key);
      }
    });

    return irritants.isEmpty ? ['alimentos irritantes'] : irritants;
  }

  void _showHabitCreatedSnackbar(String habitName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hábito "$habitName" creado exitosamente',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            // Navegar a la pantalla de hábitos
          },
        ),
      ),
    );
  }

  void _showReminderSetSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Recordatorio configurado exitosamente',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Color(0xFF2196F3),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Función para regenerar respuesta
  void _regenerateResponse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.refresh, color: const Color(0xFF2196F3), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Regenerar Respuesta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Quieres que genere una nueva respuesta con un enfoque diferente?',
          style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRegeneration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }

  // Función para realizar la regeneración
  void _performRegeneration() {
    // Buscar el último mensaje del usuario en la sesión
    final assistantBloc = context.read<AssistantBloc>();
    final currentState = assistantBloc.state;

    if (currentState.messages.isNotEmpty) {
      // Buscar el último mensaje del usuario
      final userMessages = currentState.messages
          .where((m) => m.type.toString().contains('user'))
          .toList();

      if (userMessages.isNotEmpty) {
        final lastUserMessage = userMessages.last;

        // Usar ChatBloc si está disponible, sino usar AssistantBloc
        try {
          final chatBloc = context.read<ChatBloc>();
          chatBloc.add(
            RegenerateResponse(
              sessionId: widget.message.sessionId,
              lastUserMessage: lastUserMessage.content,
            ),
          );
        } catch (e) {
          // Si no hay ChatBloc disponible, mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error: No se puede regenerar la respuesta'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Mostrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Regenerando respuesta...'),
              ],
            ),
            backgroundColor: const Color(0xFF2196F3),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Función para editar mensaje del asistente
  void _editAssistantMessage() {
    final TextEditingController editController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFF9C27B0), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Editar Mensaje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puedes solicitar modificaciones específicas a esta respuesta:',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editController,
              decoration: InputDecoration(
                hintText: 'Ej: Hazlo más detallado, agrega ejemplos...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final editText = editController.text.trim();
              Navigator.pop(context);
              if (editText.isNotEmpty) {
                _performMessageEdit(editText);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Aplicar Cambios'),
          ),
        ],
      ),
    );
  }

  // Función para realizar la edición del mensaje
  void _performMessageEdit(String editInstructions) {
    try {
      final chatBloc = context.read<ChatBloc>();

      // Crear el nuevo contenido del mensaje con las instrucciones de edición
      final newContent =
          '${widget.message.content}\n\n[Modificación solicitada: $editInstructions]';

      chatBloc.add(
        EditMessage(messageId: widget.message.id, newContent: newContent),
      );

      // Mostrar indicador de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Mensaje editado exitosamente'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Mostrar error si no se puede editar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Error al editar el mensaje'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Función para dar like al mensaje
  Future<void> _likeMessage() async {
    await _sendFeedback('like');
  }

  // Función para dar dislike al mensaje
  Future<void> _dislikeMessage() async {
    await _sendFeedback('dislike');
  }

  // Función para enviar feedback
  Future<void> _sendFeedback(String feedbackType) async {
    if (_isLoadingFeedback) return;
    
    setState(() {
      _isLoadingFeedback = true;
    });

    try {
      final chatRepository = context.read<ChatRepository>();
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        _showErrorSnackBar('Debes iniciar sesión para dar feedback');
        return;
      }

      // Si ya tiene el mismo feedback, lo removemos
      if (_currentFeedback == feedbackType) {
        await chatRepository.removeMessageFeedback(
          userId: user.id,
          messageId: widget.message.id,
        );
        
        setState(() {
          _currentFeedback = null;
        });
        
        _showSuccessSnackBar('Feedback removido');
      } else {
        // Enviar nuevo feedback
        await chatRepository.sendMessageFeedback(
          userId: user.id,
          messageId: widget.message.id,
          feedbackType: feedbackType,
        );
        
        setState(() {
          _currentFeedback = feedbackType;
        });
        
        final message = feedbackType == 'like' 
            ? 'Te gusta este mensaje' 
            : 'No te gusta este mensaje';
        _showSuccessSnackBar(message);
      }
    } catch (e) {
      print('Error sending feedback: $e');
      _showErrorSnackBar('Error al enviar feedback');
    } finally {
      setState(() {
        _isLoadingFeedback = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _currentFeedback == 'like' ? Icons.thumb_up : Icons.thumb_down,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFFF5722),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Función para alternar TTS (mute/unmute) y reproducir el mensaje
  void _toggleTTS() {
    final assistantBloc = context.read<AssistantBloc>();
    final currentState = assistantBloc.state;

    // Si es un mensaje del asistente y no está reproduciendo
    if (widget.message.type == MessageType.assistant) {
      if (currentState.isPlayingAudio) {
        // Si está reproduciendo, detener
        assistantBloc.add(StopCurrentTTS());
      } else {
        // Si no está reproduciendo, iniciar reproducción del mensaje
        assistantBloc.add(RestartTTS(content: widget.message.content));
      }
    } else {
      // Para otros casos, solo alternar mute/unmute
      if (currentState.isTTSMuted) {
        assistantBloc.add(UnmuteTTS());
      } else {
        assistantBloc.add(MuteTTS());
      }
    }
  }

  void _navigateToCustomizeHabit(Map<String, dynamic> habit) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => NewHabitScreen(
              prefilledHabitName: habit['name'] as String?,
              prefilledDescription: habit['description'] as String?,
              prefilledCategoryId: _getCategoryIdFromName(
                habit['category'] as String?,
              ),
            ),
          ),
        )
        .then((result) {
          // Si se creó el hábito exitosamente, mostrar confirmación
          if (result == true) {
            _showHabitCreatedSnackbar(habit['name'] as String);
          }
        });
  }

  void _navigateToCreateHabit(Habit habit) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => NewHabitScreen(
              prefilledHabitName: habit.name,
              prefilledDescription: habit.description,
              prefilledCategoryId: habit.categoryId,
            ),
          ),
        )
        .then((result) {
          // Si se creó el hábito exitosamente, mostrar confirmación
          if (result == true) {
            _showHabitCreatedSnackbar(habit.name);
          }
        });
  }

  String? _getCategoryIdFromName(String? categoryName) {
    // Mapeo de nombres de categorías a UUIDs reales de la base de datos
    // Estos UUIDs coinciden con las categorías definidas en las migraciones de Supabase
    final categoryMap = {
      // Categorías principales del sistema
      'Alimentación': 'b0231bea-a750-4984-97d8-8ccb3a2bae1c',
      'Actividad Física': '2196f3aa-1234-4567-89ab-cdef12345678',
      'Sueño': '6d1f2f1b-04ef-497e-97b7-8077ff3b3c69',
      'Hidratación': '93688043-4d35-4b2a-9dcd-17482125b1a9',
      'Bienestar Mental': 'ff9800bb-5678-4567-89ab-cdef12345678',
      'Productividad': '795548cc-9012-4567-89ab-cdef12345678',

      // Alias y variaciones comunes
      'Ejercicio':
          '2196f3aa-1234-4567-89ab-cdef12345678', // Alias para Actividad Física
      'Salud':
          'b0231bea-a750-4984-97d8-8ccb3a2bae1c', // Alias para Alimentación
      'Bienestar':
          'ff9800bb-5678-4567-89ab-cdef12345678', // Alias para Bienestar Mental
      'Descanso': '6d1f2f1b-04ef-497e-97b7-8077ff3b3c69', // Alias para Sueño
      'General':
          'b0231bea-a750-4984-97d8-8ccb3a2bae1c', // Fallback a Alimentación
    };

    return categoryMap[categoryName];
  }

  /// Construye el desplegable de hábitos sugeridos mejorado
  Widget _buildSuggestedHabitsDropdown() {
    // Solo mostrar para mensajes del asistente que contengan consejos de salud
    if (widget.message.type != MessageType.assistant ||
        !_shouldShowActionButtons()) {
      return const SizedBox.shrink();
    }

    // Obtener hábitos sugeridos del mensaje o extraerlos del contenido
    List<Habit> suggestedHabits = [];

    // Primero intentar obtener de metadata
    if (_hasSuggestedHabits()) {
      final habitsData = widget.message.metadata!['suggestedHabits'] as List;
      suggestedHabits = habitsData
          .map((habitData) => Habit.fromMap(habitData))
          .toList();
    } 
    // DESHABILITADO: Extracción automática de hábitos del contenido
    // Esto evita la creación de hábitos sin sentido basados en palabras clave
    // Los hábitos ahora solo se crean desde metadata explícita del asistente
    /*
    else {
      // Si no hay en metadata, extraer del contenido del mensaje
      final extractedHabits = _extractHabitsFromMessage();
      if (extractedHabits != null && extractedHabits.isNotEmpty) {
        suggestedHabits = extractedHabits
            .map((habitData) => _convertMapToHabit(habitData))
            .toList();
      }
    }
    */

    // Si no hay hábitos sugeridos, no mostrar el widget
    if (suggestedHabits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        EnhancedHabitsDropdownWidget(
          suggestedHabits: suggestedHabits,
          existingUserHabits: widget.existingUserHabits,
          onHabitSelected: (habit) {
            // Callback cuando se selecciona un hábito
            if (widget.onCreateHabit != null) {
              widget.onCreateHabit!(habit.name, {
                'name': habit.name,
                'description': habit.description,
                'category': _getCategoryNameFromId(habit.categoryId),
                'icon': _getIconDataFromName(habit.iconName),
                'frequency': 'Diario',
              });
            }
          },
          onHabitConfigured: (habit, config) {
            // Callback cuando se configura un hábito
            if (widget.onCreateHabit != null) {
              widget.onCreateHabit!(habit.name, config);
            }
          },
          onHabitsUpdated: widget.onHabitsUpdated,
          showReprogrammingOptions: _hasReprogrammingContent(),
        ),
      ],
    );
  }

  /// Construye un elemento de hábito sugerido
  Widget _buildSuggestedHabitItem(Map<String, dynamic> habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _createHabitFromSuggestion(habit),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      habit['category'] as String,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    habit['icon'] as IconData,
                    size: 20,
                    color: _getCategoryColor(habit['category'] as String),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit['name'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habit['description'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit['frequency'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  size: 24,
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Crea un hábito a partir de una sugerencia
  void _createHabitFromSuggestion(Map<String, dynamic> habitData) {
    if (widget.onCreateHabit != null) {
      widget.onCreateHabit!(habitData['name'] as String, habitData);
    } else {
      // Fallback: navegar a la pantalla de creación de hábito
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewHabitScreen(
            prefilledHabitName: habitData['name'] as String,
            prefilledDescription: habitData['description'] as String,
            prefilledCategoryId: _getCategoryIdFromName(
              habitData['category'] as String,
            ),
          ),
        ),
      );
    }
  }

  /// Obtiene el color de una categoría
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alimentación':
        return const Color(0xFF4CAF50);
      case 'hidratación':
        return const Color(0xFF2196F3);
      case 'ejercicio':
      case 'actividad física':
        return const Color(0xFFFF9800);
      case 'sueño':
      case 'descanso':
        return const Color(0xFF9C27B0);
      case 'bienestar mental':
        return const Color(0xFFE91E63);
      case 'salud':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF757575);
    }
  }

  /// Convierte un Map a un objeto Habit
  Habit _convertMapToHabit(Map<String, dynamic> habitData) {
    return Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: habitData['name'] as String,
      description: habitData['description'] as String? ?? '',
      categoryId: _getCategoryIdFromName(
        habitData['category'] as String? ?? 'Salud',
      ),
      iconName: _getIconNameFromData(habitData['icon']),
      iconColor: _getColorHexFromCategory(
        habitData['category'] as String? ?? 'Salud',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Obtiene el nombre de categoría desde el ID
  String _getCategoryNameFromId(String? categoryId) {
    // Mapeo básico de IDs a nombres
    switch (categoryId) {
      case '1':
        return 'Alimentación';
      case '2':
        return 'Hidratación';
      case '3':
        return 'Ejercicio';
      case '4':
        return 'Sueño';
      case '5':
        return 'Bienestar Mental';
      default:
        return 'Salud';
    }
  }

  /// Obtiene IconData desde el nombre del icono
  IconData _getIconDataFromName(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'restaurant':
      case 'utensils':
        return Icons.restaurant;
      case 'favorite':
      case 'heart':
        return Icons.favorite;
      case 'fitness_center':
      case 'activity':
        return Icons.fitness_center;
      case 'psychology':
      case 'brain':
        return Icons.psychology;
      case 'water_drop':
        return Icons.water_drop;
      case 'bed':
        return Icons.bed;
      case 'book':
        return Icons.book;
      case 'self_improvement':
      case 'meditation':
        return Icons.self_improvement;
      case 'schedule':
        return Icons.schedule;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      default:
        return Icons.track_changes;
    }
  }

  /// Obtiene el nombre del icono desde IconData
  String _getIconNameFromData(dynamic iconData) {
    if (iconData is IconData) {
      // Mapeo básico de IconData a nombres
      if (iconData == Icons.restaurant) return 'restaurant';
      if (iconData == Icons.favorite) return 'favorite';
      if (iconData == Icons.fitness_center) return 'fitness_center';
      if (iconData == Icons.psychology) return 'psychology';
      if (iconData == Icons.water_drop) return 'water_drop';
      if (iconData == Icons.bed) return 'bed';
      if (iconData == Icons.book) return 'book';
      if (iconData == Icons.self_improvement) return 'self_improvement';
      if (iconData == Icons.schedule) return 'schedule';
      if (iconData == Icons.local_pharmacy) return 'local_pharmacy';
    }
    return 'track_changes';
  }

  /// Obtiene el color hexadecimal desde la categoría
  String _getColorHexFromCategory(String category) {
    final color = _getCategoryColor(category);
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  /// Determina si debe usar el efecto typewriter para este mensaje
  bool _shouldUseTypewriterEffect() {
    // Solo para mensajes del asistente
    if (widget.message.type != MessageType.assistant) return false;
    
    // Verificar si es un mensaje reciente (últimos 5 segundos)
    final now = DateTime.now();
    final messageTime = widget.message.createdAt;
    final timeDifference = now.difference(messageTime).inSeconds;
    
    // Usar typewriter solo para mensajes muy recientes
    if (timeDifference > 10) return false;
    
    // Verificar si el mensaje tiene metadata que indique que es una respuesta progresiva
    final metadata = widget.message.metadata;
    if (metadata != null) {
      // Si tiene análisis de deep learning, usar typewriter
      if (metadata['hasDeepLearning'] == true) return true;
      
      // Si es una respuesta completa reciente, usar typewriter
      if (metadata['isCompleteResponse'] == true) return true;
    }
    
    // Para mensajes largos (más de 100 caracteres), usar typewriter
    if (widget.message.content.length > 100) return true;
    
    return false;
  }

  /// Verifica si el mensaje contiene contenido de reprogramación
  bool _hasReprogrammingContent() {
    final content = widget.message.content.toLowerCase();
    return content.contains('reprogramar') ||
        content.contains('cambiar horario') ||
        content.contains('ajustar') ||
        content.contains('modificar horario') ||
        content.contains('nueva hora') ||
        content.contains('cambiar tiempo');
  }
}
