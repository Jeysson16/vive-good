import 'package:dartz/dartz.dart';
import '../../repositories/onboarding_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class CompleteOnboarding implements UseCase<void, NoParams> {
  final OnboardingRepository repository;

  CompleteOnboarding(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.completeOnboarding();
  }
}