import 'package:flutter/material.dart';
import 'dart:math' as math;

class AssistantAvatarWidget extends StatefulWidget {
  final bool isActive;
  final bool isLoading;
  final double size;
  final String? avatarUrl;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AssistantAvatarWidget({
    super.key,
    this.isActive = false,
    this.isLoading = false,
    this.size = 120,
    this.avatarUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<AssistantAvatarWidget> createState() => _AssistantAvatarWidgetState();
}

class _AssistantAvatarWidgetState extends State<AssistantAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  @override
  void didUpdateWidget(AssistantAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
    
    if (widget.isLoading && !oldWidget.isLoading) {
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final secondaryColor = widget.secondaryColor ?? const Color(0xFF81C784);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  secondaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring for loading
                if (widget.isLoading)
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: widget.size * 0.9,
                      height: widget.size * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: LoadingRingPainter(
                          color: primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                
                // Main avatar container
                Container(
                  width: widget.size * 0.7,
                  height: widget.size * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: widget.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(primaryColor);
                            },
                          ),
                        )
                      : _buildDefaultAvatar(primaryColor),
                ),
                
                // Active indicator
                if (widget.isActive)
                  Positioned(
                    bottom: widget.size * 0.1,
                    right: widget.size * 0.1,
                    child: Container(
                      width: widget.size * 0.15,
                      height: widget.size * 0.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(Color iconColor) {
    return Center(
      child: Icon(
        Icons.assistant,
        size: widget.size * 0.3,
        color: iconColor.withOpacity(0.8),
      ),
    );
  }
}

class LoadingRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  LoadingRingPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw partial arc for loading effect
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      math.pi, // Draw half circle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(LoadingRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Simplified assistant avatar for smaller spaces
class MiniAssistantAvatar extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color? color;

  const MiniAssistantAvatar({
    super.key,
    this.isActive = false,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = color ?? theme.primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: avatarColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.psychology,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}

/// Avatar with custom shapes and patterns
class CustomAssistantAvatar extends StatelessWidget {
  final bool isActive;
  final double size;
  final AvatarShape shape;
  final List<Color> gradientColors;

  const CustomAssistantAvatar({
    super.key,
    this.isActive = false,
    this.size = 120,
    this.shape = AvatarShape.circle,
    this.gradientColors = const [Color(0xFF4CAF50), Color(0xFF81C784)],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape == AvatarShape.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shape == AvatarShape.roundedSquare
            ? BorderRadius.circular(size * 0.2)
            : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: isActive ? 20 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.psychology,
        size: size * 0.4,
        color: Colors.white,
      ),
    );
  }
}

enum AvatarShape {
  circle,
  roundedSquare,
  square,
}