import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/habit_notification.dart';
import 'package:vive_good_app/domain/entities/notification_schedule.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class ScheduleHabitNotificationUseCase {
  final NotificationRepository repository;

  ScheduleHabitNotificationUseCase(this.repository);

  Future<Either<Failure, String>> call(ScheduleNotificationParams params) async {
    try {
      // Crear el horario de notificación
      final schedule = NotificationSchedule(
        id: params.scheduleId,
        habitNotificationId: params.habitNotificationId,
        dayOfWeek: params.dayOfWeek,
        scheduledTime: params.scheduledTime,
        isActive: true,
        snoozeCount: 0,
        platformNotificationId: params.platformNotificationId,
      );

      // Programar la notificación
      final result = await repository.scheduleNotification(
        params.habitNotificationId,
        schedule,
        params.message,
      );

      return result.fold(
        (failure) => Left(failure),
        (notificationId) => Right(notificationId),
      );
    } catch (e) {
      return Left(ServerFailure('Error al programar notificación: ${e.toString()}'));
    }
  }
}

class ScheduleNotificationParams {
  final String scheduleId;
  final String habitNotificationId;
  final String dayOfWeek;
  final String scheduledTime;
  final String? message;
  final int platformNotificationId;

  ScheduleNotificationParams({
    required this.scheduleId,
    required this.habitNotificationId,
    required this.dayOfWeek,
    required this.scheduledTime,
    this.message,
    required this.platformNotificationId,
  });
}