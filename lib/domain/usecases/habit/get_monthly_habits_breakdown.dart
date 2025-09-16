import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/habit_breakdown.dart';
import '../../repositories/habit_repository.dart';

class GetMonthlyHabitsBreakdownParams {
  final String userId;
  final int year;
  final int month;

  const GetMonthlyHabitsBreakdownParams({
    required this.userId,
    required this.year,
    required this.month,
  });
}

class GetMonthlyHabitsBreakdown implements UseCase<List<HabitBreakdown>, GetMonthlyHabitsBreakdownParams> {
  final HabitRepository repository;

  GetMonthlyHabitsBreakdown(this.repository);

  @override
  Future<Either<Failure, List<HabitBreakdown>>> call(GetMonthlyHabitsBreakdownParams params) async {
    final result = await repository.getMonthlyHabitsBreakdown(
      params.userId,
      params.year,
      params.month,
    );
    return result;
  }
}