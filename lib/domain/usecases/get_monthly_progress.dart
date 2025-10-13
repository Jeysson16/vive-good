import 'package:dartz/dartz.dart';
import '../repositories/progress_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/progress.dart';

class GetMonthlyProgress implements UseCase<List<Progress>, GetMonthlyProgressParams> {
  final ProgressRepository repository;

  GetMonthlyProgress(this.repository);

  @override
  Future<Either<Failure, List<Progress>>> call(GetMonthlyProgressParams params) async {
    return await repository.getMonthlyProgress(params.userId);
  }
}

class GetMonthlyProgressParams {
  final String userId;

  GetMonthlyProgressParams({required this.userId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMonthlyProgressParams && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}