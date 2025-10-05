import 'package:flutter/material.dart';
import 'voice_animation_widget.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final Function(String) onSendMessage;
  final VoidCallback onStartVoiceRecording;
  final VoidCallback onStopVoiceRecording;
  final bool isRecording;
  final bool isListening;
  final bool isLoading;
  final String? voiceInputText;
  final double? voiceLevel;

  const ChatInputWidget({
    super.key,
    required this.textController,
    required this.onSendMessage,
    required this.onStartVoiceRecording,
    required this.onStopVoiceRecording,
    this.isRecording = false,
    this.isListening = false,
    this.isLoading = false,
    this.voiceInputText,
    this.voiceLevel,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  bool _showTextField = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    widget.textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
    
    if (widget.voiceInputText != oldWidget.voiceInputText &&
        widget.voiceInputText != null &&
        widget.voiceInputText!.isNotEmpty) {
      widget.textController.text = widget.voiceInputText!;
    }
  }

  void _onTextChanged() {
    setState(() {
      // Rebuild to update send button state
    });
  }

  void _onFocusChanged() {
    setState(() {
      _showTextField = _focusNode.hasFocus || widget.textController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    widget.textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice input feedback
            if (widget.isRecording || widget.isListening)
              _buildVoiceInputFeedback(),
            
            // Main input row
            Row(
              children: [
                // Text input field
                Expanded(
                  child: _buildTextInput(),
                ),
                
                const SizedBox(width: 12),
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputFeedback() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Voice animation
          SizedBox(
            width: 30, // Reducido de 40 a 30
            height: 30, // Reducido de 40 a 30
            child: VoiceAnimationWidget(
              controller: _pulseController,
              amplitude: widget.voiceLevel ?? 0.0,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isRecording
                      ? 'Escuchando...'
                      : widget.isListening
                          ? 'Procesando...'
                          : 'Listo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                if (widget.voiceInputText != null &&
                    widget.voiceInputText!.isNotEmpty)
                  Text(
                    widget.voiceInputText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Stop button
          if (widget.isRecording)
            GestureDetector(
              onTap: widget.onStopVoiceRecording,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: TextField(
        controller: widget.textController,
        focusNode: _focusNode,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Escribe tu mensaje...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          suffixIcon: widget.textController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    widget.textController.clear();
                    _focusNode.unfocus();
                  },
                  child: const Icon(
                    Icons.clear,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        onSubmitted: (text) {
          if (text.trim().isNotEmpty) {
            widget.onSendMessage(text.trim());
            widget.textController.clear();
          }
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attachment button (optional)
        if (!hasText && !widget.isRecording)
          _buildActionButton(
            icon: Icons.attach_file,
            onTap: () {
              // Handle attachment
            },
            backgroundColor: Colors.grey[100],
            iconColor: Colors.grey[600],
          ),
        
        if (!hasText && !widget.isRecording)
          const SizedBox(width: 8),
        
        // Main action button (voice or send)
        _buildMainActionButton(hasText),
      ],
    );
  }

  Widget _buildMainActionButton(bool hasText) {
    if (hasText) {
      // Send button
      return _buildActionButton(
        icon: Icons.send,
        onTap: () {
          final text = widget.textController.text.trim();
          if (text.isNotEmpty) {
            widget.onSendMessage(text);
            widget.textController.clear();
            _focusNode.unfocus();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        iconColor: Colors.white,
        isLoading: widget.isLoading,
      );
    } else {
      // Voice button
      return GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: widget.isRecording
            ? widget.onStopVoiceRecording
            : widget.onStartVoiceRecording,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.isRecording
                    ? Colors.red
                    : Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? Colors.red
                            : Theme.of(context).primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: widget.isRecording ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isRecording ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
          ),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconColor ?? Colors.white,
                  ),
                ),
              )
            : Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 20,
              ),
      ),
    );
  }
}