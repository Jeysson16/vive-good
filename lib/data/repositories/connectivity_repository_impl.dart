import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../services/connectivity_service.dart';

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  final ConnectivityService connectivityService;

  ConnectivityRepositoryImpl({required this.connectivityService});

  @override
  Future<Either<Failure, ConnectivityStatus>> getCurrentConnectivityStatus() async {
    try {
      final status = await connectivityService.getCurrentConnectivityStatus();
      return Right(status);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<ConnectivityStatus> get connectivityStream =>
      connectivityService.connectivityStream;

  @override
  Future<Either<Failure, bool>> isOnline() async {
    try {
      final status = await connectivityService.getCurrentConnectivityStatus();
      return Right(status.isOnline);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isOffline() async {
    try {
      final status = await connectivityService.getCurrentConnectivityStatus();
      return Right(status.isOffline);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}