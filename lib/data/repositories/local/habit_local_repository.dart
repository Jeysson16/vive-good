import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/habit.dart';
import '../../models/local/habit_local_model.dart';
import '../../services/database_service.dart';

class HabitLocalRepository {
  final DatabaseService _databaseService;

  HabitLocalRepository({required DatabaseService databaseService})
      : _databaseService = databaseService;

  /// Obtiene todos los hábitos del usuario
  Future<Either<Failure, List<Habit>>> getHabits(String userId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'habits',
        where: 'user_id = ? AND is_active = ?',
        whereArgs: [userId, 1],
        orderBy: 'created_at DESC',
      );

      final habits = maps
          .map((map) => HabitLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(habits);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene un hábito por ID
  Future<Either<Failure, Habit?>> getHabitById(String id) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'habits',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return const Right(null);
      }

      final habit = HabitLocalModel.fromMap(maps.first).toEntity();
      return Right(habit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Agrega un nuevo hábito
  Future<Either<Failure, void>> addHabit(Habit habit) async {
    try {
      final habitModel = HabitLocalModel.fromEntity(habit);
      
      await _databaseService.insertWithTimestamp('habits', habitModel.toMap());
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza un hábito existente
  Future<Either<Failure, void>> updateHabit(Habit habit) async {
    try {
      final habitModel = HabitLocalModel.fromEntity(habit);
      
      await _databaseService.updateWithTimestamp(
        'habits',
        habitModel.toMap(),
        'id = ?',
        [habit.id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Elimina un hábito (soft delete)
  Future<Either<Failure, void>> deleteHabit(String id) async {
    try {
      await _databaseService.updateWithTimestamp(
        'habits',
        {'is_active': 0},
        'id = ?',
        [id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene hábitos no sincronizados
  Future<Either<Failure, List<Habit>>> getUnsyncedHabits() async {
    try {
      final maps = await _databaseService.getUnsyncedRecords('habits');
      
      final habits = maps
          .map((map) => HabitLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(habits);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Marca un hábito como sincronizado
  Future<Either<Failure, void>> markHabitAsSynced(String id) async {
    try {
      await _databaseService.markAsSynced('habits', id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Guarda hábitos desde el servidor (marca como sincronizados)
  Future<Either<Failure, void>> saveHabitsFromServer(List<Habit> habits) async {
    try {
      final db = await _databaseService.database;
      
      await db.transaction((txn) async {
        for (final habit in habits) {
          final habitModel = HabitLocalModel.fromEntity(habit, isSynced: true);
          
          await txn.insert(
            'habits',
            habitModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Limpia todos los hábitos del usuario
  Future<Either<Failure, void>> clearHabits(String userId) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'habits',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene estadísticas de hábitos
  Future<Either<Failure, Map<String, int>>> getHabitStats(String userId) async {
    try {
      final db = await _databaseService.database;
      
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM habits WHERE user_id = ? AND is_active = 1',
        [userId],
      );
      
      final unsyncedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM habits WHERE user_id = ? AND is_synced = 0',
        [userId],
      );
      
      final stats = {
        'total': totalResult.first['count'] as int,
        'unsynced': unsyncedResult.first['count'] as int,
      };
      
      return Right(stats);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene hábitos pendientes de sincronización (alias para getUnsyncedHabits)
  Future<Either<Failure, List<Habit>>> getPendingHabits() async {
    return await getUnsyncedHabits();
  }
}