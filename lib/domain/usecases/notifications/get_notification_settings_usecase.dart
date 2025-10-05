import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/notification_settings.dart';
import '../../repositories/notification_repository.dart';

class GetNotificationSettingsUseCase
    implements UseCase<NotificationSettings?, GetNotificationSettingsParams> {
  final NotificationRepository repository;

  GetNotificationSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationSettings?>> call(
    GetNotificationSettingsParams params,
  ) async {
    return await repository.getNotificationSettings(params.userId);
  }
}

class GetNotificationSettingsParams {
  final String userId;

  GetNotificationSettingsParams({required this.userId});
}
