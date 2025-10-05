import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../../../domain/entities/habit.dart';
import 'formatted_text_widget.dart';
import 'auto_created_habits_widget.dart';
import '../../pages/habits/new_habit_screen.dart';

/// Widget para mostrar mensajes de chat individuales
class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final Function(String messageId, String newContent)? onEdit;
  final Function(String messageId)? onDelete;
  final Function(String habitName, Map<String, dynamic> habitData)? onCreateHabit;
  final Function()? onViewMoreAdvice;
  final Function()? onHabitsUpdated;

  const ChatMessageWidget({
    super.key,
    required this.message,
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

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
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
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ..._buildAssistantMessage(),
        if (isUser) ..._buildUserMessage(),
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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
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
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: _buildMessageContent(),
              ),
            ),
            
            // Timestamp
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.message.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
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
    
    if (isUser) {
      return Text(
        widget.message.content,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          height: 1.4,
        ),
      );
    } else {
      // Para mensajes del asistente, usar el widget de formato
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormattedTextWidget(
            text: widget.message.content,
            baseStyle: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
              height: 1.4,
            ),
          ),
          
          // Mostrar hábitos auto-creados si están disponibles
          if (_hasAutoCreatedHabits()) ..._buildAutoCreatedHabits(),
          
          // Botones de acción para mensajes del asistente
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
      'dolor', 'estómago', 'gastritis', 'acidez', 'reflujo',
      'comidas', 'comer', 'alimentación', 'dieta',
      'evita', 'evitar', 'reduce', 'elimina',
      'hábito', 'rutina', 'horario',
      'recomend', 'consejo', 'sugiero', 'importante',
      'agua', 'hidrat', 'bebe',
      'ejercicio', 'camina', 'actividad',
      'estrés', 'relajación', 'descanso', 'sueño',
      'probióticos', 'suplementos', 'medicamento'
    ];
    
    // Verificar si contiene al menos 2 palabras clave para mayor precisión
    final keywordCount = healthKeywords.where((keyword) => content.contains(keyword)).length;
    
    // También mostrar si el mensaje es largo (más de 100 caracteres) y contiene al menos una palabra clave
    final isLongMessage = content.length > 100;
    final hasHealthKeyword = healthKeywords.any((keyword) => content.contains(keyword));
    
    return keywordCount >= 2 || (isLongMessage && hasHealthKeyword);
  }
  
  bool _hasAutoCreatedHabits() {
    return widget.message.metadata != null &&
           widget.message.metadata!['autoCreatedHabits'] != null &&
           (widget.message.metadata!['autoCreatedHabits'] as List).isNotEmpty;
  }
  
  List<Widget> _buildAutoCreatedHabits() {
    if (!_hasAutoCreatedHabits()) return [];
    
    final habitsData = widget.message.metadata!['autoCreatedHabits'] as List;
    final habits = habitsData.map((habitData) => Habit.fromMap(habitData)).toList();
    
    return [
      const SizedBox(height: 12),
      AutoCreatedHabitsWidget(
        habits: habits,
        onHabitsUpdated: widget.onHabitsUpdated,
      ),
    ];
  }
  
  List<Widget> _buildActionButtons() {
    return [
      const SizedBox(height: 12),
      // Botones principales según diseño Figma
      Row(
        children: [
          _buildBrainboxChatButton(),
          const SizedBox(width: 8),
          _buildRegenerateButton(),
          const SizedBox(width: 8),
          _buildEditMessageButton(),
        ],
      ),
      const SizedBox(height: 8),
      // Botones secundarios
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Crear Hábito',
            color: const Color(0xFF4CAF50),
            onPressed: () => _showCreateHabitDialog(),
          ),
          _buildActionButton(
            icon: Icons.schedule,
            label: 'Recordatorio',
            color: const Color(0xFF2196F3),
            onPressed: () => _showReminderDialog(),
          ),
          _buildActionButton(
            icon: Icons.info_outline,
            label: 'Más Consejos',
            color: const Color(0xFF9C27B0),
            onPressed: () => widget.onViewMoreAdvice?.call(),
          ),
        ],
      ),
    ];
  }
  
  // Botón Brainbox-Chat según diseño Figma
  Widget _buildBrainboxChatButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBrainboxChatDialog(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology,
                size: 16,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 6),
              Text(
                'Brainbox-Chat',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Botón Regenerar según diseño Figma
  Widget _buildRegenerateButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _regenerateResponse(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 6),
              Text(
                'Regenerar',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF2196F3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Botón Editar mensaje según diseño Figma
  Widget _buildEditMessageButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _editAssistantMessage(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9C27B0).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit,
                size: 16,
                color: const Color(0xFF9C27B0),
              ),
              const SizedBox(width: 6),
              Text(
                'Editar mensaje',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF9C27B0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
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

  Widget _buildEditField() {
    return TextField(
      controller: _editController,
      focusNode: _editFocusNode,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        height: 1.4,
      ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
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
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
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
      child: const Icon(
        Icons.smart_toy,
        color: Colors.white,
        size: 20,
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                    ),
                    label: const Text('Personalizar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(
                        color: Color(0xFFCCCCCC),
                      ),
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
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                    ),
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
            Icon(
              Icons.schedule,
              color: Color(0xFF2196F3),
            ),
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
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
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
    if (_containsAny(content, ['comidas pequeñas', 'porciones pequeñas', 'comer poco', 'frecuentes', 'cada 2-3 horas'])) {
      habits.add({
        'name': 'Comidas pequeñas y frecuentes',
        'description': 'Comer porciones más pequeñas cada 2-3 horas para reducir la carga en el estómago',
        'icon': Icons.restaurant,
        'frequency': 'Diario',
        'category': 'Alimentación',
        'times_per_day': 5,
        'suggested_times': ['08:00', '10:30', '13:00', '15:30', '18:00'],
      });
    }
    
    // Detección de alimentos a evitar
    if (_containsAny(content, ['evita', 'evitar', 'no comas', 'elimina', 'reduce']) && 
        _containsAny(content, ['café', 'alcohol', 'cítricos', 'picante', 'grasa', 'frituras', 'condimentos'])) {
      final irritants = _extractIrritants(content);
      habits.add({
        'name': 'Evitar alimentos irritantes',
        'description': 'Reducir o eliminar ${irritants.join(', ')} que pueden empeorar los síntomas digestivos',
        'icon': Icons.block,
        'frequency': 'Diario',
        'category': 'Alimentación',
        'times_per_day': 1,
        'irritants': irritants,
      });
    }
    
    // Detección de hidratación
    if (_containsAny(content, ['agua', 'hidrat', 'bebe', 'líquidos', 'infusiones'])) {
      habits.add({
        'name': 'Mantener hidratación adecuada',
        'description': 'Beber 8 vasos de agua al día para ayudar en la digestión y reducir la acidez',
        'icon': Icons.water_drop,
        'frequency': 'Diario',
        'category': 'Hidratación',
        'times_per_day': 8,
        'suggested_times': ['07:00', '09:00', '11:00', '13:00', '15:00', '17:00', '19:00', '21:00'],
      });
    }
    
    // Detección de ejercicio y actividad física
    if (_containsAny(content, ['ejercicio', 'camina', 'actividad física', 'movimiento', 'yoga'])) {
      habits.add({
        'name': 'Actividad física suave',
        'description': 'Realizar ejercicio ligero como caminar o yoga para mejorar la digestión',
        'icon': Icons.directions_walk,
        'frequency': 'Diario',
        'category': 'Ejercicio',
        'times_per_day': 1,
        'suggested_times': ['18:00'],
        'duration': 30,
      });
    }
    
    // Detección de manejo del estrés
    if (_containsAny(content, ['estrés', 'relajación', 'ansiedad', 'calma', 'respiración', 'meditación'])) {
      habits.add({
        'name': 'Técnicas de relajación',
        'description': 'Practicar técnicas de respiración y relajación para reducir el estrés que afecta la digestión',
        'icon': Icons.self_improvement,
        'frequency': 'Diario',
        'category': 'Bienestar',
        'times_per_day': 2,
        'suggested_times': ['08:00', '20:00'],
        'duration': 10,
      });
    }
    
    // Detección de horarios de comida
    if (_containsAny(content, ['horarios', 'rutina', 'mismo horario', 'regular'])) {
      habits.add({
        'name': 'Horarios regulares de comida',
        'description': 'Mantener horarios fijos para las comidas principales para mejorar la digestión',
        'icon': Icons.schedule,
        'frequency': 'Diario',
        'category': 'Alimentación',
        'times_per_day': 3,
        'suggested_times': ['08:00', '13:00', '19:00'],
      });
    }
    
    // Detección de sueño y descanso
    if (_containsAny(content, ['dormir', 'sueño', 'descanso', 'acostarse temprano'])) {
      habits.add({
        'name': 'Mejorar calidad del sueño',
        'description': 'Mantener un horario regular de sueño para permitir que el sistema digestivo se recupere',
        'icon': Icons.bedtime,
        'frequency': 'Diario',
        'category': 'Sueño',
        'times_per_day': 1,
        'suggested_times': ['22:00'],
        'duration': 480, // 8 horas
      });
    }
    
    // Detección de medicamentos y suplementos
    if (_containsAny(content, ['probióticos', 'suplementos', 'vitaminas', 'medicamento'])) {
      habits.add({
        'name': 'Tomar suplementos digestivos',
        'description': 'Tomar probióticos o suplementos recomendados para mejorar la salud digestiva',
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
          'description': 'Seguir las recomendaciones del asistente para aliviar los síntomas digestivos',
          'icon': Icons.health_and_safety,
          'frequency': 'Diario',
          'category': 'Salud',
          'times_per_day': 1,
          'suggested_times': ['09:00'],
        });
      } else {
        habits.add({
          'name': 'Implementar consejos de salud',
          'description': 'Seguir las recomendaciones del asistente para mejorar el bienestar general',
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
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
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
            Icon(
              Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
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

  // Función para mostrar el diálogo Brainbox-Chat
  void _showBrainboxChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.psychology,
              color: const Color(0xFF4CAF50),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Brainbox-Chat',
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
              'Esta funcionalidad te permite profundizar en el tema con análisis más detallados y sugerencias personalizadas.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Análisis inteligente basado en tu historial y preferencias',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
              Navigator.pop(context);
              _activateBrainboxChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  // Función para activar Brainbox-Chat
  void _activateBrainboxChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.psychology,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Brainbox-Chat activado - Análisis en progreso...'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            // Aquí se podría navegar a una vista detallada
          },
        ),
      ),
    );
  }

  // Función para regenerar respuesta
  void _regenerateResponse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.refresh,
              color: const Color(0xFF2196F3),
              size: 24,
            ),
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
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF666666),
          ),
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

  // Función para editar mensaje del asistente
  void _editAssistantMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: const Color(0xFF9C27B0),
              size: 24,
            ),
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
              decoration: InputDecoration(
                hintText: 'Ej: Hazlo más detallado, agrega ejemplos...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              _performMessageEdit();
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
  void _performMessageEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Aplicando cambios al mensaje...'),
          ],
        ),
        backgroundColor: const Color(0xFF9C27B0),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _navigateToCustomizeHabit(Map<String, dynamic> habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewHabitScreen(
          prefilledHabitName: habit['name'] as String?,
          prefilledDescription: habit['description'] as String?,
          prefilledCategoryId: _getCategoryIdFromName(habit['category'] as String?),
        ),
      ),
    ).then((result) {
      // Si se creó el hábito exitosamente, mostrar confirmación
      if (result == true) {
        _showHabitCreatedSnackbar(habit['name'] as String);
      }
    });
  }
  
  String? _getCategoryIdFromName(String? categoryName) {
    // Mapeo de nombres de categorías a IDs
    // Estos IDs deberían coincidir con los de la base de datos
    final categoryMap = {
      'Alimentación': '1',
      'Ejercicio': '2',
      'Salud': '3',
      'Hidratación': '4',
      'Sueño': '5',
      'Bienestar': '6',
    };
    
    return categoryMap[categoryName];
  }
}