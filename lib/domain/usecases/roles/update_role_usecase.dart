import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/role_entity.dart';
import '../../repositories/roles_repository.dart';

class UpdateRoleUseCase implements UseCase<RoleEntity, UpdateRoleParams> {
  final RolesRepository repository;

  UpdateRoleUseCase(this.repository);

  @override
  Future<Either<Failure, RoleEntity>> call(UpdateRoleParams params) async {
    return await repository.updateRole(
      id: params.id,
      name: params.name,
      description: params.description,
    );
  }
}

class UpdateRoleParams extends Equatable {
  final String id;
  final String? name;
  final String? description;

  const UpdateRoleParams({
    required this.id,
    this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}