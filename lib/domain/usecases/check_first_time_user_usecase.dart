import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

class CheckFirstTimeUserUseCase implements UseCase<bool, NoParams> {
  final UserRepository repository;

  CheckFirstTimeUserUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isFirstTimeUser();
  }
}