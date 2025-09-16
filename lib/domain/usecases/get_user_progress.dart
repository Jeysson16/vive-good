import 'package:dartz/dartz.dart';
import '../entities/progress.dart';
import '../repositories/progress_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class GetUserProgress implements UseCase<Progress, GetUserProgressParams> {
  final ProgressRepository repository;

  GetUserProgress(this.repository);

  @override
  Future<Either<Failure, Progress>> call(GetUserProgressParams params) async {
    return await repository.getUserProgress(params.userId);
  }
}

class GetUserProgressParams {
  final String userId;

  const GetUserProgressParams({required this.userId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetUserProgressParams && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}