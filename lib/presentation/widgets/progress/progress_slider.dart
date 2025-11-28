import 'package:flutter/material.dart';

class ProgressSlider extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const ProgressSlider({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = const Color(0xFF4CAF50),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.dotSize = 12,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalSteps,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Paso $currentStep de $totalSteps',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index < currentStep;
    final isCurrent = index == currentStep - 1;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isCurrent ? dotSize * 1.5 : dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: isActive || isCurrent ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(dotSize / 2),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class LinearProgressSlider extends StatelessWidget {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final String? label;

  const LinearProgressSlider({
    super.key,
    required this.progress,
    this.activeColor = const Color(0xFF4CAF50),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.height = 8,
    this.borderRadius,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).round()}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class StepProgressSlider extends StatelessWidget {
  final int currentStep;
  final List<String> stepLabels;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;
  final double lineHeight;

  const StepProgressSlider({
    super.key,
    required this.currentStep,
    required this.stepLabels,
    this.activeColor = const Color(0xFF4CAF50),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.completedColor = const Color(0xFF4CAF50),
    this.lineHeight = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(
            stepLabels.length * 2 - 1,
            (index) {
              if (index.isEven) {
                final stepIndex = index ~/ 2;
                return _buildStepCircle(stepIndex);
              } else {
                final lineIndex = index ~/ 2;
                return _buildConnectingLine(lineIndex);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stepLabels.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            return Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: index <= currentStep ? Colors.black87 : Colors.black38,
                  fontWeight: index == currentStep ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final isCompleted = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;
    final isInactive = stepIndex > currentStep;

    Color circleColor;
    Widget? child;

    if (isCompleted) {
      circleColor = completedColor;
      child = const Icon(
        Icons.check,
        color: Colors.white,
        size: 16,
      );
    } else if (isCurrent) {
      circleColor = activeColor;
      child = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      circleColor = inactiveColor;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: activeColor, width: 2)
            : null,
      ),
      child: child,
    );
  }

  Widget _buildConnectingLine(int lineIndex) {
    final isCompleted = lineIndex < currentStep;
    
    return Expanded(
      child: Container(
        height: lineHeight,
        color: isCompleted ? completedColor : inactiveColor,
      ),
    );
  }
}