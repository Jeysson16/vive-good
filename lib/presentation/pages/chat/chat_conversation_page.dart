import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/chat/chat_message_widget.dart';
import '../../widgets/chat/typing_indicator_widget.dart';
import '../../widgets/chat/regenerate_button_widget.dart';
import '../../../domain/entities/chat/chat_message.dart';
import 'chat_history_page.dart';

/// Página de conversación de chat siguiendo el diseño de Figma 2067_518
class ChatConversationPage extends StatefulWidget {
  final String? initialMessage;
  final String? sessionId;

  const ChatConversationPage({
    super.key,
    this.initialMessage,
    this.sessionId,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  String? _currentSessionId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _initializeChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (widget.sessionId != null) {
      // Usar sesión existente
      _currentSessionId = widget.sessionId;
      context.read<ChatBloc>().add(SelectSession(widget.sessionId!));
    } else {
      // Crear nueva sesión si hay mensaje inicial
      if (widget.initialMessage != null) {
        context.read<ChatBloc>().add(CreateNewSession(user.id));
      }
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentSessionId == null) return;

    context.read<ChatBloc>().add(SendUserMessage(
      sessionId: _currentSessionId!,
      content: message,
    ));

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  void _regenerateLastResponse() {
    final state = context.read<ChatBloc>().state;
    if (state is ChatLoaded && state.messages.isNotEmpty) {
      // Buscar el último mensaje del usuario
      final userMessages = state.messages
          .where((m) => m.type == MessageType.user)
          .toList();
      
      if (userMessages.isNotEmpty) {
        final lastUserMessage = userMessages.last;
        context.read<ChatBloc>().add(RegenerateResponse(
          sessionId: _currentSessionId!,
          lastUserMessage: lastUserMessage.content,
        ));
      }
    }
  }

  void _stopGeneration() {
    context.read<ChatBloc>().add(const SetTypingStatus(false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is EmptySession || state is ChatLoaded) {
            if (state is EmptySession) {
              _currentSessionId = state.currentSession.id;
              
              // Enviar mensaje inicial si existe
              if (widget.initialMessage != null && !_isInitialized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<ChatBloc>().add(SendUserMessage(
                    sessionId: _currentSessionId!,
                    content: widget.initialMessage!,
                  ));
                });
              }
            } else if (state is ChatLoaded) {
              _currentSessionId = state.currentSession?.id;
              _scrollToBottom();
            }
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return Column(
              children: [
                // Área de mensajes
                Expanded(
                  child: _buildMessagesArea(state),
                ),
                
                // Botón de regenerar (si aplica)
                _buildRegenerateButton(state),
                
                // Campo de entrada de mensaje
                _buildMessageInput(state),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF333333),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.history,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryPage(),
                ),
              );
            },
            tooltip: 'Historial',
          ),
          const SizedBox(width: 8),
          const Text(
            'Chat',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.assistant,
            color: Color(0xFF4CAF50),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Volver al main page donde está el asistente
          },
          tooltip: 'Ir al Asistente',
        ),
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: Color(0xFF333333),
          ),
          onPressed: () {
            // TODO: Implementar menú de opciones
          },
        ),
      ],
    );
  }

  Widget _buildMessagesArea(ChatState state) {
    if (state is MessagesLoading || state is SessionsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      );
    }

    if (state is EmptySession) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              'Inicia una conversación',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Escribe un mensaje para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

    if (state is ChatLoaded) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.messages.length + (state.isAssistantTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.messages.length) {
            final message = state.messages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ChatMessageWidget(
                message: message,
                onEdit: (messageId, newContent) {
                  context.read<ChatBloc>().add(EditMessage(
                    messageId: messageId,
                    newContent: newContent,
                  ));
                },
                onDelete: (messageId) {
                  context.read<ChatBloc>().add(DeleteMessage(messageId));
                },
              ),
            );
          } else {
            // Indicador de escritura
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: TypingIndicatorWidget(),
            );
          }
        },
      );
    }

    if (state is ChatError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ChatBloc>().add(const ClearError());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRegenerateButton(ChatState state) {
    if (state is ChatLoaded && 
        state.messages.isNotEmpty && 
        state.messages.last.type == MessageType.assistant &&
        !state.isAssistantTyping) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: RegenerateButtonWidget(
          onPressed: _regenerateLastResponse,
        ),
      );
    }

    if (state is ChatLoaded && state.isAssistantTyping) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: _stopGeneration,
          icon: const Icon(Icons.stop, size: 18),
          label: const Text('Parar de generar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMessageInput(ChatState state) {
    final isLoading = state is MessageSending || 
                     state is SessionCreating ||
                     (state is ChatLoaded && state.isAssistantTyping);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !isLoading && _currentSessionId != null,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Botón de envío
            GestureDetector(
              onTap: isLoading || _currentSessionId == null ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isNotEmpty && 
                         !isLoading && 
                         _currentSessionId != null
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: isLoading
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
          ],
        ),
      ),
    );
  }
}