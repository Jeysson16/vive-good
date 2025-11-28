import 'package:flutter/material.dart';

class AnimatedSuccessWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  
  const AnimatedSuccessWidget({
    super.key,
    this.message = '¡Éxito!',
    this.onDismiss,
  });
  
  @override
  State<AnimatedSuccessWidget> createState() => _AnimatedSuccessWidgetState();
}

class _AnimatedSuccessWidgetState extends State<AnimatedSuccessWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _checkAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
    
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkController.forward();
    });
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _checkAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CheckmarkPainter(_checkAnimation.value),
                    size: const Size(80, 80),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onDismiss != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ],
      ),
    );
  }
}

// Custom painter for checkmark animation
class CheckmarkPainter extends CustomPainter {
  final double progress;
  
  CheckmarkPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    
    // Checkmark path
    final startPoint = Offset(center.dx - 12, center.dy);
    final middlePoint = Offset(center.dx - 4, center.dy + 8);
    final endPoint = Offset(center.dx + 12, center.dy - 8);
    
    if (progress > 0) {
      path.moveTo(startPoint.dx, startPoint.dy);
      
      if (progress <= 0.5) {
        // First half: draw to middle point
        final currentPoint = Offset.lerp(
          startPoint,
          middlePoint,
          progress * 2,
        )!;
        path.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Second half: draw to end point
        path.lineTo(middlePoint.dx, middlePoint.dy);
        final currentPoint = Offset.lerp(
          middlePoint,
          endPoint,
          (progress - 0.5) * 2,
        )!;
        path.lineTo(currentPoint.dx, currentPoint.dy);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}