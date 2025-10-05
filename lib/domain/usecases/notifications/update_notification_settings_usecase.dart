import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/notification_settings.dart';
import '../../repositories/notification_repository.dart';

class UpdateNotificationSettingsUseCase
    implements UseCase<NotificationSettings, UpdateNotificationSettingsParams> {
  final NotificationRepository repository;

  UpdateNotificationSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationSettings>> call(
    UpdateNotificationSettingsParams params,
  ) async {
    return await repository.updateNotificationSettings(params.settings);
  }
}

class UpdateNotificationSettingsParams {
  final NotificationSettings settings;

  UpdateNotificationSettingsParams({required this.settings});
}
