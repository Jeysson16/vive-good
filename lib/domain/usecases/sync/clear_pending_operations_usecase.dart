import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/sync_repository.dart';

class ClearPendingOperationsUseCase implements UseCase<void, NoParams> {
  final SyncRepository repository;

  ClearPendingOperationsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.clearPendingOperations();
  }
}