import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/habit_notification.dart';
import 'package:vive_good_app/domain/entities/notification_schedule.dart';
import 'package:vive_good_app/domain/entities/notification_log.dart';
import 'package:vive_good_app/domain/entities/notification_settings.dart';

abstract class NotificationRepository {
  // Gestión de notificaciones de hábitos
  Future<Either<Failure, String>> scheduleNotification(
    String habitNotificationId,
    NotificationSchedule schedule,
    String? message,
  );

  Future<Either<Failure, void>> cancelNotification(String notificationId);

  Future<Either<Failure, void>> cancelAllNotificationsForHabit(String userHabitId);

  Future<Either<Failure, String>> snoozeNotification(
    String notificationId,
    int snoozeMinutes,
  );

  // Gestión de configuraciones de notificaciones
  Future<Either<Failure, HabitNotification>> createHabitNotification(
    HabitNotification notification,
  );

  Future<Either<Failure, HabitNotification>> updateHabitNotification(
    HabitNotification notification,
  );

  Future<Either<Failure, void>> deleteHabitNotification(String notificationId);

  Future<Either<Failure, List<HabitNotification>>> getHabitNotifications(
    String userHabitId,
  );

  Future<Either<Failure, List<HabitNotification>>> getAllHabitNotifications();

  // Gestión de horarios
  Future<Either<Failure, List<NotificationSchedule>>> getPendingNotifications();

  Future<Either<Failure, List<NotificationSchedule>>> getSchedulesForNotification(
    String habitNotificationId,
  );

  Future<Either<Failure, NotificationSchedule>> updateSchedule(
    NotificationSchedule schedule,
  );

  // Gestión de logs
  Future<Either<Failure, void>> logNotificationSent(
    String scheduleId,
    DateTime sentAt,
  );

  Future<Either<Failure, void>> logNotificationAction(
    String scheduleId,
    NotificationAction action,
  );

  Future<Either<Failure, List<NotificationLog>>> getNotificationLogs(
    String scheduleId,
  );

  // Gestión de configuraciones
  Future<Either<Failure, NotificationSettings>> getNotificationSettings(
    String userId,
  );

  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(
    NotificationSettings settings,
  );

  // Permisos
  Future<Either<Failure, bool>> requestNotificationPermissions();

  Future<Either<Failure, bool>> checkNotificationPermissions();

  // Utilidades
  Future<Either<Failure, void>> rescheduleAllNotifications();

  Future<Either<Failure, int>> getPendingNotificationCount();
}