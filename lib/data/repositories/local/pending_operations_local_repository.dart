import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/pending_operation.dart';
import 'package:vive_good_app/data/models/pending_operation_model.dart';
import 'package:vive_good_app/data/datasources/local/database_helper.dart';

/// Repositorio local para manejar operaciones pendientes de sincronización
class PendingOperationsLocalRepository {
  final DatabaseHelper _databaseHelper;

  PendingOperationsLocalRepository({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  /// Agrega una nueva operación pendiente
  Future<Either<Failure, void>> addPendingOperation(PendingOperation operation) async {
    try {
      final model = PendingOperationModel.fromEntity(operation);
      await _databaseHelper.insertPendingOperation(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add pending operation: ${e.toString()}'));
    }
  }

  /// Obtiene todas las operaciones pendientes
  Future<Either<Failure, List<PendingOperation>>> getAllPendingOperations() async {
    try {
      final operations = await _databaseHelper.getAllPendingOperations();
      final entities = operations
          .map((json) => PendingOperationModel.fromJson(json).toEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending operations: ${e.toString()}'));
    }
  }

  /// Obtiene operaciones pendientes por tipo
  Future<Either<Failure, List<PendingOperation>>> getPendingOperationsByType(
    PendingOperationType type,
  ) async {
    try {
      final operations = await _databaseHelper.getPendingOperationsByType(
        type.toString().split('.').last,
      );
      final entities = operations
          .map((json) => PendingOperationModel.fromJson(json).toEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending operations by type: ${e.toString()}'));
    }
  }

  /// Obtiene una operación pendiente por ID
  Future<Either<Failure, PendingOperation?>> getPendingOperationById(String id) async {
    try {
      final operation = await _databaseHelper.getPendingOperationById(id);
      if (operation != null) {
        final entity = PendingOperationModel.fromJson(operation).toEntity();
        return Right(entity);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending operation: ${e.toString()}'));
    }
  }

  /// Actualiza una operación pendiente
  Future<Either<Failure, void>> updatePendingOperation(PendingOperation operation) async {
    try {
      final model = PendingOperationModel.fromEntity(operation);
      await _databaseHelper.updatePendingOperation(operation.id, model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update pending operation: ${e.toString()}'));
    }
  }

  /// Elimina una operación pendiente
  Future<Either<Failure, void>> removePendingOperation(String id) async {
    try {
      await _databaseHelper.deletePendingOperation(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove pending operation: ${e.toString()}'));
    }
  }

  /// Elimina operaciones pendientes por tipo
  Future<Either<Failure, void>> removePendingOperationsByType(
    PendingOperationType type,
  ) async {
    try {
      await _databaseHelper.deletePendingOperationsByType(
        type.toString().split('.').last,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove pending operations by type: ${e.toString()}'));
    }
  }

  /// Elimina operaciones pendientes por ID de entidad
  Future<Either<Failure, void>> removePendingOperationsByEntityId(String entityId) async {
    try {
      await _databaseHelper.deletePendingOperationsByEntityId(entityId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove pending operations by entity ID: ${e.toString()}'));
    }
  }

  /// Limpia todas las operaciones pendientes
  Future<Either<Failure, void>> clearAllPendingOperations() async {
    try {
      await _databaseHelper.clearPendingOperations();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear pending operations: ${e.toString()}'));
    }
  }

  /// Limpia operaciones pendientes antiguas (más de 24 horas)
  Future<Either<Failure, void>> clearOldPendingOperations() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));
      await _databaseHelper.deletePendingOperationsOlderThan(cutoffDate);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear old pending operations: ${e.toString()}'));
    }
  }

  /// Obtiene el conteo de operaciones pendientes
  Future<Either<Failure, int>> getPendingOperationsCount() async {
    try {
      final count = await _databaseHelper.getPendingOperationsCount();
      return Right(count);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending operations count: ${e.toString()}'));
    }
  }

  /// Obtiene el conteo de operaciones pendientes por tipo
  Future<Either<Failure, int>> getPendingOperationsCountByType(
    PendingOperationType type,
  ) async {
    try {
      final count = await _databaseHelper.getPendingOperationsCountByType(
        type.toString().split('.').last,
      );
      return Right(count);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending operations count by type: ${e.toString()}'));
    }
  }

  /// Verifica si hay operaciones pendientes
  Future<Either<Failure, bool>> hasPendingOperations() async {
    try {
      final count = await _databaseHelper.getPendingOperationsCount();
      return Right(count > 0);
    } catch (e) {
      return Left(CacheFailure('Failed to check pending operations: ${e.toString()}'));
    }
  }
}