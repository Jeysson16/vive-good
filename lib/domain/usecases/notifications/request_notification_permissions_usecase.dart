import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/notification_repository.dart';

class RequestNotificationPermissionsUseCase implements UseCase<bool, NoParams> {
  final NotificationRepository repository;

  RequestNotificationPermissionsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.requestNotificationPermissions();
  }
}
