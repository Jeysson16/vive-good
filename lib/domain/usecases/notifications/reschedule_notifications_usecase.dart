import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class RescheduleAllNotificationsUseCase {
  final NotificationRepository repository;

  RescheduleAllNotificationsUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    try {
      return await repository.rescheduleAllNotifications();
    } catch (e) {
      return Left(ServerFailure('Error al reprogramar notificaciones: ${e.toString()}'));
    }
  }
}

class RescheduleHabitNotificationsUseCase {
  final NotificationRepository repository;

  RescheduleHabitNotificationsUseCase(this.repository);

  Future<Either<Failure, void>> call(String userHabitId) async {
    try {
      // Primero cancelamos todas las notificaciones del hábito
      final cancelResult = await repository.cancelAllNotificationsForHabit(userHabitId);
      
      return cancelResult.fold(
        (failure) => Left(failure),
        (_) async {
          // Luego obtenemos las notificaciones del hábito y las reprogramamos
          final notificationsResult = await repository.getHabitNotifications(userHabitId);
          
          return notificationsResult.fold(
            (failure) => Left(failure),
            (notifications) async {
              for (final notification in notifications) {
                if (notification.isEnabled) {
                  for (final schedule in notification.schedules) {
                    if (schedule.isActive) {
                      await repository.scheduleNotification(
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
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error al reprogramar notificaciones del hábito: ${e.toString()}'));
    }
  }
}

class RescheduleNotificationsUseCase {
  final NotificationRepository repository;

  RescheduleNotificationsUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    try {
      return await repository.rescheduleAllNotifications();
    } catch (e) {
      return Left(ServerFailure('Error al reprogramar notificaciones: ${e.toString()}'));
    }
  }
}