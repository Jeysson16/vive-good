import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/notification_schedule.dart';
import '../../repositories/notification_repository.dart';

class GetSchedulesByNotificationIdUseCase
    implements
        UseCase<
          List<NotificationSchedule>,
          GetSchedulesByNotificationIdParams
        > {
  final NotificationRepository repository;

  GetSchedulesByNotificationIdUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationSchedule>>> call(
    GetSchedulesByNotificationIdParams params,
  ) async {
    return await repository.getSchedulesForNotification(params.notificationId);
  }
}

class GetSchedulesByNotificationIdParams {
  final String notificationId;

  GetSchedulesByNotificationIdParams({required this.notificationId});
}
