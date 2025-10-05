import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/core/errors/exceptions.dart' as custom_exceptions;
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/entities/category.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import 'package:vive_good_app/domain/entities/habit_breakdown.dart';
import 'package:vive_good_app/domain/repositories/habit_repository.dart';
import 'package:vive_good_app/data/datasources/habit_remote_datasource.dart';
import 'package:vive_good_app/data/datasources/habit_local_datasource.dart';
import 'package:vive_good_app/data/services/connectivity_service.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/repositories/local/habit_local_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource remoteDataSource;
  final HabitLocalDataSource localDataSource;
  final HabitLocalRepository habitLocalRepository;
  final ConnectivityService connectivityService;

  HabitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.habitLocalRepository,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, List<UserHabit>>> getUserHabits(String userId) async {
    try {
      // Siempre intentar obtener datos locales primero usando el nuevo repositorio
      final localHabitsResult = await habitLocalRepository.getHabits(userId);
      
      // Verificar conectividad
      final connectivityStatus = await connectivityService.getCurrentConnectivityStatus();
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar obtener datos remotos
          final remoteHabits = await remoteDataSource.getUserHabits(userId);
          
          // Guardar datos remotos en local para sincronización
          final userHabits = remoteHabits.map((model) => model.toEntity()).toList();
          final habitsToSave = userHabits
              .map((userHabit) => userHabit.habit)
              .where((habit) => habit != null)
              .cast<Habit>()
              .toList();
          await habitLocalRepository.saveHabitsFromServer(habitsToSave);
          
          // Retornar datos remotos actualizados
          return Right(userHabits);
        } on custom_exceptions.ServerException {
          // Si falla el remoto pero hay datos locales, usar locales
          return localHabitsResult.fold(
            (failure) => Left(ServerFailure('Failed to get user habits')),
            (localHabits) {
              if (localHabits.isNotEmpty) {
                // Convertir Habit a UserHabit para mantener compatibilidad
                final userHabits = localHabits.map((habit) => UserHabit(
                  id: habit.id,
                  userId: userId,
                  habitId: habit.id,
                  frequency: 'daily', // Valor por defecto
                  notificationsEnabled: true,
                  startDate: habit.createdAt,
                  isActive: true,
                  createdAt: habit.createdAt,
                  updatedAt: habit.updatedAt,
                  habit: habit, // Incluir el hábito completo
                )).toList();
                return Right(userHabits);
              }
              return Left(ServerFailure('Failed to get user habits'));
            },
          );
        }
      } else {
        // Sin conexión, usar datos locales
        return localHabitsResult.fold(
          (failure) => Left(failure),
          (localHabits) {
            // Convertir Habit a UserHabit para mantener compatibilidad
            final userHabits = localHabits.map((habit) => UserHabit(
              id: habit.id,
              userId: userId,
              habitId: habit.id,
              frequency: 'daily', // Valor por defecto
              notificationsEnabled: true,
              startDate: habit.createdAt,
              isActive: true,
              createdAt: habit.createdAt,
              updatedAt: habit.updatedAt,
              habit: habit, // Incluir el hábito completo
            )).toList();
            return Right(userHabits);
          },
        );
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get user habits: $e'));
    }
  }

  @override
  Future<Either<Failure, UserHabit>> getUserHabitById(String userHabitId) async {
    try {
      // Intentar obtener datos locales primero
      final localHabit = await localDataSource.getUserHabitById(userHabitId);
      
      // Verificar conectividad
      final connectivityStatus = await connectivityService.getCurrentConnectivityStatus();
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar obtener datos remotos
          final remoteHabit = await remoteDataSource.getUserHabitById(userHabitId);
          return Right(remoteHabit.toEntity());
        } on custom_exceptions.ServerException {
          // Si falla el remoto pero hay datos locales, usar locales
          if (localHabit != null) {
            return Right(localHabit.toEntity());
          }
          return Left(ServerFailure('Failed to get user habit'));
        }
      } else {
        // Sin conexión, usar datos locales
        if (localHabit != null) {
          return Right(localHabit.toEntity());
        }
        return Left(CacheFailure('Habit not found locally'));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get user habit: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getHabitCategories() async {
    try {
      // Intentar obtener categorías locales primero
      final localCategories = await localDataSource.getHabitCategories();
      
      // Verificar conectividad
      final connectivityStatus = await connectivityService.getCurrentConnectivityStatus();
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar obtener datos remotos
          final remoteCategories = await remoteDataSource.getHabitCategories();
          return Right(remoteCategories.map((model) => model.toEntity()).toList());
        } on custom_exceptions.ServerException {
          // Si falla el remoto pero hay categorías locales, usar locales
          if (localCategories.isNotEmpty) {
            return Right(localCategories.map((model) => model.toEntity()).toList());
          }
          return Left(ServerFailure('Failed to get habit categories'));
        }
      } else {
        // Sin conexión, usar categorías locales
        return Right(localCategories.map((model) => model.toEntity()).toList());
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get habit categories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Habit>>> getHabitSuggestions({
    String? userId,
    String? categoryId,
    int? limit,
  }) async {
    try {
      final habits = await remoteDataSource.getHabitSuggestions(
        userId: userId,
        categoryId: categoryId,
        limit: limit,
      );
      return Right(habits.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get habit suggestions'));
    }
  }

  @override
  Future<Either<Failure, void>> logHabitCompletion(String habitId, DateTime date) async {
    try {
      // Obtener userId del contexto (esto debería venir como parámetro en una implementación real)
      final userId = 'current_user_id'; // TODO: Obtener del contexto de autenticación
      
      // Siempre guardar localmente primero
      await localDataSource.logHabitCompletion(habitId, date, userId);
      
      // Verificar conectividad
      final connectivityStatus = await connectivityService.getCurrentConnectivityStatus();
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar sincronizar con remoto
          await remoteDataSource.logHabitCompletion(habitId, date);
        } on custom_exceptions.ServerException {
          // Si falla el remoto, los datos ya están guardados localmente
          // La sincronización se hará automáticamente cuando se restablezca la conexión
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to log habit completion: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addHabit(Habit habit) async {
    try {
      // Siempre guardar localmente primero usando el nuevo repositorio
      final localResult = await habitLocalRepository.addHabit(habit);
      
      return localResult.fold(
        (failure) => Left(failure),
        (_) async {
          // Verificar conectividad
          final connectivityStatus = await connectivityService.getCurrentConnectivityStatus();
          
          if (connectivityStatus.isOnline) {
            try {
              // Si hay conexión, intentar sincronizar con remoto
              final habitModel = HabitModel.fromEntity(habit);
              await remoteDataSource.addHabit(habitModel);
              
              // Marcar como sincronizado
              await habitLocalRepository.markHabitAsSynced(habit.id);
            } on custom_exceptions.ServerException {
              // Si falla el remoto, los datos ya están guardados localmente
              // La sincronización se hará automáticamente cuando se restablezca la conexión
            }
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to add habit: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabit(String habitId) async {
    try {
      await remoteDataSource.deleteHabit(habitId);
      return const Right(null);
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to delete habit'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserHabit(String userHabitId, Map<String, dynamic> updates) async {
    try {
      await remoteDataSource.updateUserHabit(userHabitId, updates);
      return const Right(null);
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to update user habit'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserHabit(String userHabitId) async {
    try {
      await remoteDataSource.deleteUserHabit(userHabitId);
      return const Right(null);
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to delete user habit'));
    }
  }

  @override
  Future<Either<Failure, List<UserHabit>>> getDashboardHabits(String userId, int limit, bool includeCompletionStatus) async {
    try {
      print('📊 [DEBUG] HabitRepository - Getting dashboard habits for user: $userId');
      print('   - Timestamp: ${DateTime.now()}');
      
      // Verificar conectividad primero
      final connectivityStatus = await connectivityService.getCurrentConnectivityStatus();
      print('   - Connectivity check completed');
      print('   - Network type: ${connectivityStatus.type}');
      print('   - Connectivity status: ${connectivityStatus.isOnline ? "ONLINE" : "OFFLINE"}');
      print('   - Last checked: ${connectivityStatus.lastChecked}');
      
      if (connectivityStatus.isOnline) {
        try {
          print('   - Attempting to fetch remote data first (online mode)...');
          // PRIORIDAD 1: Datos remotos cuando hay conexión
          final remoteDashboardHabits = await remoteDataSource.getDashboardHabits(userId, limit, includeCompletionStatus);
          print('   - Remote habits fetched successfully: ${remoteDashboardHabits.length}');
          
          // Guardar datos remotos en cache local para futuras consultas offline
          try {
            // Convertir UserHabitModel a HabitModel para guardar en cache local
            for (final userHabitModel in remoteDashboardHabits) {
              if (userHabitModel.habit != null) {
                await localDataSource.addHabit(userHabitModel.habit!);
              }
            }
            print('   - Remote data cached locally for offline use');
          } catch (cacheError) {
            print('   - Warning: Failed to cache remote data locally: $cacheError');
            // No fallar si no se puede cachear, los datos remotos siguen siendo válidos
          }
          
          return Right(remoteDashboardHabits.map((model) => model.toEntity()).toList());
        } on custom_exceptions.ServerException catch (e) {
          print('   - Remote fetch failed: $e');
          print('   - Falling back to local cache...');
          
          // FALLBACK: Si falla remoto, usar datos locales como respaldo
          final localHabits = await localDataSource.getDashboardHabits(userId, limit);
          print('   - Local habits found: ${localHabits.length}');
          
          if (localHabits.isNotEmpty) {
            print('   - Using local cache as fallback');
            // Convertir HabitModel a UserHabit para mantener compatibilidad
            final userHabits = localHabits.map((habit) => UserHabit(
              id: habit.id,
              userId: userId,
              habitId: habit.id,
              frequency: 'daily', // Valor por defecto
              notificationsEnabled: true,
              startDate: habit.createdAt,
              isActive: true,
              createdAt: habit.createdAt,
              updatedAt: habit.updatedAt,
              habit: habit, // Incluir el hábito completo
            )).toList();
            return Right(userHabits);
          }
          
          print('   - No local cache available, returning server error');
          return Left(ServerFailure('Failed to get dashboard habits from server and no local cache available'));
        }
      } else {
        print('   - Offline mode: using local cache only...');
        // MODO OFFLINE: Solo usar datos locales
        final localHabits = await localDataSource.getDashboardHabits(userId, limit);
        print('   - Local habits found: ${localHabits.length}');
        
        if (localHabits.isNotEmpty) {
          print('   - Returning local cache data');
          // Convertir HabitModel a UserHabit para mantener compatibilidad
          final userHabits = localHabits.map((habit) => UserHabit(
            id: habit.id,
            userId: userId,
            habitId: habit.id,
            frequency: 'daily', // Valor por defecto
            notificationsEnabled: true,
            startDate: habit.createdAt,
            isActive: true,
            createdAt: habit.createdAt,
            updatedAt: habit.updatedAt,
            habit: habit, // Incluir el hábito completo
          )).toList();
          return Right(userHabits);
        }
        
        print('   - No local cache found for offline mode');
        return Left(CacheFailure('No dashboard habits found in local cache. Connect to internet to sync data.'));
      }
    } catch (e) {
      print('   - Unexpected error: $e');
      return Left(ServerFailure('Failed to get dashboard habits: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HabitBreakdown>>> getMonthlyHabitsBreakdown(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final remoteBreakdown = await remoteDataSource.getMonthlyHabitsBreakdown(userId, year, month);
      return Right(remoteBreakdown.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get monthly habits breakdown'));
    }
  }
}
