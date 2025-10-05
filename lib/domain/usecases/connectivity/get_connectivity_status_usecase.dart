import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../data/services/connectivity_service.dart';
import '../../repositories/connectivity_repository.dart';

class GetConnectivityStatusUseCase implements UseCase<ConnectivityStatus, NoParams> {
  final ConnectivityRepository repository;

  GetConnectivityStatusUseCase(this.repository);

  @override
  Future<Either<Failure, ConnectivityStatus>> call(NoParams params) async {
    return await repository.getCurrentConnectivityStatus();
  }
}