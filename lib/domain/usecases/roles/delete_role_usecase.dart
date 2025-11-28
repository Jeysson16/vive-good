import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/roles_repository.dart';

class DeleteRoleUseCase implements UseCase<void, DeleteRoleParams> {
  final RolesRepository repository;

  DeleteRoleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteRoleParams params) async {
    return await repository.deleteRole(params.id);
  }
}

class DeleteRoleParams extends Equatable {
  final String id;

  const DeleteRoleParams({required this.id});

  @override
  List<Object?> get props => [id];
}