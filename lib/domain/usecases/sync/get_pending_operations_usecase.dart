import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../data/services/sync_service.dart';
import '../../repositories/sync_repository.dart';
import '../../entities/pending_operation.dart';

class GetPendingOperationsUseCase implements UseCase<List<PendingOperation>, NoParams> {
  final SyncRepository repository;

  GetPendingOperationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PendingOperation>>> call(NoParams params) async {
    return await repository.getPendingOperations();
  }
}