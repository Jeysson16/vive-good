import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';

class SnoozeNotificationUseCase {
  final NotificationRepository repository;

  SnoozeNotificationUseCase(this.repository);

  Future<Either<Failure, String>> call(SnoozeNotificationParams params) async {
    try {
      // Validar que el tiempo de snooze sea válido
      if (!_isValidSnoozeTime(params.snoozeMinutes)) {
        return Left(ValidationFailure('Tiempo de snooze inválido'));
      }

      return await repository.snoozeNotification(
        params.notificationId,
        params.snoozeMinutes,
      );
    } catch (e) {
      return Left(ServerFailure('Error al posponer notificación: ${e.toString()}'));
    }
  }

  bool _isValidSnoozeTime(int minutes) {
    const validTimes = [5, 15, 30, 60];
    return validTimes.contains(minutes);
  }
}

class SnoozeNotificationParams {
  final String notificationId;
  final int snoozeMinutes;

  SnoozeNotificationParams({
    required this.notificationId,
    required this.snoozeMinutes,
  });
}