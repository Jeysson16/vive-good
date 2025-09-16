import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/core/usecases/usecase.dart';
import 'package:vive_good_app/domain/entities/habit_breakdown.dart';
import 'package:vive_good_app/domain/repositories/habit_repository.dart';

class GetMonthlyHabitsBreakdown implements UseCase<List<HabitBreakdown>, GetMonthlyHabitsBreakdownParams> {
  final HabitRepository repository;

  GetMonthlyHabitsBreakdown(this.repository);

  @override
  Future<Either<Failure, List<HabitBreakdown>>> call(GetMonthlyHabitsBreakdownParams params) async {
    return await repository.getMonthlyHabitsBreakdown(
      params.userId,
      params.year,
      params.month,
    );
  }
}

class GetMonthlyHabitsBreakdownParams {
  final String userId;
  final int year;
  final int month;

  GetMonthlyHabitsBreakdownParams({
    required this.userId,
    required this.year,
    required this.month,
  });
}