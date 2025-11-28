import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/role_entity.dart';
import '../../repositories/roles_repository.dart';

class GetAllRolesUseCase implements UseCase<List<RoleEntity>, NoParams> {
  final RolesRepository repository;

  GetAllRolesUseCase(this.repository);

  @override
  Future<Either<Failure, List<RoleEntity>>> call(NoParams params) async {
    return await repository.getAllRoles();
  }
}