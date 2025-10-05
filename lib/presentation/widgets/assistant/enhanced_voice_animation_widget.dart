import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnhancedVoiceAnimationWidget extends StatefulWidget {
  final AnimationController controller;
  final double amplitude;
  final Color? color;
  final bool isListening;
  final bool isActive;
  final String? partialTranscription;

  const EnhancedVoiceAnimationWidget({
    super.key,
    required this.controller,
    this.amplitude = 0.5,
    this.color,
    this.isListening = false,
    this.isActive = false,
    this.partialTranscription,
  });

  @override
  State<EnhancedVoiceAnimationWidget> createState() =>
      _EnhancedVoiceAnimationWidgetState();
}

class _EnhancedVoiceAnimationWidgetState
    extends State<EnhancedVoiceAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _smoothAmplitudeController;
  late Animation<double> _smoothAmplitude;
  double _targetAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _smoothAmplitudeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _smoothAmplitude = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _smoothAmplitudeController,
        curve: Curves.easeInOut,
      ),
    );
    _targetAmplitude = widget.amplitude;
  }

  @override
  void didUpdateWidget(EnhancedVoiceAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amplitude != oldWidget.amplitude) {
      _updateAmplitude(widget.amplitude);
    }
  }

  void _updateAmplitude(double newAmplitude) {
    _targetAmplitude = newAmplitude;
    _smoothAmplitudeController.reset();
    _smoothAmplitudeController.forward();
  }

  @override
  void dispose() {
    _smoothAmplitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? const Color(0xFF4CAF50);

    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _smoothAmplitude]),
      builder: (context, child) {
        // Calculate smooth amplitude interpolation
        final currentAmplitude =
            _smoothAmplitude.value * _targetAmplitude +
            (1 - _smoothAmplitude.value) * widget.amplitude;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0 + (currentAmplitude * 0.3),
              colors: [
                primaryColor.withOpacity(0.1 + currentAmplitude * 0.05),
                primaryColor.withOpacity(0.05 + currentAmplitude * 0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main voice waves only - no central core or particles
              CustomPaint(
                painter: EnhancedVoiceWavePainter(
                  animation: widget.controller,
                  amplitude: currentAmplitude,
                  color: primaryColor,
                  isListening: widget.isListening,
                  isActive: widget.isActive,
                ),
                size: const Size(250, 250),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PulsePainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;

  PulsePainter({
    required this.animation,
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Reducido de 2.0 a 1.5

    // Create breathing pulse effect (más suave y contenido)
    final pulseValue = math.sin(
      animation.value * 1.2 * math.pi,
    ); // Reducido de 1.5 a 1.2
    final radius =
        (size.width * 0.25) +
        (amplitude * 8 * pulseValue); // Reducido de 0.35 a 0.25 y de 15 a 8
    final opacity = (0.03 + (amplitude * 0.06 * pulseValue.abs())).clamp(
      0.0,
      0.15,
    ); // Reducido opacidad máxima

    paint.color = color.withOpacity(opacity);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(PulsePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.amplitude != amplitude;
  }
}

class EnhancedVoiceWavePainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;
  final bool isListening;
  final bool isActive;

  EnhancedVoiceWavePainter({
    required this.animation,
    required this.amplitude,
    required this.color,
    required this.isListening,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.12; // Reducido de 0.15 a 0.12

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isListening
          ? 2.0
          : 1.5 // Reducido de 3.0 a 2.0
      ..strokeCap = StrokeCap.round;

    // Dynamic wave count based on amplitude (reducido)
    final waveCount = isListening
        ? (2 + (amplitude * 2).round())
        : 2; // Reducido de 3 a 2

    for (int i = 0; i < waveCount; i++) {
      final waveOffset =
          (i * 0.4) % 1.0; // Aumentado de 0.3 a 0.4 para más separación
      final animationValue = (animation.value + waveOffset) % 1.0;

      // Enhanced easing for more organic movement
      final easedValue = _enhancedEasing(animationValue);

      // Dynamic radius calculation (más contenido)
      final radiusMultiplier = isListening
          ? (1.0 + amplitude * 0.3)
          : 0.7; // Reducido de 1.2 a 1.0 y de 0.5 a 0.3
      final waveRadius =
          baseRadius +
          (i * 10 * radiusMultiplier) + // Reducido de 15 a 10
          (amplitude * 15 * easedValue); // Reducido de 25 a 15

      // Improved opacity with amplitude influence (más sutil)
      final baseOpacity = isListening
          ? 0.4
          : 0.2; // Reducido de 0.7 a 0.4 y de 0.3 a 0.2
      final opacity =
          ((1.0 - easedValue) *
                  (baseOpacity - i * 0.08) * // Reducido de 0.1 a 0.08
                  (0.3 + amplitude * 0.4))
              .clamp(0.0, 0.6); // Reducido máximo de 1.0 a 0.6

      // Color intensity based on amplitude (más sutil)
      final colorIntensity = (0.5 + (amplitude * 0.3)).clamp(
        0.0,
        0.8,
      ); // Reducido de 0.6 a 0.5 y de 0.4 a 0.3
      paint.color = Color.lerp(
        color.withOpacity(
          (opacity * 0.4).clamp(0.0, 0.6),
        ), // Reducido de 0.5 a 0.4
        color.withOpacity(opacity),
        colorIntensity,
      )!;

      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  double _enhancedEasing(double t) {
    // Custom easing for more natural wave movement
    return math.sin(t * math.pi * 0.5);
  }

  @override
  bool shouldRepaint(EnhancedVoiceWavePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.isListening != isListening ||
        oldDelegate.isActive != isActive;
  }
}

class DynamicCorePainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;
  final bool isListening;
  final bool hasText;

  DynamicCorePainter({
    required this.animation,
    required this.amplitude,
    required this.color,
    required this.isListening,
    required this.hasText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.2; // Reducido de 0.3 a 0.2

    final paint = Paint()..style = PaintingStyle.fill;

    // Dynamic core size based on listening state and amplitude (más suave)
    final coreMultiplier = isListening
        ? (1.0 + amplitude * 0.2)
        : 0.7; // Reducido de 0.5 a 0.2
    final coreRadius = baseRadius * coreMultiplier;

    // Pulsing effect when has text (más suave)
    final pulseEffect = hasText
        ? math.sin(animation.value * 2 * math.pi) * 0.05
        : 0.0; // Reducido de 4 a 2 y de 0.1 a 0.05
    final finalRadius =
        coreRadius +
        (pulseEffect * baseRadius * 0.3); // Añadido multiplicador 0.3

    // Dynamic opacity
    final coreOpacity = (isListening ? (0.8 + amplitude * 0.2) : 0.5).clamp(
      0.0,
      1.0,
    );

    // Create gradient based on state
    final gradientColors = isListening
        ? [
            color.withOpacity(coreOpacity),
            color.withOpacity((coreOpacity * 0.6).clamp(0.0, 1.0)),
            color.withOpacity((coreOpacity * 0.2).clamp(0.0, 1.0)),
          ]
        : [
            color.withOpacity((coreOpacity * 0.7).clamp(0.0, 1.0)),
            color.withOpacity((coreOpacity * 0.3).clamp(0.0, 1.0)),
          ];

    final gradient = RadialGradient(
      colors: gradientColors,
      stops: isListening ? [0.0, 0.7, 1.0] : [0.0, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: finalRadius),
    );

    canvas.drawCircle(center, finalRadius, paint);

    // Add inner highlight when listening
    if (isListening) {
      paint.shader = null;
      paint.color = Colors.white.withOpacity(
        (0.3 + amplitude * 0.2).clamp(0.0, 1.0),
      );
      canvas.drawCircle(center, finalRadius * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(DynamicCorePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.isListening != isListening ||
        oldDelegate.hasText != hasText;
  }
}

class FloatingParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;

  FloatingParticlesPainter({
    required this.animation,
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Dynamic particle count based on amplitude with more responsive scaling
    final particleCount = (6 + (amplitude * 12)).round().clamp(6, 18);

    for (int i = 0; i < particleCount; i++) {
      // More dynamic rotation based on amplitude
      final rotationSpeed = 0.2 + (amplitude * 0.4);
      final angle =
          (i * 2 * math.pi / particleCount) +
          (animation.value * math.pi * rotationSpeed);

      // Enhanced distance calculation with amplitude response
      final baseDistance = size.width * 0.25;
      final amplitudeBoost = amplitude * 30;
      final waveEffect =
          math.sin(animation.value * 4 * math.pi + i * 0.5) *
          (10 + amplitude * 15);
      final distance = baseDistance + amplitudeBoost + waveEffect;

      final particleOffset = Offset(
        center.dx + distance * math.cos(angle),
        center.dy + distance * math.sin(angle),
      );

      // Enhanced floating effect with multiple wave frequencies
      final floatOffset1 =
          math.sin(animation.value * 5 * math.pi + i * 0.7) * amplitude * 10;
      final floatOffset2 =
          math.cos(animation.value * 3 * math.pi + i * 1.2) * amplitude * 6;

      final adjustedOffset = Offset(
        particleOffset.dx + floatOffset2,
        particleOffset.dy + floatOffset1,
      );

      // More dynamic size with amplitude response
      final baseSizeMultiplier = 0.8 + amplitude * 0.7;
      final pulseEffect = math.sin(animation.value * 6 * math.pi + i * 0.8);
      final particleSize =
          (1.5 + amplitude * 4) *
          baseSizeMultiplier *
          (0.6 + 0.4 * pulseEffect);

      // Enhanced opacity with better amplitude response
      final baseOpacity = 0.2 + amplitude * 0.6;
      final flickerEffect = math.sin(animation.value * 8 * math.pi + i * 1.1);
      final opacity = (baseOpacity * (0.5 + 0.5 * flickerEffect)).clamp(
        0.0,
        0.9,
      );

      // Add subtle color variation based on amplitude
      final colorIntensity = (0.7 + amplitude * 0.3).clamp(0.0, 1.0);
      final particleColor = Color.lerp(
        color.withOpacity(opacity * 0.6),
        color.withOpacity(opacity),
        colorIntensity,
      )!;

      paint.color = particleColor;
      canvas.drawCircle(adjustedOffset, particleSize, paint);

      // Add inner glow for high amplitude particles
      if (amplitude > 0.6 && particleSize > 3) {
        paint.color = Colors.white.withOpacity((opacity * 0.3).clamp(0.0, 0.4));
        canvas.drawCircle(adjustedOffset, particleSize * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.amplitude != amplitude;
  }
}
