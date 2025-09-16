import 'package:dartz/dartz.dart';
import '../repositories/progress_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class GetDailyWeekProgress implements UseCase<Map<String, double>, GetDailyWeekProgressParams> {
  final ProgressRepository repository;

  GetDailyWeekProgress(this.repository);

  @override
  Future<Either<Failure, Map<String, double>>> call(GetDailyWeekProgressParams params) async {
    return await repository.getDailyWeekProgress(params.userId);
  }
}

class GetDailyWeekProgressParams {
  final String userId;

  GetDailyWeekProgressParams({required this.userId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetDailyWeekProgressParams && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}