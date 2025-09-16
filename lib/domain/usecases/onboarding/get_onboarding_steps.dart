import 'package:dartz/dartz.dart';
import '../../entities/onboarding_step.dart';
import '../../repositories/onboarding_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class GetOnboardingSteps implements UseCase<List<OnboardingStep>, NoParams> {
  final OnboardingRepository repository;

  GetOnboardingSteps(this.repository);

  @override
  Future<Either<Failure, List<OnboardingStep>>> call([NoParams? params]) async {
    return await repository.getOnboardingSteps();
  }
}