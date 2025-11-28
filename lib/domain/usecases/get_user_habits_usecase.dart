import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/core/usecases/usecase.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import 'package:vive_good_app/domain/repositories/habit_repository.dart';

class GetUserHabitsUseCase implements UseCase<List<UserHabit>, String> {
  final HabitRepository repository;

  GetUserHabitsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserHabit>>> call(String userId) async {
    final result = await repository.getUserHabits(userId);
    return result.map((habits) => habits);
  }
}
