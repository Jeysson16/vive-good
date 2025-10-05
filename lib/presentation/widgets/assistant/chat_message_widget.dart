import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/chat/chat_message.dart';
import 'assistant_avatar_widget.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onPlayAudio;
  final VoidCallback? onStopAudio;
  final bool isPlaying;
  final bool showAvatar;
  final bool showTimestamp;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onPlayAudio,
    this.onStopAudio,
    this.isPlaying = false,
    this.showAvatar = true,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar) ...[
            const MiniAssistantAvatar(
              size: 32,
              isActive: false,
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context, isUser),
                if (showTimestamp) _buildTimestamp(context, isUser),
              ],
            ),
          ),
          
          if (isUser && showAvatar) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isUser) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).primaryColor
            : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          Text(
            message.content,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          
          // Audio controls if message has audio
          // Audio controls removed - not supported in current ChatMessage structure
           // if (message.metadata?['audioUrl'] != null) ..[
           //   const SizedBox(height: 8),
           //   _buildAudioControls(context, isUser),
           // ],
          
          // Message actions
          if (!isUser) ...[
            const SizedBox(height: 8),
            _buildMessageActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioControls(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withOpacity(0.2)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (isPlaying) {
                onStopAudio?.call();
              } else {
                // onPlayAudio?.call(message.metadata?['audioUrl']);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isUser ? Colors.white : Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isUser ? Theme.of(context).primaryColor : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Audio waveform or duration
          Expanded(
            child: Container(
              height: 20,
              child: isPlaying
                  ? _buildAudioWaveform(isUser)
                  : _buildAudioDuration(isUser),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioWaveform(bool isUser) {
    return Row(
      children: List.generate(20, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: (index % 3 + 1) * 6.0,
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAudioDuration(bool isUser) {
    return Text(
      '0:00', // Fixed duration since audioUrl is not available
      style: TextStyle(
        color: isUser
            ? Colors.white.withOpacity(0.8)
            : Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  Widget _buildMessageActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.copy,
          onTap: () {
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mensaje copiado'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.thumb_up_outlined,
          onTap: () {
            // Handle like action
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.thumb_down_outlined,
          onTap: () {
            // Handle dislike action
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, bool isUser) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: isUser ? 0 : 16,
        right: isUser ? 16 : 0,
      ),
      child: Text(
        _formatTimestamp(message.createdAt),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Typing indicator widget
class TypingIndicatorWidget extends StatefulWidget {
  final bool isVisible;
  final Color? color;

  const TypingIndicatorWidget({
    super.key,
    this.isVisible = true,
    this.color,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const MiniAssistantAvatar(
            size: 32,
            isActive: true,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _animations.asMap().entries.map((entry) {
                return AnimatedBuilder(
                  animation: entry.value,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (widget.color ?? Colors.grey[400])!
                            .withOpacity(0.3 + (entry.value.value * 0.7)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}