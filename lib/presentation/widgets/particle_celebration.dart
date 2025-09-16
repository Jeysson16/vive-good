import 'dart:math';
import 'package:flutter/material.dart';

class ParticleCelebration extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onComplete;

  const ParticleCelebration({
    super.key,
    required this.isVisible,
    this.onComplete,
  });

  @override
  State<ParticleCelebration> createState() => _ParticleCelebrationState();
}

class _ParticleCelebrationState extends State<ParticleCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _particles = List.generate(12, (index) => _createParticle());

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ParticleCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _particles = List.generate(12, (index) => _createParticle());
    _controller.reset();
    _controller.forward();
  }

  Particle _createParticle() {
    return Particle(
      startX: 0.5,
      startY: 0.5,
      endX: 0.5 + (_random.nextDouble() - 0.5) * 2,
      endY: 0.5 + (_random.nextDouble() - 0.5) * 2,
      color: _getRandomColor(),
      size: _random.nextDouble() * 4 + 2,
    );
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF22C55E),
      const Color(0xFF10B981),
      const Color(0xFF34D399),
      const Color(0xFF6EE7B7),
      const Color(0xFFFBBF24),
      const Color(0xFFF59E0B),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class Particle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;

  Particle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;

      // Calculate current position
      final currentX =
          particle.startX + (particle.endX - particle.startX) * progress;
      final currentY =
          particle.startY + (particle.endY - particle.startY) * progress;

      // Apply easing for more natural movement
      final easedProgress = Curves.easeOut.transform(progress);
      final x =
          size.width *
          (particle.startX + (particle.endX - particle.startX) * easedProgress);
      final y =
          size.height *
          (particle.startY + (particle.endY - particle.startY) * easedProgress);

      // Draw particle with size animation
      final currentSize = particle.size * (1.0 - progress * 0.5);
      canvas.drawCircle(Offset(x, y), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
