import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../data/services/connectivity_service.dart';

abstract class ConnectivityRepository {
  Future<Either<Failure, ConnectivityStatus>> getCurrentConnectivityStatus();
  Stream<ConnectivityStatus> get connectivityStream;
  Future<Either<Failure, bool>> isOnline();
  Future<Either<Failure, bool>> isOffline();
}