import 'package:dartz/dartz.dart';
import '../../repositories/user_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class SetOnboardingCompleted implements UseCase<void, bool> {
  final UserRepository repository;

  SetOnboardingCompleted(this.repository);

  @override
  Future<Either<Failure, void>> call(bool params) async {
    return await repository.setOnboardingCompleted(params);
  }
}