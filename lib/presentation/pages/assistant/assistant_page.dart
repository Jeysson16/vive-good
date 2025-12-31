import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/datasources/chat_remote_datasource.dart';
import '../../../data/repositories/supabase_chat_repository.dart';
import '../../../domain/entities/user_habit.dart';
import '../../blocs/assistant/assistant_bloc.dart';
import '../../blocs/assistant/assistant_event.dart';
import '../../blocs/assistant/assistant_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_state.dart';
import '../../widgets/assistant/assistant_avatar_widget.dart';
import '../../widgets/assistant/attached_habits_widget.dart';
import '../../widgets/assistant/enhanced_voice_animation_widget.dart';
import '../../widgets/assistant/suggestion_chip_widget.dart';
import '../../widgets/chat/chat_message_widget.dart';
import '../chat/chat_intro_page.dart';
import '../habits/new_habit_screen.dart';

class AssistantPage extends StatefulWidget {
  final List<UserHabit>? attachedHabits;

  const AssistantPage({super.key, this.attachedHabits});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage>
    with TickerProviderStateMixin {
  late AnimationController _voiceAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _iconAnimationController;
  late AnimationController _gradientAnimationController;
  late TextEditingController _textController;
  late ScrollController _scrollController;
  late ScrollController _suggestionsScrollController;
  late Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _suggestionsScrollController = ScrollController();

    // Auto-scroll para sugerencias
    _startAutoScroll();

    _fadeAnimationController.forward();

    // Initialize assistant with current user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = _getCurrentUserId(context);
      context.read<AssistantBloc>().add(InitializeAssistant(userId: userId));

      // Si hay hábitos adjuntados, mostrarlos como contexto pero permitir al usuario escribir su mensaje
      // Ya no enviamos mensaje automático, solo mostramos los hábitos adjuntados
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_suggestionsScrollController.hasClients) {
        final maxScroll = _suggestionsScrollController.position.maxScrollExtent;
        final currentScroll = _suggestionsScrollController.offset;

        if (currentScroll >= maxScroll) {
          _suggestionsScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _suggestionsScrollController.animateTo(
            currentScroll + 120,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _voiceAnimationController.dispose();
    _fadeAnimationController.dispose();
    _iconAnimationController.dispose();
    _gradientAnimationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _suggestionsScrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  /// Helper method to get current user ID from AuthBloc
  String _getCurrentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return 'anonymous_user'; // Fallback for unauthenticated users
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FA), // Gris muy claro en la parte superior
            Color.fromARGB(
              255,
              213,
              245,
              213,
            ), // Verde muy suave en la parte inferior
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Eliminamos el AppBar para optimizar espacio
        body: BlocConsumer<AssistantBloc, AssistantState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Handle voice animation
            if (state.isRecording) {
              _voiceAnimationController.repeat();
              _iconAnimationController.forward();
            } else {
              _voiceAnimationController.stop();
              _iconAnimationController.reverse();
            }

            // Auto-scroll to bottom when new messages arrive
            if (state.messages.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  // Hábitos adjuntados (si existen)
                  if (widget.attachedHabits != null &&
                      widget.attachedHabits!.isNotEmpty)
                    AttachedHabitsWidget(
                      attachedHabits: widget.attachedHabits!,
                      onRemoveAll: () {
                        // Navegar de vuelta sin hábitos adjuntados
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AssistantPage(),
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
                              builder: (context) => const AssistantPage(),
                            ),
                          );
                        } else {
                          // Navegar con la lista actualizada
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AssistantPage(attachedHabits: updatedHabits),
                            ),
                          );
                        }
                      },
                    ),

                  // Contenido principal
                  Expanded(
                    child: state.messages.isEmpty
                        ? _buildWelcomeScreen(context, state)
                        : _buildChatView(context, state),
                  ),
                  _buildHealthDisclaimer(),

                  // Completion button (appears when there are messages)
                  if (state.messages.isNotEmpty && state.currentSession != null)
                    _buildCompletionButton(context, state),

                  // Bottom input area
                  _buildBottomInputArea(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHealthDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: const Text(
          'Las recomendaciones del asistente son sugerencias generales. Ante dudas o síntomas, consulta a un profesional de la salud.',
          style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(AssistantState state) {
    final suggestions = state.suggestions.isNotEmpty
        ? state.suggestions
        : [
            'Reprograma el almuerzo',
            'Cambia mi rutina',
            '¿Cómo está mi salud?',
            'Consejos para gastritis',
            'Análisis de síntomas',
            'Plan de alimentación',
            'Ejercicios recomendados',
            'Control de estrés',
          ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _suggestionsScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SuggestionChipWidget(
              text: suggestion,
              onTap: () {
                context.read<AssistantBloc>().add(
                  SendTextMessage(
                    content: suggestion,
                    userId: _getCurrentUserId(context),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, AssistantState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildSuggestionChips(state),
            ],
          ),

          const SizedBox(height: 40),

          // Greeting and main question
          Text(
            'Hola, ${context.read<AuthBloc>().state is AuthAuthenticated ? (context.read<AuthBloc>().state as AuthAuthenticated).user.firstName : 'Usuario'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿En qué puedo ayudarte?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Voice animation and avatar with circular gradient background
          Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF81C784).withOpacity(0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Voice animation
                    EnhancedVoiceAnimationWidget(
                      controller: _voiceAnimationController,
                      amplitude: state.recordingAmplitude ?? 0.0,
                      color: _getAnimationColor(state),
                      isListening: state.isRecording,
                      isActive:
                          state.isRecording ||
                          state.isPlayingAudio ||
                          state.isLoading,
                    ),
                    // Assistant avatar
                    AssistantAvatarWidget(
                      isActive: state.isRecording || state.isPlayingAudio,
                      isLoading: state.isLoading,
                      size: 120,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Color _getAnimationColor(AssistantState state) {
    if (state.isRecording) {
      return const Color(0xFF4CAF50); // Verde cuando está grabando
    } else if (state.isPlayingAudio) {
      return Colors.blue;
    } else if (state.isLoading) {
      return Colors.orange;
    }
    return const Color(0xFF4CAF50);
  }

  Widget _buildChatView(BuildContext context, AssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.messages.length + (state.isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          // Mostrar indicador de carga si el asistente está escribiendo
          if (index == state.messages.length && state.isTyping) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTypingIndicator(),
            );
          }

          final message = state.messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BlocBuilder<HabitBloc, HabitState>(
              builder: (context, habitState) {
                final existingUserHabits = habitState is HabitLoaded
                    ? habitState.filteredHabits
                    : <UserHabit>[];

                return ChatMessageWidget(
                  key: ValueKey(message.id),
                  message: message,
                  existingUserHabits: existingUserHabits,
                  onCreateHabit: (habitName, habitData) {
                    // Navegar a NewHabitScreen con los datos del hábito
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NewHabitScreen(
                          prefilledHabitName: habitName,
                          prefilledDescription:
                              habitData['description'] as String?,
                          prefilledCategoryId: _getCategoryIdFromName(
                            habitData['category'] as String?,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomInputArea(BuildContext context, AssistantState state) {
    // Si hay hábitos adjuntados y no hay mensajes, mostrar campo de texto
    final bool showTextInput =
        widget.attachedHabits != null &&
        widget.attachedHabits!.isNotEmpty &&
        state.messages.isEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        child: showTextInput
            ? _buildTextInputArea(context, state)
            : _buildVoiceInputArea(context, state),
      ),
    );
  }

  Widget _buildTextInputArea(BuildContext context, AssistantState state) {
    final habitNames = widget.attachedHabits!
        .map((habit) => habit.customName ?? habit.habit?.name ?? 'Hábito')
        .join(', ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo de texto
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Escribe sobre tus hábitos: $habitNames',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTextMessage(context, state),
                ),
              ),
              // Botón de envío
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => _sendTextMessage(context, state),
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Botones adicionales
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón de voz
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () {
                  if (state.isRecording) {
                    context.read<AssistantBloc>().add(
                      const StopVoiceRecording(),
                    );
                  } else {
                    context.read<AssistantBloc>().add(
                      const StartVoiceRecording(),
                    );
                  }
                },
                icon: Icon(
                  state.isRecording ? Icons.stop : Icons.mic,
                  color: const Color(0xFF2E7D32),
                  size: 24,
                ),
                tooltip: state.isRecording
                    ? 'Detener grabación'
                    : 'Grabar mensaje',
              ),
            ),
            // Botón de cerrar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
                tooltip: 'Cerrar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceInputArea(BuildContext context, AssistantState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Messages button (left)
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => ChatBloc(
                      chatRepository: SupabaseChatRepository(
                        ChatRemoteDataSource(Supabase.instance.client),
                      ),
                    ),
                    child: ChatIntroPage(attachedHabits: widget.attachedHabits),
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.chat_bubble_outline,
              color: const Color(0xFF2E7D32),
              size: 24,
            ),
            tooltip: 'Mensajes',
          ),
        ),

        // Voice recording button (center)
        GestureDetector(
          onTap: () {
            if (state.isRecording) {
              context.read<AssistantBloc>().add(const StopVoiceRecording());
            } else {
              context.read<AssistantBloc>().add(const StartVoiceRecording());
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: state.isRecording
                  ? const Color(0xFF4CAF50) // Verde cuando está grabando
                  : Colors.transparent, // Transparente cuando no está grabando
              shape: BoxShape.circle,
              border: state.isRecording
                  ? null
                  : Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      width: 2,
                    ),
              boxShadow: state.isRecording
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: state.isRecording ? 0.9 : 1.0,
              child: Icon(
                state.isRecording ? Icons.stop : Icons.mic,
                color: state.isRecording
                    ? Colors.white
                    : const Color(0xFF2E7D32),
                size: 32,
              ),
            ),
          ),
        ),

        // Close button (right)
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              context.go(AppRoutes.main);
            },
            icon: Icon(
              Icons.close_rounded,
              color: const Color(0xFF2E7D32),
              size: 22,
            ),
            tooltip: 'Cerrar',
          ),
        ),
      ],
    );
  }

  void _sendTextMessage(BuildContext context, AssistantState state) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final userId = _getCurrentUserId(context);

    // Incluir información de hábitos adjuntados en el contexto
    String messageWithContext = text;
    if (widget.attachedHabits != null && widget.attachedHabits!.isNotEmpty) {
      final habitNames = widget.attachedHabits!
          .map((habit) => habit.customName ?? habit.habit?.name ?? 'Hábito')
          .join(', ');
      messageWithContext =
          'Contexto: Hábitos adjuntados: $habitNames\n\nMensaje del usuario: $text';
    }

    context.read<AssistantBloc>().add(
      SendTextMessage(content: messageWithContext, userId: userId),
    );

    _textController.clear();
  }

  void _showOptionsMenu(BuildContext context, state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Análisis con Deep Learning'),
              subtitle: Text(
                state.isDeepLearningEnabled ? 'Activado' : 'Desactivado',
              ),
              trailing: Switch(
                value: state.isDeepLearningEnabled,
                onChanged: (value) {
                  context.read<AssistantBloc>().add(
                    ToggleDeepLearning(enabled: value),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de conversaciones'),
              onTap: () {
                Navigator.pop(context);
                context.read<AssistantBloc>().add(
                  const LoadChatSessions('current_user_id'),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionDisplay(AssistantState state) {
    // Mostrar siempre el contenedor pero con animación suave
    final bool shouldShow =
        state.isRecording || state.partialTranscription.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: shouldShow ? 80 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: shouldShow ? 1.0 : 0.0,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(shouldShow ? 0.1 : 0.0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(
                0xFF4CAF50,
              ).withOpacity(shouldShow ? 0.3 : 0.0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: shouldShow ? 1.0 : 0.0,
                    child: Icon(
                      Icons.mic,
                      color: const Color(0xFF4CAF50),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: shouldShow ? 1.0 : 0.0,
                      child: Text(
                        'Transcripción en tiempo real',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: state.isRecording ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 1000),
                      scale: state.isRecording ? 1.0 : 0.0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      state.partialTranscription.isEmpty
                          ? (state.isRecording ? 'Escuchando...' : '')
                          : state.partialTranscription,
                      key: ValueKey(
                        state.partialTranscription.isEmpty
                            ? 'listening'
                            : 'transcription',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
                        fontStyle: state.partialTranscription.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionButton(BuildContext context, AssistantState state) {
    // Check if conversation already has a summary
    final hasSummary = state.messages.any(
      (message) =>
          message.content.contains('Resumen de la conversación') ||
          message.content.contains('Summary'),
    );

    if (hasSummary) {
      return const SizedBox.shrink(); // Don't show button if already completed
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            if (state.currentSession != null) {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Completar Conversación'),
                    content: const Text(
                      '¿Deseas generar un resumen de esta conversación? '
                      'Esto marcará la conversación como completada y mostrará '
                      'un resumen con los puntos clave discutidos.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Trigger conversation completion
                          context.read<AssistantBloc>().add(
                            CompleteChatSession(
                              sessionId: state.currentSession!.id,
                              userId: state.currentSession!.userId,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Completar'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          icon: const Icon(Icons.summarize_rounded),
          label: const Text('Completar Conversación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  /// Convierte el nombre de una categoría a su UUID correspondiente
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

  /// Widget que muestra el indicador de que el asistente está escribiendo
  Widget _buildTypingIndicator() {
    return Row(
      children: [
        // Avatar del asistente
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.assistant,
                  color: Colors.white,
                  size: 18,
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Contenedor del indicador de escritura
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Procesando respuesta',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                // Animación de puntos
                SizedBox(
                  width: 24,
                  height: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTypingDot(0),
                      _buildTypingDot(1),
                      _buildTypingDot(2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Espaciador para alinear a la izquierda
        const SizedBox(width: 48),
      ],
    );
  }

  /// Widget para cada punto de la animación de escritura
  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _voiceAnimationController,
      builder: (context, child) {
        final animationValue = _voiceAnimationController.value;
        final delay = index * 0.2;
        final dotValue = ((animationValue + delay) % 1.0);
        final opacity = (0.3 + 0.7 * (1 - (dotValue - 0.5).abs() * 2)).clamp(
          0.3,
          1.0,
        );

        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withOpacity(opacity),
          ),
        );
      },
    );
  }
}
