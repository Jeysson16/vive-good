import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/data/services/connectivity_service.dart';
import 'package:vive_good_app/data/repositories/local/habit_local_repository.dart';
import 'package:vive_good_app/data/repositories/local/progress_local_repository.dart';
import 'package:vive_good_app/data/repositories/local/user_local_repository.dart';
import 'package:vive_good_app/data/repositories/local/chat_local_repository.dart';
import 'package:vive_good_app/data/repositories/local/pending_operations_local_repository.dart';
import 'package:vive_good_app/data/datasources/habit_remote_datasource.dart';
import 'package:vive_good_app/data/datasources/progress_remote_datasource.dart';
import 'package:vive_good_app/data/datasources/user_remote_datasource.dart';
import 'package:vive_good_app/data/datasources/chat_remote_datasource.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/models/local/progress_local_model.dart';
import 'package:vive_good_app/data/models/user_model.dart';
import 'package:vive_good_app/data/models/chat/chat_message_model.dart';
import 'package:vive_good_app/domain/entities/pending_operation.dart';
import 'package:vive_good_app/domain/entities/chat/chat_message.dart';

/// Servicio de sincronización que maneja la sincronización automática
/// de datos locales con el servidor cuando hay conectividad
class SyncService {
  final ConnectivityService _connectivityService;
  final HabitLocalRepository _habitLocalRepository;
  final ProgressLocalRepository _progressLocalRepository;
  final UserLocalRepository _userLocalRepository;
  final ChatLocalRepository _chatLocalRepository;
  final PendingOperationsLocalRepository _pendingOperationsRepository;
  final HabitRemoteDataSource _habitRemoteDataSource;
  final ProgressRemoteDataSource _progressRemoteDataSource;
  final UserRemoteDataSource _userRemoteDataSource;
  final ChatRemoteDataSource _chatRemoteDataSource;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Stream controller para el conteo de operaciones pendientes
  final StreamController<int> _pendingOperationsCountController = 
      StreamController<int>.broadcast();
      
  // Stream controller para el estado de sincronización
  final StreamController<bool> _isSyncingController = 
      StreamController<bool>.broadcast();

  SyncService({
    required ConnectivityService connectivityService,
    required HabitLocalRepository habitLocalRepository,
    required ProgressLocalRepository progressLocalRepository,
    required UserLocalRepository userLocalRepository,
    required ChatLocalRepository chatLocalRepository,
    required PendingOperationsLocalRepository pendingOperationsRepository,
    required HabitRemoteDataSource habitRemoteDataSource,
    required ProgressRemoteDataSource progressRemoteDataSource,
    required UserRemoteDataSource userRemoteDataSource,
    required ChatRemoteDataSource chatRemoteDataSource,
  })  : _connectivityService = connectivityService,
        _habitLocalRepository = habitLocalRepository,
        _progressLocalRepository = progressLocalRepository,
        _userLocalRepository = userLocalRepository,
        _chatLocalRepository = chatLocalRepository,
        _pendingOperationsRepository = pendingOperationsRepository,
        _habitRemoteDataSource = habitRemoteDataSource,
        _progressRemoteDataSource = progressRemoteDataSource,
        _userRemoteDataSource = userRemoteDataSource,
        _chatRemoteDataSource = chatRemoteDataSource;

  /// Inicializa el servicio de sincronización
  void initialize() {
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (status) {
        if (status.isOnline && !_isSyncing) {
          _performSync();
        }
      },
    );
    
