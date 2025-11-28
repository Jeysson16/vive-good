import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/role_entity.dart';
import '../../repositories/roles_repository.dart';

class CreateRoleUseCase implements UseCase<RoleEntity, CreateRoleParams> {
  final RolesRepository repository;

  CreateRoleUseCase(this.repository);

  @override
  Future<Either<Failure, RoleEntity>> call(CreateRoleParams params) async {
    return await repository.createRole(
      name: params.name,
      description: params.description,
    );
  }
}

class CreateRoleParams extends Equatable {
  final String name;
  final String? description;

  const CreateRoleParams({
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [name, description];
}