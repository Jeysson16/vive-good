import 'package:dartz/dartz.dart';
import '../../repositories/user_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class IsFirstTimeUser implements UseCase<bool, NoParams> {
  final UserRepository repository;

  IsFirstTimeUser(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isFirstTimeUser();
  }
}