import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/sync_repository.dart';

class GetPendingOperationsCountUseCase implements UseCase<int, NoParams> {
  final SyncRepository repository;

  GetPendingOperationsCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getPendingOperationsCount();
  }
}