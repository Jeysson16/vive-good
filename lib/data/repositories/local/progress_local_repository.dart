import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/habit_progress.dart';
import '../../models/local/progress_local_model.dart';
import '../../services/database_service.dart';

class ProgressLocalRepository {
  final DatabaseService _databaseService;

  ProgressLocalRepository({required DatabaseService databaseService})
      : _databaseService = databaseService;

  /// Obtiene el progreso de un hábito específico
  Future<Either<Failure, List<HabitProgress>>> getProgressByHabit(String habitId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'progress',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        orderBy: 'date DESC',
      );

      final progressList = maps
          .map((map) => ProgressLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(progressList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el progreso de hoy para todos los hábitos
  Future<Either<Failure, List<HabitProgress>>> getTodayProgress() async {
    try {
      final db = await _databaseService.database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final maps = await db.query(
        'progress',
        where: 'date = ?',
        whereArgs: [today],
        orderBy: 'created_at DESC',
      );

      final progressList = maps
          .map((map) => ProgressLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(progressList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el progreso por fecha específica
  Future<Either<Failure, List<HabitProgress>>> getProgressByDate(DateTime date) async {
    try {
      final db = await _databaseService.database;
      final dateStr = date.toIso8601String().split('T')[0];
      
      final maps = await db.query(
        'progress',
        where: 'date = ?',
        whereArgs: [dateStr],
        orderBy: 'created_at DESC',
      );

      final progressList = maps
          .map((map) => ProgressLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(progressList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el progreso en un rango de fechas
  Future<Either<Failure, List<HabitProgress>>> getProgressByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _databaseService.database;
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      final maps = await db.query(
        'progress',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'date DESC, created_at DESC',
      );

      final progressList = maps
          .map((map) => ProgressLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(progressList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el progreso por usuario
  Future<Either<Failure, List<HabitProgress>>> getProgressByUser(String userId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'progress',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
      );

      final progressList = maps
          .map((map) => ProgressLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(progressList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Marca progreso para un hábito en una fecha específica
  Future<Either<Failure, void>> markProgress(HabitProgress progress) async {
    try {
      final progressModel = ProgressLocalModel.fromEntity(progress);
      
      await _databaseService.insertWithTimestamp('progress', progressModel.toMap());
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza el progreso existente
  Future<Either<Failure, void>> updateProgress(HabitProgress progress) async {
    try {
      final progressModel = ProgressLocalModel.fromEntity(progress);
      
      await _databaseService.updateWithTimestamp(
        'progress',
        progressModel.toMap(),
        'user_id = ?',
        [progress.userId],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Elimina el progreso
  Future<Either<Failure, void>> deleteProgress(String id) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'progress',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el progreso no sincronizado
  Future<Either<Failure, List<HabitProgress>>> getUnsyncedProgress() async {
    try {
      final maps = await _databaseService.getUnsyncedRecords('progress');
      
      final progressList = maps
          .map((map) => ProgressLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(progressList);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Marca progreso como sincronizado
  Future<Either<Failure, void>> markProgressAsSynced(String id) async {
    try {
      await _databaseService.markAsSynced('progress', id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Guarda el progreso desde el servidor
  Future<Either<Failure, void>> saveProgressFromServer(List<HabitProgress> progressList) async {
    try {
      final db = await _databaseService.database;
      
      await db.transaction((txn) async {
        for (final progress in progressList) {
          final progressModel = ProgressLocalModel.fromEntity(progress, isSynced: true);
          
          await txn.insert(
            'progress',
            progressModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene estadísticas de progreso
  Future<Either<Failure, Map<String, dynamic>>> getProgressStats(String habitId) async {
    try {
      final db = await _databaseService.database;
      
      // Total de días con progreso
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM progress WHERE habit_id = ?',
        [habitId],
      );
      
      // Días completados
      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM progress WHERE habit_id = ? AND completed = 1',
        [habitId],
      );
      
      // Racha actual
      final streakResult = await db.rawQuery('''
        SELECT COUNT(*) as streak FROM (
          SELECT date FROM progress 
          WHERE habit_id = ? AND completed = 1 
          ORDER BY date DESC
        ) WHERE date >= date('now', '-' || (
          SELECT COUNT(*) FROM progress p2 
          WHERE p2.habit_id = ? AND p2.completed = 1 AND p2.date >= date('now', '-30 days')
        ) || ' days')
      ''', [habitId, habitId]);
      
      final stats = {
        'total_days': totalResult.first['count'] as int,
        'completed_days': completedResult.first['count'] as int,
        'current_streak': streakResult.first['streak'] as int,
        'completion_rate': 0.0,
      };
      
      if (stats['total_days']! > 0) {
        stats['completion_rate'] = (stats['completed_days']! / stats['total_days']!) * 100;
      }
      
      return Right(stats);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Limpia todo el progreso de un hábito
  Future<Either<Failure, void>> clearProgressByHabit(String habitId) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'progress',
        where: 'habit_id = ?',
        whereArgs: [habitId],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el progreso pendiente de sincronización (alias para getUnsyncedProgress)
  Future<Either<Failure, List<HabitProgress>>> getPendingProgress() async {
    return await getUnsyncedProgress();
  }
}