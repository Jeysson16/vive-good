import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/notification_schedule.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class GetPendingNotificationsUseCase {
  final NotificationRepository repository;

  GetPendingNotificationsUseCase(this.repository);

  Future<Either<Failure, List<NotificationSchedule>>> call() async {
    try {
      return await repository.getPendingNotifications();
    } catch (e) {
      return Left(ServerFailure('Error al obtener notificaciones pendientes: ${e.toString()}'));
    }
  }
}

class GetPendingNotificationCountUseCase {
  final NotificationRepository repository;

  GetPendingNotificationCountUseCase(this.repository);

  Future<Either<Failure, int>> call() async {
    try {
      return await repository.getPendingNotificationCount();
    } catch (e) {
      return Left(ServerFailure('Error al obtener contador de notificaciones: ${e.toString()}'));
    }
  }
}