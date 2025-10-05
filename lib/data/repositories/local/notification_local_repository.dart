import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/habit_notification.dart';
import '../../../domain/entities/notification_schedule.dart';
import '../../../domain/entities/notification_log.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../models/local/habit_notification_local_model.dart';
import '../../models/local/notification_schedule_local_model.dart';
import '../../models/local/notification_log_local_model.dart';
import '../../models/local/notification_settings_local_model.dart';
import '../../services/database_service.dart';

class NotificationLocalRepository {
  final DatabaseService _databaseService;

  NotificationLocalRepository({required DatabaseService databaseService})
      : _databaseService = databaseService;

  // ===== HABIT NOTIFICATIONS =====

  /// Crea una nueva notificación de hábito
  Future<Either<Failure, HabitNotification>> createHabitNotification(
      HabitNotification notification) async {
    try {
      final notificationModel = HabitNotificationLocalModel.fromEntity(notification);
      
      await _databaseService.insertWithTimestamp(
        'habit_notifications', 
        notificationModel.toMap()
      );
      
      return Right(notification);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza una notificación de hábito
  Future<Either<Failure, HabitNotification>> updateHabitNotification(
      HabitNotification notification) async {
    try {
      final notificationModel = HabitNotificationLocalModel.fromEntity(notification);
      
      await _databaseService.updateWithTimestamp(
        'habit_notifications',
        notificationModel.toMap(),
        'id = ?',
        [notification.id],
      );
      
      return Right(notification);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Elimina una notificación de hábito
  Future<Either<Failure, void>> deleteHabitNotification(String notificationId) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'habit_notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene notificaciones de un hábito específico
  Future<Either<Failure, List<HabitNotification>>> getHabitNotifications(
      String userHabitId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'habit_notifications',
        where: 'user_habit_id = ?',
        whereArgs: [userHabitId],
        orderBy: 'created_at DESC',
      );

      final notifications = maps
          .map((map) => HabitNotificationLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(notifications);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene todas las notificaciones de hábitos
  Future<Either<Failure, List<HabitNotification>>> getAllHabitNotifications() async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'habit_notifications',
        orderBy: 'created_at DESC',
      );

      final notifications = maps
          .map((map) => HabitNotificationLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(notifications);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== NOTIFICATION SCHEDULES =====

  /// Crea un nuevo horario de notificación
  Future<Either<Failure, NotificationSchedule>> createNotificationSchedule(
      NotificationSchedule schedule) async {
    try {
      final scheduleModel = NotificationScheduleLocalModel.fromEntity(schedule);
      
      await _databaseService.insertWithTimestamp(
        'notification_schedules', 
        scheduleModel.toMap()
      );
      
      return Right(schedule);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza un horario de notificación
  Future<Either<Failure, NotificationSchedule>> updateNotificationSchedule(
      NotificationSchedule schedule) async {
    try {
      final scheduleModel = NotificationScheduleLocalModel.fromEntity(schedule);
      
      final db = await _databaseService.database;
      await db.update(
        'notification_schedules',
        scheduleModel.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
      
      return Right(schedule);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene horarios pendientes de notificación
  Future<Either<Failure, List<NotificationSchedule>>> getPendingNotifications() async {
    try {
      final db = await _databaseService.database;
      
      final now = DateTime.now();
      final maps = await db.rawQuery('''
        SELECT ns.* FROM notification_schedules ns
        INNER JOIN habit_notifications hn ON ns.habit_notification_id = hn.id
        WHERE ns.is_active = 1 
        AND hn.is_enabled = 1
        AND ns.scheduled_time <= ?
        ORDER BY ns.scheduled_time ASC
      ''', [now.millisecondsSinceEpoch]);

      final schedules = maps
          .map((map) => NotificationScheduleLocalModel.fromMap(map).toEntity())
          .toList()
          .cast<NotificationSchedule>();

      return Right(schedules);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene horarios de una notificación específica
  Future<Either<Failure, List<NotificationSchedule>>> getSchedulesForNotification(
      String notificationId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'notification_schedules',
        where: 'habit_notification_id = ?',
        whereArgs: [notificationId],
        orderBy: 'day_of_week ASC, scheduled_time ASC',
      );

      final schedules = maps
          .map((map) => NotificationScheduleLocalModel.fromMap(map).toEntity())
          .toList()
          .cast<NotificationSchedule>();

      return Right(schedules);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene el conteo de notificaciones pendientes
  Future<Either<Failure, int>> getPendingNotificationCount() async {
    try {
      final db = await _databaseService.database;
      
      final now = DateTime.now();
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM notification_schedules ns
        INNER JOIN habit_notifications hn ON ns.habit_notification_id = hn.id
        WHERE ns.is_active = 1 
        AND hn.is_enabled = 1
        AND ns.scheduled_time <= ?
      ''', [now.millisecondsSinceEpoch]);

      final count = result.first['count'] as int;
      return Right(count);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== NOTIFICATION LOGS =====

  /// Registra el envío de una notificación
  Future<Either<Failure, NotificationLog>> logNotificationSent(
      NotificationLog log) async {
    try {
      final logModel = NotificationLogLocalModel.fromEntity(log);
      
      await _databaseService.insertWithTimestamp(
        'notification_logs', 
        logModel.toMap()
      );
      
      return Right(log);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Registra una acción del usuario en una notificación
  Future<Either<Failure, NotificationLog>> logNotificationAction(
      String scheduleId, NotificationAction action) async {
    try {
      final log = NotificationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        notificationScheduleId: scheduleId,
        scheduledFor: DateTime.now(),
        sentAt: DateTime.now(),
        status: NotificationStatus.sent,
        actionTaken: action,
        createdAt: DateTime.now(),
      );

      return await logNotificationSent(log);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene logs de notificaciones
  Future<Either<Failure, List<NotificationLog>>> getNotificationLogs({
    String? scheduleId,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      final db = await _databaseService.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (scheduleId != null) {
        whereClause += 'notification_schedule_id = ?';
        whereArgs.add(scheduleId);
      }
      
      if (fromDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'created_at >= ?';
        whereArgs.add(fromDate.millisecondsSinceEpoch);
      }
      
      if (toDate != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'created_at <= ?';
        whereArgs.add(toDate.millisecondsSinceEpoch);
      }

      final maps = await db.query(
        'notification_logs',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      final logs = maps
          .map((map) => NotificationLogLocalModel.fromMap(map).toEntity())
          .toList()
          .cast<NotificationLog>();

      return Right(logs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== NOTIFICATION SETTINGS =====

  /// Obtiene la configuración de notificaciones del usuario
  Future<Either<Failure, NotificationSettings>> getNotificationSettings(
      String userId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'notification_settings',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (maps.isEmpty) {
        // Crear configuración por defecto
        final defaultSettings = NotificationSettings(
          userId: userId,
          globalNotificationsEnabled: true,
          permissionsGranted: false,
          quietHoursStart: null,
          quietHoursEnd: null,
          defaultSnoozeMinutes: 15,
          maxSnoozeCount: 3,
          defaultNotificationSound: 'default',
          updatedAt: DateTime.now(),
        );
        
        await updateNotificationSettings(defaultSettings);
        return Right(defaultSettings);
      }

      final settings = NotificationSettingsLocalModel.fromMap(maps.first).toEntity();
      return Right(settings);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza la configuración de notificaciones
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(
      NotificationSettings settings) async {
    try {
      final settingsModel = NotificationSettingsLocalModel.fromEntity(settings);
      
      await _databaseService.insertWithTimestamp(
        'notification_settings',
        settingsModel.toMap(),
      );
      
      return Right(settings);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ===== SYNC OPERATIONS =====

  /// Obtiene notificaciones no sincronizadas
  Future<Either<Failure, List<HabitNotification>>> getUnsyncedNotifications() async {
    try {
      final maps = await _databaseService.getUnsyncedRecords('habit_notifications');
      
      final notifications = maps
          .map((map) => HabitNotificationLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(notifications);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Marca una notificación como sincronizada
  Future<Either<Failure, void>> markNotificationAsSynced(String id) async {
    try {
      await _databaseService.markAsSynced('habit_notifications', id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Guarda notificaciones desde el servidor
  Future<Either<Failure, void>> saveNotificationsFromServer(
      List<HabitNotification> notifications) async {
    try {
      final db = await _databaseService.database;
      
      await db.transaction((txn) async {
        for (final notification in notifications) {
          final notificationModel = HabitNotificationLocalModel.fromEntity(
            notification
          );
          
          await txn.insert(
            'habit_notifications',
            notificationModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Limpia todas las notificaciones del usuario
  Future<Either<Failure, void>> clearNotifications(String userId) async {
    try {
      final db = await _databaseService.database;
      
      await db.transaction((txn) async {
        // Eliminar logs de notificaciones
        await txn.rawDelete('''
          DELETE FROM notification_logs 
          WHERE notification_schedule_id IN (
            SELECT ns.id FROM notification_schedules ns
            INNER JOIN habit_notifications hn ON ns.habit_notification_id = hn.id
            INNER JOIN habits h ON hn.user_habit_id = h.id
            WHERE h.user_id = ?
          )
        ''', [userId]);
        
        // Eliminar horarios de notificaciones
        await txn.rawDelete('''
          DELETE FROM notification_schedules 
          WHERE habit_notification_id IN (
            SELECT hn.id FROM habit_notifications hn
            INNER JOIN habits h ON hn.user_habit_id = h.id
            WHERE h.user_id = ?
          )
        ''', [userId]);
        
        // Eliminar notificaciones de hábitos
        await txn.rawDelete('''
          DELETE FROM habit_notifications 
          WHERE user_habit_id IN (
            SELECT id FROM habits WHERE user_id = ?
          )
        ''', [userId]);
        
        // Eliminar configuración de notificaciones
        await txn.delete(
          'notification_settings',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      });
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}