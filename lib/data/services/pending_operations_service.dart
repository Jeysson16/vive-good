import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/pending_operation.dart';
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/entities/progress.dart';
import 'package:vive_good_app/domain/entities/user.dart';
import 'package:vive_good_app/domain/entities/chat/chat_message.dart';
import 'package:vive_good_app/data/repositories/local/pending_operations_local_repository.dart';
import 'package:vive_good_app/data/services/connectivity_service.dart';

/// Servicio para manejar la cola de operaciones pendientes
class PendingOperationsService {
  final PendingOperationsLocalRepository _repository;
  final ConnectivityService _connectivityService;

  PendingOperationsService({
    required PendingOperationsLocalRepository repository,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _connectivityService = connectivityService;

  /// Agrega una operación de creación de hábito a la cola
  Future<Either<Failure, void>> addCreateHabitOperation(Habit habit) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.createHabit,
      entityId: habit.id,
      data: {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'categoryId': habit.categoryId,
        'iconName': habit.iconName,
        'iconColor': habit.iconColor,
        'isPublic': habit.isPublic,
        'createdBy': habit.createdBy,
        'userId': habit.userId,
        'createdAt': habit.createdAt.toIso8601String(),
        'updatedAt': habit.updatedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Agrega una operación de actualización de hábito a la cola
  Future<Either<Failure, void>> addUpdateHabitOperation(Habit habit) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.updateHabit,
      entityId: habit.id,
      data: {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'categoryId': habit.categoryId,
        'iconName': habit.iconName,
        'iconColor': habit.iconColor,
        'isPublic': habit.isPublic,
        'createdBy': habit.createdBy,
        'userId': habit.userId,
        'createdAt': habit.createdAt.toIso8601String(),
        'updatedAt': habit.updatedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Agrega una operación de eliminación de hábito a la cola
  Future<Either<Failure, void>> addDeleteHabitOperation(String habitId) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.deleteHabit,
      entityId: habitId,
      data: {'habitId': habitId},
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Agrega una operación de actualización de progreso a la cola
  Future<Either<Failure, void>> addUpdateProgressOperation(Progress progress) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.updateProgress,
      entityId: progress.userId,
      data: {
        'userId': progress.userId,
        'userName': progress.userName,
        'userProfileImage': progress.userProfileImage,
        'weeklyCompletedHabits': progress.weeklyCompletedHabits,
        'suggestedHabits': progress.suggestedHabits,
        'pendingActivities': progress.pendingActivities,
        'newHabits': progress.newHabits,
        'weeklyProgressPercentage': progress.weeklyProgressPercentage,
        'acceptedNutritionSuggestions': progress.acceptedNutritionSuggestions,
        'motivationalMessage': progress.motivationalMessage,
        'lastUpdated': progress.lastUpdated.toIso8601String(),
        'dailyProgress': progress.dailyProgress,
      },
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Agrega una operación de actualización de usuario a la cola
  Future<Either<Failure, void>> addUpdateUserOperation(User user) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.updateUser,
      entityId: user.id,
      data: {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': user.updatedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Agrega una operación de envío de mensaje a la cola
  Future<Either<Failure, void>> addSendMessageOperation(ChatMessage message) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.sendMessage,
      entityId: message.id,
      data: {
        'id': message.id,
        'sessionId': message.sessionId,
        'content': message.content,
        'type': message.type.name,
        'status': message.status.name,
        'createdAt': message.createdAt.toIso8601String(),
        'updatedAt': message.updatedAt?.toIso8601String(),
        'metadata': message.metadata,
        'parentMessageId': message.parentMessageId,
        'isEdited': message.isEdited,
      },
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Agrega una operación de limpieza de historial de chat a la cola
  Future<Either<Failure, void>> addClearChatHistoryOperation(String userId) async {
    final operation = PendingOperation(
      id: _generateOperationId(),
      type: PendingOperationType.clearChatHistory,
      entityId: userId,
      data: {'userId': userId},
      createdAt: DateTime.now(),
    );

    return await _repository.addPendingOperation(operation);
  }

  /// Obtiene todas las operaciones pendientes
  Future<Either<Failure, List<PendingOperation>>> getAllPendingOperations() async {
    return await _repository.getAllPendingOperations();
  }

  /// Obtiene operaciones pendientes por tipo
  Future<Either<Failure, List<PendingOperation>>> getPendingOperationsByType(
    PendingOperationType type,
  ) async {
    return await _repository.getPendingOperationsByType(type);
  }

  /// Marca una operación como completada y la elimina de la cola
  Future<Either<Failure, void>> markOperationAsCompleted(String operationId) async {
    return await _repository.removePendingOperation(operationId);
  }

  /// Marca una operación como fallida e incrementa el contador de reintentos
  Future<Either<Failure, void>> markOperationAsFailed(
    String operationId,
    String error,
  ) async {
    final operationResult = await _repository.getPendingOperationById(operationId);
    
    return operationResult.fold(
      (failure) => Left(failure),
      (operation) async {
        if (operation == null) {
          return Left(CacheFailure('Operation not found'));
        }

        final updatedOperation = operation.incrementRetry(error);
        
        // Si ha excedido el máximo de reintentos, eliminar la operación
        if (updatedOperation.hasExceededMaxRetries) {
          return await _repository.removePendingOperation(operationId);
        }

        // Actualizar la operación con el nuevo contador de reintentos
        return await _repository.updatePendingOperation(updatedOperation);
      },
    );
  }

  /// Elimina operaciones pendientes por ID de entidad
  Future<Either<Failure, void>> removeOperationsByEntityId(String entityId) async {
    return await _repository.removePendingOperationsByEntityId(entityId);
  }

  /// Limpia operaciones pendientes antiguas
  Future<Either<Failure, void>> cleanupOldOperations() async {
    return await _repository.clearOldPendingOperations();
  }

  /// Obtiene el conteo de operaciones pendientes
  Future<Either<Failure, int>> getPendingOperationsCount() async {
    return await _repository.getPendingOperationsCount();
  }

  /// Verifica si hay operaciones pendientes
  Future<Either<Failure, bool>> hasPendingOperations() async {
    return await _repository.hasPendingOperations();
  }

  /// Obtiene operaciones pendientes que están listas para reintento
  Future<Either<Failure, List<PendingOperation>>> getOperationsReadyForRetry() async {
    final allOperationsResult = await _repository.getAllPendingOperations();
    
    return allOperationsResult.fold(
      (failure) => Left(failure),
      (operations) {
        final readyOperations = operations.where((operation) {
          // Solo incluir operaciones que no han excedido el máximo de reintentos
          // y que son recientes (menos de 24 horas)
          return !operation.hasExceededMaxRetries && operation.isRecent;
        }).toList();
        
        return Right(readyOperations);
      },
    );
  }

  /// Genera un ID único para una operación
  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Programa la limpieza automática de operaciones antiguas
  void schedulePeriodicCleanup() {
    Timer.periodic(const Duration(hours: 6), (timer) {
      cleanupOldOperations();
    });
  }
}