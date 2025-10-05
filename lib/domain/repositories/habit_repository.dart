import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/entities/category.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import 'package:vive_good_app/domain/entities/habit_breakdown.dart';

abstract class HabitRepository {
  Future<Either<Failure, List<UserHabit>>> getUserHabits(String userId);
  Future<Either<Failure, UserHabit>> getUserHabitById(String userHabitId);
  Future<Either<Failure, List<Category>>> getHabitCategories();
  Future<Either<Failure, List<Habit>>> getHabitSuggestions({
    String? userId,
    String? categoryId,
    int? limit,
  });
  Future<Either<Failure, void>> addHabit(Habit habit);
  Future<Either<Failure, void>> deleteHabit(String habitId);
  Future<Either<Failure, void>> updateUserHabit(String userHabitId, Map<String, dynamic> updates);
  Future<Either<Failure, void>> deleteUserHabit(String userHabitId);
  Future<Either<Failure, void>> logHabitCompletion(
    String habitId,
    DateTime date,
  );
  Future<Either<Failure, List<UserHabit>>> getDashboardHabits(
    String userId,
    int limit,
    bool includeCompletionStatus,
  );
  Future<Either<Failure, List<HabitBreakdown>>> getMonthlyHabitsBreakdown(
    String userId,
    int year,
    int month,
  );
}
