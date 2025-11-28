import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/chat/instruction_chip_widget.dart';
import '../../widgets/dialogs/register_symptom_dialog.dart';
import '../../widgets/assistant/attached_habits_widget.dart';
import '../habits/new_habit_screen.dart';
import '../daily_progress_page.dart';
import 'pending_activities_selection_page.dart';
import 'chat_conversation_page.dart';
import 'chat_history_page.dart';
import '../../../domain/entities/user_habit.dart';

/// Página de introducción al chat siguiendo el diseño de Figma 2067_355
class ChatIntroPage extends StatefulWidget {
  final List<UserHabit>? attachedHabits;
  
  const ChatIntroPage({super.key, this.attachedHabits});

  @override
  State<ChatIntroPage> createState() => _ChatIntroPageState();
}

class _ChatIntroPageState extends State<ChatIntroPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSessions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _loadUserSessions() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.read<ChatBloc>().add(LoadUserSessions(user.id));
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuario no autenticado');
        return;
      }

      // Crear nueva sesión
      context.read<ChatBloc>().add(CreateNewSession(user.id));

      // Esperar a que se cree la sesión
      await Future.delayed(const Duration(milliseconds: 500));

      // Navegar a la página de conversación con el mensaje inicial
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ChatBloc>(),
              child: ChatConversationPage(
                initialMessage: message,
                attachedHabits: widget.attachedHabits,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al iniciar conversación: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendPredefinedMessage(String message) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuario no autenticado');
        return;
      }

      // Crear nueva sesión
      context.read<ChatBloc>().add(CreateNewSession(user.id));

      // Esperar a que se cree la sesión
      await Future.delayed(const Duration(milliseconds: 500));

      // Navegar a la página de conversación con el mensaje inicial
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ChatBloc>(),
              child: ChatConversationPage(
                initialMessage: message,
                attachedHabits: widget.attachedHabits,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al iniciar conversación: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        title: const Text(
          'Vive Good',
          style: TextStyle(color: Color(0xFF2E7D32)),
        ),
        actions: [
          IconButton(
            tooltip: 'Historial de chat',
            icon: const Icon(Icons.history, color: Color(0xFF2E7D32)),
            onPressed: _navigateToChatHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatError) {
              _showErrorSnackBar(state.message);
              setState(() {
                _isLoading = false;
              });
            }
          },
          child: Column(
            children: [
              // Hábitos adjuntados (si existen)
              if (widget.attachedHabits != null && widget.attachedHabits!.isNotEmpty)
                AttachedHabitsWidget(
                  attachedHabits: widget.attachedHabits!,
                  onRemoveAll: () {
                    // Navegar de vuelta sin hábitos adjuntados
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<ChatBloc>(),
                          child: const ChatIntroPage(),
                        ),
                      ),
                    );
                  },
                  onRemoveHabit: (habit) {
                    // Crear nueva lista sin el hábito removido
                    final updatedHabits = widget.attachedHabits!
                        .where((h) => h.id != habit.id)
                        .toList();
                    
                    if (updatedHabits.isEmpty) {
                      // Si no quedan hábitos, navegar sin hábitos adjuntados
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<ChatBloc>(),
                            child: const ChatIntroPage(),
                          ),
                        ),
                      );
                    } else {
                      // Navegar con la lista actualizada
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<ChatBloc>(),
                            child: ChatIntroPage(
                              attachedHabits: updatedHabits,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildInstructionChips(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: _buildMessageInput(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo de Vive Good
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Texto "Vive Good"
        const Text(
          'Vive Good',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtítulo
        const Text(
          'Tu asistente de salud digestiva',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionChips() {
    final instructions = [
      'Quiero registrar mi alimentación de hoy',
      'Tengo síntomas después de comer',
      'Necesito evaluar mis rutinas diarias',
      'Quiero consejos para mejorar mi estilo de vida',
    ];

    return Column(
      children: instructions.map((instruction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InstructionChipWidget(
            text: instruction,
            onTap: () => _sendPredefinedMessage(instruction),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageInput() {
    final canSend = _messageController.text.trim().isNotEmpty && !_isLoading;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF219540).withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Botón "+"
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: _showQuickActionsMenu,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
          // Campo de texto
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje',
                hintStyle: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Botón de envío
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: canSend ? _sendMessage : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canSend ? const Color(0xFF4CAF50) : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black26,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título del menú
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Acciones específicas solicitadas por el usuario
                    _quickAction(
                      icon: Icons.monitor_heart,
                      title: 'Registrar síntoma',
                      subtitle: 'Registrar síntomas digestivos',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const RegisterSymptomDialog(),
                        );
                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Síntoma registrado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                    _quickAction(
                      icon: Icons.add_circle_outline,
                      title: 'Registrar nuevo hábito',
                      subtitle: 'Crear un nuevo hábito saludable',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (context) => const NewHabitScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hábito registrado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                    _quickAction(
                      icon: Icons.checklist,
                      title: 'Actividades pendientes',
                      subtitle: 'Seleccionar y adjuntar al chat',
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => const PendingActivitiesSelectionPage(),
                          ),
                        );
                        
                        if (result != null && result.isNotEmpty) {
                          // Enviar el mensaje directamente
                          _sendPredefinedMessage(result);
                        }
                      },
                    ),
                    _quickAction(
                      icon: Icons.trending_up,
                      title: 'Ver mi progreso de hoy',
                      subtitle: 'Estadísticas del día actual',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DailyProgressPage(),
                          ),
                        );
                      },
                    ),
                    
                    // Separador
                    const Divider(height: 32),
                    
                    // Acciones adicionales
                    _quickAction(
                      icon: Icons.history,
                      title: 'Ver historial de chat',
                      subtitle: 'Sesiones guardadas',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToChatHistory();
                      },
                    ),
                    _quickAction(
                      icon: Icons.psychology_alt_outlined,
                      title: 'Sugerencia IA personalizada',
                      subtitle: 'Consejos basados en tu perfil',
                      onTap: () {
                        Navigator.pop(context);
                        _sendPredefinedMessage('Dame sugerencias personalizadas para hoy');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _navigateToChatHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: const ChatHistoryPage(),
        ),
      ),
    );
  }
}