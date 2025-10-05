import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/assistant/assistant_bloc.dart';
import '../../blocs/assistant/assistant_state.dart';
import '../../blocs/assistant/assistant_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/assistant/voice_animation_widget.dart';
import '../../widgets/assistant/enhanced_voice_animation_widget.dart';
import '../../widgets/assistant/suggestion_chip_widget.dart';
import '../../widgets/assistant/chat_message_widget.dart';
import '../../widgets/assistant/assistant_avatar_widget.dart';
import '../chat/chat_intro_page.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../../data/repositories/supabase_chat_repository.dart';
import '../../../data/datasources/chat_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routes/app_routes.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

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
            Color.fromARGB(255, 213, 245, 213), // Verde muy suave en la parte inferior
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
                      
                      // Contenido principal
                      Expanded(
                        child: state.messages.isEmpty 
                                ? _buildWelcomeScreen(context, state)
                                : _buildChatView(context, state),
                      ),
                      
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

    return Container(
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
          
          // Show transcribed text when available
          if (state.textInput.isNotEmpty && !state.isRecording)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    state.textInput,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          
          const SizedBox(height: 40),
          
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
                      isActive: state.isRecording || state.isPlayingAudio || state.isLoading,
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
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ChatMessageWidget(
              message: message,
              onPlayAudio: (audioUrl) {
                context.read<AssistantBloc>().add(
                  StartVoicePlayback(audioUrl),
                );
              },
              onStopAudio: () {
                context.read<AssistantBloc>().add(
                  const StopVoicePlayback(),
                );
              },
              isPlaying: state.isPlayingAudio && 
                        state.currentAudioUrl != null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomInputArea(BuildContext context, AssistantState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        child: Row(
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => ChatBloc(
                          chatRepository: SupabaseChatRepository(
                            ChatRemoteDataSource(
                              Supabase.instance.client,
                            ),
                          ),
                        ),
                        child: const ChatIntroPage(),
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
                  boxShadow: state.isRecording ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
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
                  context.go('/main');
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
        ),
      ),
    );
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
    final bool shouldShow = state.isRecording || state.partialTranscription.isNotEmpty;
    
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
              color: const Color(0xFF4CAF50).withOpacity(shouldShow ? 0.3 : 0.0),
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
                      key: ValueKey(state.partialTranscription.isEmpty ? 'listening' : 'transcription'),
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
    final hasSummary = state.messages.any((message) => message.content.contains('Resumen de la conversación') || message.content.contains('Summary'));
    
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
}