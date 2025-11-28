import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/roles_repository.dart';
import '../datasources/roles_remote_datasource.dart';

class RolesRepositoryImpl implements RolesRepository {
  final RolesRemoteDataSource remoteDataSource;

  RolesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<RoleEntity>>> getAllRoles() async {
    try {
      final roles = await remoteDataSource.getAllRoles();
      return Right(roles.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> getRoleById(String id) async {
    try {
      final role = await remoteDataSource.getRoleById(id);
      return Right(role.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> createRole({
    required String name,
    String? description,
  }) async {
    try {
      final role = await remoteDataSource.createRole(
        name: name,
        description: description,
      );
      return Right(role.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> updateRole({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final role = await remoteDataSource.updateRole(
        id: id,
        name: name,
        description: description,
      );
      return Right(role.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRole(String id) async {
    try {
      await remoteDataSource.deleteRole(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {
    try {
      await remoteDataSource.assignRoleToUser(
        userId: userId,
        roleId: roleId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {
    try {
      await remoteDataSource.removeRoleFromUser(
        userId: userId,
        roleId: roleId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<RoleEntity>>> getUserRoles(String userId) async {
    try {
      final roles = await remoteDataSource.getUserRoles(userId);
      return Right(roles.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
}