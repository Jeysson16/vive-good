import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/habit_notification.dart';
import '../../repositories/notification_repository.dart';

class UpdateHabitNotificationUseCase
    implements UseCase<void, UpdateHabitNotificationParams> {
  final NotificationRepository repository;

  UpdateHabitNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    UpdateHabitNotificationParams params,
  ) async {
    try {
      // Update the habit notification
      final updateResult = await repository.updateHabitNotification(
        params.notification,
      );
      if (updateResult.isLeft()) return updateResult;

      // If notification is disabled, cancel all related platform notifications
      if (!params.notification.isEnabled) {
        final schedulesResult = await repository.getSchedulesForNotification(
          params.notification.id,
        );
        if (schedulesResult.isLeft()) return Left(ServerFailure());

        final schedules = schedulesResult.getOrElse(() => []);
        for (final schedule in schedules) {
          await repository.cancelNotification(schedule.platformNotificationId.toString());

          // Update schedule to inactive
          final updatedSchedule = schedule.copyWith(isActive: false);
          await repository.updateSchedule(updatedSchedule);
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}

class UpdateHabitNotificationParams {
  final HabitNotification notification;

  UpdateHabitNotificationParams({required this.notification});
}
