import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/role_entity.dart';

abstract class RolesRepository {
  /// Obtiene todos los roles
  Future<Either<Failure, List<RoleEntity>>> getAllRoles();
  
  /// Obtiene un rol por ID
  Future<Either<Failure, RoleEntity>> getRoleById(String id);
  
  /// Crea un nuevo rol
  Future<Either<Failure, RoleEntity>> createRole({
    required String name,
    String? description,
  });
  
  /// Actualiza un rol existente
  Future<Either<Failure, RoleEntity>> updateRole({
    required String id,
    String? name,
    String? description,
  });
  
  /// Elimina un rol
  Future<Either<Failure, void>> deleteRole(String id);
  
  /// Asigna un rol a un usuario
  Future<Either<Failure, void>> assignRoleToUser({
    required String userId,
    required String roleId,
  });
  
  /// Remueve un rol de un usuario
  Future<Either<Failure, void>> removeRoleFromUser({
    required String userId,
    required String roleId,
  });
  
  /// Obtiene los roles de un usuario
  Future<Either<Failure, List<RoleEntity>>> getUserRoles(String userId);
}