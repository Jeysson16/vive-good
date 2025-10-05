import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/notification_repository.dart';

class CheckNotificationPermissionsUseCase implements UseCase<bool, NoParams> {
  final NotificationRepository repository;

  CheckNotificationPermissionsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.checkNotificationPermissions();
  }
}
