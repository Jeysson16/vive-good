import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/chat/chat_message.dart';
import 'assistant_avatar_widget.dart';

class ChatMessagesWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isLoading;
  final void Function(ChatMessage)? onMessageTap;
  final void Function(ChatMessage)? onMessageLongPress;
  final bool showTimestamps;
  final bool showReadStatus;

  const ChatMessagesWidget({
    super.key,
    required this.messages,
    required this.scrollController,
    this.isLoading = false,
    this.onMessageTap,
    this.onMessageLongPress,
    this.showTimestamps = true,
    this.showReadStatus = true,
  });

  @override
  State<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends State<ChatMessagesWidget>
    with TickerProviderStateMixin {
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isLoading) {
      _typingController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(ChatMessagesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _typingController.repeat(reverse: true);
      } else {
        _typingController.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // Mostrar indicador de escritura al final
          if (index == widget.messages.length && widget.isLoading) {
            return _buildTypingIndicator();
          }
          
          final message = widget.messages[index];
          final isLastMessage = index == widget.messages.length - 1;
          final showTimestamp = _shouldShowTimestamp(index);
          
          return Column(
            children: [
              if (showTimestamp)
                _buildTimestampDivider(message.createdAt),
              
              _buildMessageBubble(
                message,
                isLastMessage,
              ),
              
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
  
  bool _shouldShowTimestamp(int index) {
    if (!widget.showTimestamps || index == 0) return true;
    
    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];
    
    // Mostrar timestamp si han pasado más de 5 minutos
    final timeDifference = currentMessage.createdAt
        .difference(previousMessage.createdAt)
        .inMinutes;
    
    return timeDifference > 5;
  }
  
  Widget _buildTimestampDivider(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    String timeText;
    if (messageDate == today) {
      timeText = DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      timeText = 'Ayer ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      timeText = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              timeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message, bool isLastMessage) {
    final isUser = message.type == MessageType.user;
    
    return GestureDetector(
      onTap: () => widget.onMessageTap?.call(message),
        onLongPress: () => widget.onMessageLongPress?.call(message),
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 50 : 0,
          right: isUser ? 0 : 50,
          bottom: isLastMessage ? 16 : 0,
        ),
        child: Column(
          crossAxisAlignment: isUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            // Burbuja del mensaje
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message, isUser),
            ),
            
            // Información adicional del mensaje
            if (widget.showReadStatus)
              _buildMessageInfo(message, isUser),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageContent(ChatMessage message, bool isUser) {
    switch (message.type) {
      case MessageType.user:
      case MessageType.assistant:
      case MessageType.system:
        return _buildTextContent(message.content, isUser);
    }
  }
  
  Widget _buildTextContent(String content, bool isUser) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: isUser ? Colors.white : const Color(0xFF2D3748),
        height: 1.4,
      ),
    );
  }
  
  Widget _buildMessageInfo(ChatMessage message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timestamp del mensaje
          Text(
            DateFormat('HH:mm').format(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    if (confidence >= 0.8) {
      color = Colors.green;
    } else if (confidence >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 50, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: AnimatedBuilder(
        animation: _typingAnimation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final delay = index * 0.3;
              final animationValue = (_typingAnimation.value + delay) % 1.0;
              final opacity = (math.sin(animationValue * math.pi) * 0.5) + 0.5;
              
              return Container(
                margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }


}