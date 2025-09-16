import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_step.dart';

class OnboardingStepWidget extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingStepWidget({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA), // Fondo según diseño Figma
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Expanded(
                flex: 3,
                child: _buildIllustration(),
              ),
              const SizedBox(height: 40),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A), // Color de texto oscuro
                            fontSize: 28,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF6B7280), // Color gris para descripción
                            height: 1.5,
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildIllustration() {
    switch (step.id) {
      case '1':
        // Persona con corazón verde y estrellas (Gestiona el Estrés)
        return Center(
          child: Container(
            width: 303,
            height: 312,
            child: Image.asset(
              'assets/images/onboarding_1.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen no se encuentra
                return Container(
                  width: 303,
                  height: 312,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        );
      case '2':
        // Estómago con rayos (síntomas de gastritis)
        return Center(
          child: Container(
            width: 276,
            height: 282,
            child: Image.asset(
              'assets/images/onboarding_2.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen no se encuentra
                return Container(
                  width: 276,
                  height: 282,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        );
      case '3':
        // Persona con sombrero y zanahoria
        return Center(
          child: Container(
            width: 250,
            height: 296,
            child: Image.asset(
              'assets/images/onboarding_3.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen no se encuentra
                return Container(
                  width: 250,
                  height: 296,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
