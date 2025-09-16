import 'package:flutter/material.dart';

class AnimatedMicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isListening;
  
  const AnimatedMicButton({
    Key? key,
    required this.onPressed,
    this.isListening = false,
  }) : super(key: key);

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Start pulse animation if listening
    if (widget.isListening) {
      _startPulseAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _startPulseAnimation();
      } else {
        _stopPulseAnimation();
      }
    }
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
    _rippleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _pulseAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect
                  if (_rippleAnimation.value > 0)
                    Container(
                      width: 64 * (1 + _rippleAnimation.value * 0.5),
                      height: 64 * (1 + _rippleAnimation.value * 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withOpacity(
                          0.3 * (1 - _rippleAnimation.value),
                        ),
                      ),
                    ),
                  
                  // Pulse effect for listening state
                  if (widget.isListening)
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.2),
                        ),
                      ),
                    ),
                  
                  // Main button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isListening
                            ? [
                                const Color(0xFFEF4444),
                                const Color(0xFFDC2626),
                              ]
                            : [
                                const Color(0xFF10B981),
                                const Color(0xFF059669),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isListening
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                              .withOpacity(0.4),
                          blurRadius: _isPressed ? 8 : 16,
                          offset: Offset(0, _isPressed ? 2 : 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}