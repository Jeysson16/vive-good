import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/onboarding_step.dart';
import '../../../domain/usecases/onboarding/get_onboarding_steps.dart';
import '../../../domain/usecases/onboarding/get_current_step_index.dart';
import '../../../domain/usecases/onboarding/set_current_step_index.dart';
import '../../../domain/usecases/onboarding/complete_onboarding.dart';
import '../../../core/usecases/usecase.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetOnboardingSteps getOnboardingSteps;
  final GetCurrentStepIndex getCurrentStepIndex;
  final SetCurrentStepIndex setCurrentStepIndex;
  final CompleteOnboarding completeOnboarding;

  OnboardingBloc({
    required this.getOnboardingSteps,
    required this.getCurrentStepIndex,
    required this.setCurrentStepIndex,
    required this.completeOnboarding,
  }) : super(OnboardingInitial()) {
    on<LoadOnboardingSteps>(_onLoadOnboardingSteps);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<SkipOnboarding>(_onSkipOnboarding);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
  }

  Future<void> _onLoadOnboardingSteps(
    LoadOnboardingSteps event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());

    try {
      final stepsResult = await getOnboardingSteps.call();
      final currentIndexResult = await getCurrentStepIndex.call();

      stepsResult.fold(
        (failure) => emit(OnboardingError(message: failure.message)),
        (steps) {
          currentIndexResult.fold(
            (failure) => emit(OnboardingError(message: failure.message)),
            (currentIndex) {
              emit(OnboardingLoaded(
                steps: steps,
                currentIndex: currentIndex,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(OnboardingError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onNextStep(
    NextStep event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      final nextIndex = currentState.currentIndex + 1;

      if (nextIndex < currentState.steps.length) {
        final result = await setCurrentStepIndex.call(nextIndex);
        result.fold(
          (failure) => emit(OnboardingError(message: failure.message)),
          (_) => emit(currentState.copyWith(currentIndex: nextIndex)),
        );
      } else {
        // Último paso alcanzado, completar onboarding
        add(const CompleteOnboardingEvent());
      }
    }
  }

  Future<void> _onPreviousStep(
    PreviousStep event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      final previousIndex = currentState.currentIndex - 1;

      if (previousIndex >= 0) {
        final result = await setCurrentStepIndex.call(previousIndex);
        result.fold(
          (failure) => emit(OnboardingError(message: failure.message)),
          (_) => emit(currentState.copyWith(currentIndex: previousIndex)),
        );
      }
    }
  }

  Future<void> _onSkipOnboarding(
    SkipOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    add(const CompleteOnboardingEvent());
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final result = await completeOnboarding.call(const NoParams());
      result.fold(
        (failure) => emit(OnboardingError(message: failure.message)),
        (_) => emit(OnboardingCompleted()),
      );
    } catch (e) {
      emit(OnboardingError(message: 'Failed to complete onboarding: ${e.toString()}'));
    }
  }
}