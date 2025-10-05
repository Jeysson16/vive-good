import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class CancelHabitNotificationUseCase {
  final NotificationRepository repository;

  CancelHabitNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call(String notificationId) async {
    try {
      return await repository.cancelNotification(notificationId);
    } catch (e) {
      return Left(ServerFailure('Error al cancelar notificación: ${e.toString()}'));
    }
  }
}

class CancelAllNotificationsForHabitUseCase {
  final NotificationRepository repository;

  CancelAllNotificationsForHabitUseCase(this.repository);

  Future<Either<Failure, void>> call(String userHabitId) async {
    try {
      return await repository.cancelAllNotificationsForHabit(userHabitId);
    } catch (e) {
      return Left(ServerFailure('Error al cancelar notificaciones del hábito: ${e.toString()}'));
    }
  }
}