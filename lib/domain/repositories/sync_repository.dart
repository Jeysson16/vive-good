import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/pending_operation.dart';
import '../entities/sync_operation.dart';
import '../../data/services/sync_service.dart';

abstract class SyncRepository {
  Future<Either<Failure, void>> syncPendingOperations();
  Future<Either<Failure, List<PendingOperation>>> getPendingOperations();
  Future<Either<Failure, void>> clearPendingOperations();
  Future<Either<Failure, int>> getPendingOperationsCount();
  Stream<List<PendingOperation>> get pendingOperationsStream;
  Stream<int> get pendingOperationsCountStream;
  Stream<bool> get syncStatusStream;
}