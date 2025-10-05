import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/habit_notification.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class CreateHabitNotificationUseCase {
  final NotificationRepository repository;

  CreateHabitNotificationUseCase(this.repository);

  Future<Either<Failure, HabitNotification>> call(HabitNotification notification) async {
    try {
      return await repository.createHabitNotification(notification);
    } catch (e) {
      return Left(ServerFailure('Error al crear notificación de hábito: ${e.toString()}'));
    }
  }
}

class UpdateHabitNotificationUseCase {
  final NotificationRepository repository;

  UpdateHabitNotificationUseCase(this.repository);

  Future<Either<Failure, HabitNotification>> call(HabitNotification notification) async {
    try {
      return await repository.updateHabitNotification(notification);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar notificación de hábito: ${e.toString()}'));
    }
  }
}

class DeleteHabitNotificationUseCase {
  final NotificationRepository repository;

  DeleteHabitNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call(String notificationId) async {
    try {
      return await repository.deleteHabitNotification(notificationId);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar notificación de hábito: ${e.toString()}'));
    }
  }
}

class GetHabitNotificationsUseCase {
  final NotificationRepository repository;

  GetHabitNotificationsUseCase(this.repository);

  Future<Either<Failure, List<HabitNotification>>> call(String userHabitId) async {
    try {
      return await repository.getHabitNotifications(userHabitId);
    } catch (e) {
      return Left(ServerFailure('Error al obtener notificaciones del hábito: ${e.toString()}'));
    }
  }
}

class GetAllHabitNotificationsUseCase {
  final NotificationRepository repository;

  GetAllHabitNotificationsUseCase(this.repository);

  Future<Either<Failure, List<HabitNotification>>> call() async {
    try {
      return await repository.getAllHabitNotifications();
    } catch (e) {
      return Left(ServerFailure('Error al obtener todas las notificaciones: ${e.toString()}'));
    }
  }
}