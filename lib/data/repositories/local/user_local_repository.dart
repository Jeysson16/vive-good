import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/user.dart';
import '../../models/local/user_local_model.dart';
import '../../services/database_service.dart';

class UserLocalRepository {
  final DatabaseService _databaseService;

  UserLocalRepository({required DatabaseService databaseService})
      : _databaseService = databaseService;

  /// Obtiene el usuario actual
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'users',
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        return const Right(null);
      }

      final user = UserLocalModel.fromMap(maps.first).toEntity();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene un usuario por ID
  Future<Either<Failure, User?>> getUserById(String id) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return const Right(null);
      }

      final user = UserLocalModel.fromMap(maps.first).toEntity();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Guarda o actualiza un usuario
  Future<Either<Failure, void>> saveUser(User user) async {
    try {
      final userModel = UserLocalModel.fromEntity(user);
      
      await _databaseService.insertWithTimestamp('users', userModel.toMap());
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza un usuario existente
  Future<Either<Failure, void>> updateUser(User user) async {
    try {
      final userModel = UserLocalModel.fromEntity(user);
      
      await _databaseService.updateWithTimestamp(
        'users',
        userModel.toMap(),
        'id = ?',
        [user.id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Elimina un usuario
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene usuarios no sincronizados
  Future<Either<Failure, List<User>>> getUnsyncedUsers() async {
    try {
      final maps = await _databaseService.getUnsyncedRecords('users');
      
      final users = maps
          .map((map) => UserLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(users);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Marca un usuario como sincronizado
  Future<Either<Failure, void>> markUserAsSynced(String id) async {
    try {
      await _databaseService.markAsSynced('users', id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Guarda usuario desde el servidor
  Future<Either<Failure, void>> saveUserFromServer(User user) async {
    try {
      final userModel = UserLocalModel.fromEntity(user, isSynced: true);
      final db = await _databaseService.database;
      
      await db.insert(
        'users',
        userModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Limpia todos los usuarios
  Future<Either<Failure, void>> clearUsers() async {
    try {
      final db = await _databaseService.database;
      
      await db.delete('users');
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Verifica si existe un usuario
  Future<Either<Failure, bool>> userExists(String id) async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE id = ?',
        [id],
      );
      
      final count = result.first['count'] as int;
      return Right(count > 0);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene estadísticas del usuario
  Future<Either<Failure, Map<String, dynamic>>> getUserStats(String userId) async {
    try {
      final db = await _databaseService.database;
      
      // Total de hábitos
      final habitsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM habits WHERE user_id = ? AND is_active = 1',
        [userId],
      );
      
      // Total de progreso
      final progressResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM progress p 
        INNER JOIN habits h ON p.habit_id = h.id 
        WHERE h.user_id = ?
      ''', [userId]);
      
      // Progreso completado
      final completedResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM progress p 
        INNER JOIN habits h ON p.habit_id = h.id 
        WHERE h.user_id = ? AND p.completed = 1
      ''', [userId]);
      
      // Mensajes de chat
      final messagesResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE user_id = ?',
        [userId],
      );
      
      final stats = {
        'total_habits': habitsResult.first['count'] as int,
        'total_progress': progressResult.first['count'] as int,
        'completed_progress': completedResult.first['count'] as int,
        'total_messages': messagesResult.first['count'] as int,
        'completion_rate': 0.0,
      };
      
      if (stats['total_progress']! > 0) {
        stats['completion_rate'] = (stats['completed_progress']! / stats['total_progress']!) * 100;
      }
      
      return Right(stats);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene usuarios pendientes de sincronización (alias para getUnsyncedUsers)
  Future<Either<Failure, List<User>>> getPendingUser() async {
    return await getUnsyncedUsers();
  }
}