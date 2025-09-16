import 'package:dartz/dartz.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class SaveUser implements UseCase<void, User> {
  final UserRepository repository;

  SaveUser(this.repository);

  @override
  Future<Either<Failure, void>> call(User params) async {
    return await repository.saveUser(params);
  }
}