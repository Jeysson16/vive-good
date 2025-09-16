import 'package:dartz/dartz.dart';
import '../../repositories/onboarding_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class GetCurrentStepIndex implements UseCase<int, NoParams> {
  final OnboardingRepository repository;

  GetCurrentStepIndex(this.repository);

  @override
  Future<Either<Failure, int>> call([NoParams? params]) async {
    return await repository.getCurrentStepIndex();
  }
}