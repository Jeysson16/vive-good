import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_habit.dart';
import '../../repositories/habit_repository.dart';

class GetUserHabitsUseCase implements UseCase<List<UserHabit>, String> {
  final HabitRepository repository;

  GetUserHabitsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserHabit>>> call(String userId) async {
    final result = await repository.getUserHabits(userId);
    return result;
  }
}
