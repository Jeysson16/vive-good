part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingLoaded extends OnboardingState {
  final List<OnboardingStep> steps;
  final int currentIndex;

  const OnboardingLoaded({
    required this.steps,
    required this.currentIndex,
  });

  @override
  List<Object> get props => [steps, currentIndex];

  OnboardingStep get currentStep => steps[currentIndex];
  bool get isFirstStep => currentIndex == 0;
  bool get isLastStep => currentIndex == steps.length - 1;

  OnboardingLoaded copyWith({
    List<OnboardingStep>? steps,
    int? currentIndex,
  }) {
    return OnboardingLoaded(
      steps: steps ?? this.steps,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class OnboardingCompleted extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError({required this.message});

  @override
  List<Object> get props => [message];
}