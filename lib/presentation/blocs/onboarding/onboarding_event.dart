part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

class LoadOnboardingSteps extends OnboardingEvent {
  const LoadOnboardingSteps();
}

class NextStep extends OnboardingEvent {
  const NextStep();
}

class PreviousStep extends OnboardingEvent {
  const PreviousStep();
}

class SkipOnboarding extends OnboardingEvent {
  const SkipOnboarding();
}

class CompleteOnboardingEvent extends OnboardingEvent {
  const CompleteOnboardingEvent();
}