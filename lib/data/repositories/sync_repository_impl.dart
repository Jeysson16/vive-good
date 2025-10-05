import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/entities/pending_operation.dart';
import '../../domain/entities/sync_operation.dart';
import '../services/sync_service.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncService syncService;

  SyncRepositoryImpl({required this.syncService});

  @override
  Future<Either<Failure, void>> syncPendingOperations() async {
    return await syncService.syncPendingOperations();
  }

  @override
  Future<Either<Failure, List<PendingOperation>>> getPendingOperations() async {
    return await syncService.getPendingOperations();
  }

  @override
  Future<Either<Failure, void>> clearPendingOperations() async {
    return await syncService.clearPendingOperations();
  }

  @override
  Future<Either<Failure, int>> getPendingOperationsCount() async {
    return await syncService.getPendingOperationsCount();
  }

  @override
  Stream<List<PendingOperation>> get pendingOperationsStream =>
      syncService.pendingOperationsStream;

  @override
  Stream<int> get pendingOperationsCountStream =>
      syncService.pendingOperationsCountStream;

  @override
  Stream<bool> get syncStatusStream => syncService.isSyncingStream;
}