    // Actualizar el conteo inicial de operaciones pendientes
    _updatePendingOperationsCount();
  }

  /// Detiene el servicio de sincronización
  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingOperationsCountController.close();
    _isSyncingController.close();
  }

  /// Fuerza una sincronización manual
  Future<Either<Failure, void>> forcSync() async {
    if (_isSyncing) {
      return Left(CacheFailure('Sync already in progress'));
    }

    final connectivityStatus = await _connectivityService.currentStatus;
    if (!connectivityStatus.isOnline) {
      return Left(NetworkFailure('No internet connection'));
    }

    return _performSync();
  }

  /// Realiza la sincronización de todos los datos pendientes
  Future<Either<Failure, void>> _performSync() async {
    if (_isSyncing) {
      return const Right(null);
    }

    _isSyncing = true;
    _isSyncingController.add(true);

    try {
      // Sincronizar hábitos pendientes
      await _syncPendingHabits();

      // Sincronizar progreso pendiente
      await _syncPendingProgress();

      // Sincronizar usuario pendiente
      await _syncPendingUser();

      // Sincronizar mensajes de chat pendientes
      await _syncPendingChatMessages();

      // Actualizar el conteo de operaciones pendientes después de la sincronización
      await _updatePendingOperationsCount();

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Sync failed: ${e.toString()}'));
    } finally {
      _isSyncing = false;
      _isSyncingController.add(false);
    }
  }

  /// Sincroniza hábitos pendientes
  Future<void> _syncPendingHabits() async {
    try {
      final pendingHabitsResult = await _habitLocalRepository.getPendingHabits();
      
      await pendingHabitsResult.fold(
        (failure) async {
          // Log error but continue with other syncs
        },
        (pendingHabits) async {
          for (final habit in pendingHabits) {
            try {
              final habitModel = HabitModel.fromEntity(habit);
              await _habitRemoteDataSource.addHabit(habitModel);
              await _habitLocalRepository.markHabitAsSynced(habit.id);
            } catch (e) {
              // Log error for this specific habit but continue
              print('Failed to sync habit ${habit.id}: $e');
            }
          }
        },
      );
    } catch (e) {
      print('Failed to sync pending habits: $e');
    }
  }

  /// Sincroniza progreso pendiente
  Future<void> _syncPendingProgress() async {
    try {
      final pendingProgressResult = await _progressLocalRepository.getPendingProgress();
      
      await pendingProgressResult.fold(
        (failure) async {
          // Log error but continue with other syncs
        },
        (pendingProgress) async {
          for (final progress in pendingProgress) {
            try {
              // Para progreso de hábitos, usar logHabitCompletion del HabitRemoteDataSource
              if (progress.completed) {
                await _habitRemoteDataSource.logHabitCompletion(progress.habitId, progress.date);
              }
              await _progressLocalRepository.markProgressAsSynced(progress.userId);
            } catch (e) {
              // Log error for this specific progress but continue
              print('Failed to sync progress for user ${progress.userId}: $e');
            }
          }
        },
      );
    } catch (e) {
      print('Failed to sync pending progress: $e');
    }
  }

  /// Sincroniza usuario pendiente
  Future<void> _syncPendingUser() async {
    try {
      final pendingUsersResult = await _userLocalRepository.getPendingUser();
      
      await pendingUsersResult.fold(
        (failure) async {
          // Log error but continue with other syncs
        },
        (pendingUsers) async {
          for (final user in pendingUsers) {
            try {
              final userModel = UserModel.fromEntity(user);
              await _userRemoteDataSource.saveUser(userModel);
              await _userLocalRepository.markUserAsSynced(user.id);
            } catch (e) {
              // Log error for this specific user but continue
              print('Failed to sync user ${user.id}: $e');
            }
          }
        },
      );
    } catch (e) {
      print('Failed to sync pending user: $e');
    }
  }

  /// Sincroniza mensajes de chat pendientes
  Future<void> _syncPendingChatMessages() async {
    try {
      final pendingMessagesResult = await _chatLocalRepository.getPendingMessages();
      
      await pendingMessagesResult.fold(
        (failure) async {
          // Log error but continue with other syncs
        },
        (pendingMessages) async {
          for (final message in pendingMessages) {
            try {
              // Para mensajes de chat, necesitamos enviar el mensaje original
              if (message.type == MessageType.user) {
                // Obtener la sesión para conseguir el userId
                final sessionResult = await _chatLocalRepository.getSession(message.sessionId);
                await sessionResult.fold(
                  (failure) async {
                    // Si no se puede obtener la sesión, marcar como fallido
                    print('Failed to get session for message ${message.id}: $failure');
                  },
                  (session) async {
                     final response = await _chatRemoteDataSource.sendMessage(
                       message.sessionId,
                       message.content,
                       message.type,
                     );
                    
                    // Guardar la respuesta del servidor
                     await _chatLocalRepository.saveMessageFromServer(response);
                  },
                );
              }
              
              await _chatLocalRepository.markMessageAsSynced(message.id);
            } catch (e) {
              // Log error for this specific message but continue
              print('Failed to sync message ${message.id}: $e');
            }
          }
        },
      );
    } catch (e) {
      print('Failed to sync pending chat messages: $e');
    }
  }

  /// Verifica si hay datos pendientes de sincronización
  Future<bool> hasPendingData() async {
    try {
      final habitsPending = await _habitLocalRepository.getPendingHabits();
      final progressPending = await _progressLocalRepository.getPendingProgress();
      final userPending = await _userLocalRepository.getPendingUser();
      final messagesPending = await _chatLocalRepository.getPendingMessages();

      return habitsPending.fold(
        (failure) => false,
        (habits) => habits.isNotEmpty,
      ) ||
      progressPending.fold(
        (failure) => false,
        (progress) => progress.isNotEmpty,
      ) ||
      userPending.fold(
        (failure) => false,
        (user) => user != null,
      ) ||
      messagesPending.fold(
        (failure) => false,
        (messages) => messages.isNotEmpty,
      );
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el estado actual de sincronización
  bool get isSyncing => _isSyncing;
  
  /// Stream del conteo de operaciones pendientes
  Stream<int> get pendingOperationsCountStream => _pendingOperationsCountController.stream;
  
  /// Stream del estado de sincronización
  Stream<bool> get isSyncingStream => _isSyncingController.stream;
  
  /// Stream de operaciones pendientes (alias para compatibilidad)
  Stream<List<PendingOperation>> get pendingOperationsStream async* {
    final operationsResult = await getPendingOperations();
    yield operationsResult.fold(
      (failure) => <PendingOperation>[],
      (operations) => operations,
    );
  }
  
  /// Limpia todas las operaciones pendientes
  Future<Either<Failure, void>> clearPendingOperations() async {
    try {
      final result = await _pendingOperationsRepository.clearAllPendingOperations();
      await _updatePendingOperationsCount();
      return result;
    } catch (e) {
      return Left(SyncFailure('Failed to clear pending operations: ${e.toString()}'));
    }
  }
  
  /// Obtiene todas las operaciones pendientes
  Future<Either<Failure, List<PendingOperation>>> getPendingOperations() async {
    return await _pendingOperationsRepository.getAllPendingOperations();
  }
  
  /// Obtiene el conteo de operaciones pendientes
  Future<Either<Failure, int>> getPendingOperationsCount() async {
    return await _pendingOperationsRepository.getPendingOperationsCount();
  }
  
  /// Sincroniza las operaciones pendientes manualmente
  Future<Either<Failure, void>> syncPendingOperations() async {
    return await _performSync();
  }
  
  /// Actualiza el conteo de operaciones pendientes en el stream
  Future<void> _updatePendingOperationsCount() async {
    final countResult = await _pendingOperationsRepository.getPendingOperationsCount();
    countResult.fold(
      (failure) => _pendingOperationsCountController.add(0),
      (count) => _pendingOperationsCountController.add(count),
    );
  }
}

/// Failure específico para errores de sincronización
class SyncFailure extends Failure {
  const SyncFailure(String message) : super(message);

  @override
  List<Object> get props => [message];
}

/// Failure específico para errores de red
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);

  @override
  List<Object> get props => [message];
}