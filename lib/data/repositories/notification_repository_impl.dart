import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/habit_notification.dart';
import '../../domain/entities/notification_schedule.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification_service.dart';
import 'local/notification_local_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalRepository notificationLocalRepository;
  final NotificationService notificationService;

  NotificationRepositoryImpl({
    required this.notificationLocalRepository,
    required this.notificationService,
  });

  // ===== NOTIFICATION SCHEDULING =====

  @override
  Future<Either<Failure, String>> scheduleNotification(
    String habitNotificationId,
    NotificationSchedule schedule,
    String? message,
  ) async {
    try {
      print('📅 [NOTIFICATION_REPO_IMPL] Programando notificación:');
      print('   HabitNotificationId: $habitNotificationId');
      print('   ScheduleId: ${schedule.id}');
      print('   Mensaje: ${message ?? 'Recordatorio de Hábito'}');
      print('   Fecha programada: ${schedule.scheduledDateTime}');
      
      // Programar la notificación usando el servicio local
      final platformNotificationId = await notificationService.scheduleNotification(
        notificationId: schedule.id,
        title: message ?? 'Recordatorio de Hábito',
        body: 'Es hora de completar tu hábito',
        scheduledTime: schedule.scheduledDateTime,
      );

      print('✅ [NOTIFICATION_REPO_IMPL] Notificación programada con ID: $platformNotificationId');
      return Right(platformNotificationId.toString());
    } catch (e) {
      print('❌ [NOTIFICATION_REPO_IMPL] Error al programar notificación: $e');
      return Left(ServerFailure('Error al programar notificación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelNotification(String notificationId) async {
    try {
      // Obtener los horarios de la notificación para cancelar las notificaciones de la plataforma
      final schedulesResult = await notificationLocalRepository.getSchedulesForNotification(notificationId);
      
      return schedulesResult.fold(
        (failure) => Left(failure),
        (schedules) async {
          // Cancelar cada notificación programada en la plataforma
          for (final schedule in schedules) {
            await notificationService.cancelNotification(schedule.platformNotificationId);
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error al cancelar notificación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelAllNotificationsForHabit(String userHabitId) async {
    try {
      // Obtener todas las notificaciones del hábito
      final notificationsResult = await notificationLocalRepository.getHabitNotifications(userHabitId);
      
      return notificationsResult.fold(
        (failure) => Left(failure),
        (notifications) async {
          // Cancelar cada notificación
          for (final notification in notifications) {
            await cancelNotification(notification.id);
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error al cancelar notificaciones del hábito: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> snoozeNotification(
    String notificationId,
    int snoozeMinutes,
  ) async {
    try {
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
      
      // Programar nueva notificación para el tiempo de snooze
      final platformNotificationId = await notificationService.scheduleNotification(
        notificationId: '${notificationId}_snooze_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Recordatorio de Hábito (Pospuesto)',
        body: 'Es hora de completar tu hábito',
        scheduledTime: snoozeTime,
      );

      // Registrar la acción de snooze
      await notificationLocalRepository.logNotificationAction(notificationId, NotificationAction.snoozed);

      return Right(platformNotificationId.toString());
    } catch (e) {
      return Left(ServerFailure('Error al posponer notificación: ${e.toString()}'));
    }
  }

  // ===== HABIT NOTIFICATION MANAGEMENT =====

  @override
  Future<Either<Failure, HabitNotification>> createHabitNotification(
    HabitNotification notification,
  ) async {
    return await notificationLocalRepository.createHabitNotification(notification);
  }

  @override
  Future<Either<Failure, HabitNotification>> updateHabitNotification(
    HabitNotification notification,
  ) async {
    return await notificationLocalRepository.updateHabitNotification(notification);
  }

  @override
  Future<Either<Failure, void>> deleteHabitNotification(String notificationId) async {
    // Primero cancelar todas las notificaciones programadas
    await cancelNotification(notificationId);
    
    // Luego eliminar de la base de datos local
    return await notificationLocalRepository.deleteHabitNotification(notificationId);
  }

  @override
  Future<Either<Failure, List<HabitNotification>>> getHabitNotifications(
    String userHabitId,
  ) async {
    return await notificationLocalRepository.getHabitNotifications(userHabitId);
  }

  @override
  Future<Either<Failure, List<HabitNotification>>> getAllHabitNotifications() async {
    return await notificationLocalRepository.getAllHabitNotifications();
  }

  // ===== SCHEDULE MANAGEMENT =====

  @override
  Future<Either<Failure, List<NotificationSchedule>>> getPendingNotifications() async {
    return await notificationLocalRepository.getPendingNotifications();
  }

  @override
  Future<Either<Failure, List<NotificationSchedule>>> getSchedulesForNotification(
    String notificationId,
  ) async {
    return await notificationLocalRepository.getSchedulesForNotification(notificationId);
  }

  @override
  Future<Either<Failure, NotificationSchedule>> updateSchedule(
    NotificationSchedule schedule,
  ) async {
    return await notificationLocalRepository.updateNotificationSchedule(schedule);
  }

  // ===== LOG MANAGEMENT =====

  @override
  Future<Either<Failure, void>> logNotificationSent(
    String scheduleId,
    DateTime sentAt,
  ) async {
    try {
      await notificationLocalRepository.logNotificationSent(NotificationLog(
        id: '',
        notificationScheduleId: scheduleId,
        scheduledFor: sentAt,
        sentAt: sentAt,
        status: NotificationStatus.sent,
        actionTaken: null,
        createdAt: DateTime.now(),
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al registrar notificación enviada: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logNotificationAction(
    String scheduleId,
    NotificationAction action,
  ) async {
    try {
      await notificationLocalRepository.logNotificationAction(scheduleId, action);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al registrar acción de notificación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<NotificationLog>>> getNotificationLogs(
    String scheduleId,
  ) async {
    return await notificationLocalRepository.getNotificationLogs(
      scheduleId: scheduleId,
    );
  }

  // ===== SETTINGS MANAGEMENT =====

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings(
    String userId,
  ) async {
    return await notificationLocalRepository.getNotificationSettings(userId);
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    return await notificationLocalRepository.updateNotificationSettings(settings);
  }

  // ===== PERMISSIONS =====

  @override
  Future<Either<Failure, bool>> requestNotificationPermissions() async {
    try {
      final granted = await notificationService.requestPermissions();
      return Right(granted);
    } catch (e) {
      return Left(ServerFailure('Error al solicitar permisos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkNotificationPermissions() async {
    try {
      final granted = await notificationService.checkPermissions();
      return Right(granted);
    } catch (e) {
      return Left(ServerFailure('Error al verificar permisos: ${e.toString()}'));
    }
  }

  // ===== UTILITIES =====

  @override
  Future<Either<Failure, void>> rescheduleAllNotifications() async {
    try {
      // Cancelar todas las notificaciones existentes
      await notificationService.cancelAllNotifications();
      
      // Obtener todas las notificaciones activas
      final notificationsResult = await notificationLocalRepository.getAllHabitNotifications();
      
      return notificationsResult.fold(
        (failure) => Left(failure),
        (notifications) async {
          // Reprogramar cada notificación activa
          for (final notification in notifications) {
            if (notification.isEnabled) {
              for (final schedule in notification.schedules) {
                if (schedule.isActive) {
                  await scheduleNotification(
                    notification.id,
                    schedule,
                    null,
                  );
                }
              }
            }
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error al reprogramar notificaciones: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getPendingNotificationCount() async {
    return await notificationLocalRepository.getPendingNotificationCount();
  }
}