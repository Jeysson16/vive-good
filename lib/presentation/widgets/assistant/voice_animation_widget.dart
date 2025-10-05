import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceAnimationWidget extends StatelessWidget {
  final AnimationController controller;
  final double amplitude;
  final Color? color;
  final int waveCount;

  const VoiceAnimationWidget({
    super.key,
    required this.controller,
    this.amplitude = 0.5,
    this.color,
    this.waveCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: VoiceWavePainter(
            animation: controller,
            amplitude: amplitude,
            color: primaryColor,
            waveCount: waveCount,
          ),
          size: const Size(60, 60), // Reducido significativamente de 200x200 a 60x60
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;
  final int waveCount;

  VoiceWavePainter({
    required this.animation,
    required this.amplitude,
    required this.color,
    required this.waveCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.15; // Ajustado para el tamaño más pequeño
    
    // Create paint for waves with smoother appearance
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 // Reducido para el tamaño más pequeño
      ..strokeCap = StrokeCap.round;

    // Draw multiple concentric waves with improved timing
    for (int i = 0; i < waveCount; i++) {
      final waveOffset = (i * 0.3) % 1.0; // Más suave
      final animationValue = (animation.value + waveOffset) % 1.0;
      
      // Smoother wave expansion with easing
      final easedValue = _easeInOutCubic(animationValue);
      final waveRadius = baseRadius + (i * 8) + (amplitude * 15 * easedValue); // Ajustado para tamaño pequeño
      
      // Improved opacity calculation for smoother fade
      final opacity = (1.0 - easedValue) * (0.6 - i * 0.1) * (0.4 + amplitude * 0.6); // Más suave
      
      // Set paint color with opacity
      paint.color = color.withOpacity(opacity.clamp(0.0, 0.6)); // Menos opacidad para suavidad
      
      // Draw wave circle
      canvas.drawCircle(center, waveRadius, paint);
    }
    
    // Solo mantener las ondas - eliminar círculos y partículas
  }

  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }



  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.color != color;
  }
}

/// Alternative voice animation with bars
class VoiceBarsWidget extends StatelessWidget {
  final AnimationController controller;
  final double amplitude;
  final Color? color;
  final int barCount;

  const VoiceBarsWidget({
    super.key,
    required this.controller,
    this.amplitude = 0.5,
    this.color,
    this.barCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: VoiceBarsPainter(
            animation: controller,
            amplitude: amplitude,
            color: primaryColor,
            barCount: barCount,
          ),
          size: const Size(100, 60),
        );
      },
    );
  }
}

class VoiceBarsPainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;
  final int barCount;

  VoiceBarsPainter({
    required this.animation,
    required this.amplitude,
    required this.color,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / (barCount * 2 - 1);
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2;
      
      // Create wave effect with different phases for each bar
      final phase = (i * 0.2) + animation.value * 2 * math.pi;
      final barHeight = (maxBarHeight * 0.2) + 
                       (maxBarHeight * 0.8 * amplitude * math.sin(phase).abs());
      
      final rect = Rect.fromLTWH(
        x,
        centerY - barHeight / 2,
        barWidth,
        barHeight,
      );
      
      // Add opacity variation
      final opacity = 0.6 + (0.4 * math.sin(phase));
      paint.color = color.withOpacity(opacity);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(VoiceBarsPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.color != color;
  }
}