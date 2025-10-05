import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/sync_repository.dart';

class SyncPendingOperationsUseCase implements UseCase<void, NoParams> {
  final SyncRepository repository;

  SyncPendingOperationsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.syncPendingOperations();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}