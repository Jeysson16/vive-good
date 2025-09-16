import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/onboarding_step.dart';
import '../repositories/onboarding_repository.dart';

class GetOnboardingStepsUseCase implements UseCase<List<OnboardingStep>, NoParams> {
  final OnboardingRepository repository;

  GetOnboardingStepsUseCase(this.repository);

  @override
  Future<Either<Failure, List<OnboardingStep>>> call(NoParams params) async {
    return await repository.getOnboardingSteps();
  }
}