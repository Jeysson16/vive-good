import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/notification_settings.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class GetNotificationSettingsUseCase {
  final NotificationRepository repository;

  GetNotificationSettingsUseCase(this.repository);

  Future<Either<Failure, NotificationSettings>> call(String userId) async {
    try {
      return await repository.getNotificationSettings(userId);
    } catch (e) {
      return Left(ServerFailure('Error al obtener configuración de notificaciones: ${e.toString()}'));
    }
  }
}

class UpdateNotificationSettingsUseCase {
  final NotificationRepository repository;

  UpdateNotificationSettingsUseCase(this.repository);

  Future<Either<Failure, NotificationSettings>> call(NotificationSettings settings) async {
    try {
      return await repository.updateNotificationSettings(settings);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar configuración de notificaciones: ${e.toString()}'));
    }
  }
}

class RequestNotificationPermissionsUseCase {
  final NotificationRepository repository;

  RequestNotificationPermissionsUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    try {
      return await repository.requestNotificationPermissions();
    } catch (e) {
      return Left(ServerFailure('Error al solicitar permisos de notificaciones: ${e.toString()}'));
    }
  }
}

class CheckNotificationPermissionsUseCase {
  final NotificationRepository repository;

  CheckNotificationPermissionsUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    try {
      return await repository.checkNotificationPermissions();
    } catch (e) {
      return Left(ServerFailure('Error al verificar permisos de notificaciones: ${e.toString()}'));
    }
  }
}