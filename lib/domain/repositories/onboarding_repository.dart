import 'package:dartz/dartz.dart';
import '../entities/onboarding_step.dart';
import '../../core/error/failures.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, List<OnboardingStep>>> getOnboardingSteps();
  Future<Either<Failure, OnboardingStep?>> getOnboardingStepById(String id);
  Future<Either<Failure, int>> getCurrentStepIndex();
  Future<Either<Failure, void>> setCurrentStepIndex(int index);
  Future<Either<Failure, void>> completeOnboarding();
  Future<Either<Failure, bool>> isOnboardingCompleted();
}