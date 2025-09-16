import 'package:dartz/dartz.dart';
import '../../repositories/onboarding_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class SetCurrentStepIndex implements UseCase<void, int> {
  final OnboardingRepository repository;

  SetCurrentStepIndex(this.repository);

  @override
  Future<Either<Failure, void>> call(int params) async {
    return await repository.setCurrentStepIndex(params);
  }
}