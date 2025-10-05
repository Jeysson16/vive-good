import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/chat/instruction_chip_widget.dart';
import 'chat_conversation_page.dart';

/// Página de introducción al chat siguiendo el diseño de Figma 2067_355
class ChatIntroPage extends StatefulWidget {
  const ChatIntroPage({super.key});

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
            builder: (context) => ChatConversationPage(
              initialMessage: message,
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
          child: Stack(
            children: [
              // Botón de retroceso
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF333333),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Espaciado superior
                    const SizedBox(height: 40),
                
                // Logo Vive Good
                _buildLogo(),
                
                const SizedBox(height: 60),
                
                // Chips de instrucciones
                _buildInstructionChips(),
                
                const Spacer(),
                
                    // Campo de mensaje y botón de envío
                    _buildMessageInput(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
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
      'Identifica síntomas y factores de riesgo de gastritis',
      'Haz preguntas, recibe consejos y corrige tu estilo de vida fácilmente',
      'Evalúa tus rutinas diarias y detecta riesgos invisibles',
      'La app te motiva a vivir mejor con pequeñas acciones cada día',
    ];

    return Column(
      children: instructions.map((instruction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InstructionChipWidget(
            text: instruction,
            onTap: () {
              _messageController.text = instruction;
              _messageFocusNode.requestFocus();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
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
                  horizontal: 20,
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
            ),
          ),
          
          // Botón de envío
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isNotEmpty && !_isLoading
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFCCCCCC),
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
}