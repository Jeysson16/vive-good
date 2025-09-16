import 'package:dartz/dartz.dart';
import '../../repositories/user_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class SetFirstTimeUser implements UseCase<void, bool> {
  final UserRepository repository;

  SetFirstTimeUser(this.repository);

  @override
  Future<Either<Failure, void>> call(bool params) async {
    return await repository.setFirstTimeUser(params);
  }
}