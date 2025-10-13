import 'package:dartz/dartz.dart';
import '../repositories/progress_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class GetMonthlyIndicators implements UseCase<Map<String, String>, GetMonthlyIndicatorsParams> {
  final ProgressRepository repository;

  GetMonthlyIndicators(this.repository);

  @override
  Future<Either<Failure, Map<String, String>>> call(GetMonthlyIndicatorsParams params) async {
    return await repository.getMonthlyIndicators(params.userId, params.year, params.month);
  }
}

class GetMonthlyIndicatorsParams {
  final String userId;
  final int year;
  final int month;

  GetMonthlyIndicatorsParams({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMonthlyIndicatorsParams && 
           other.userId == userId && 
           other.year == year && 
           other.month == month;
  }

  @override
  int get hashCode => userId.hashCode ^ year.hashCode ^ month.hashCode;
}