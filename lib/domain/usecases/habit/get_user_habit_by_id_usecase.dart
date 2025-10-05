import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_habit.dart';
import '../../repositories/habit_repository.dart';

class GetUserHabitByIdUseCase implements UseCase<UserHabit, String> {
  final HabitRepository repository;

  GetUserHabitByIdUseCase(this.repository);

  @override
  Future<Either<Failure, UserHabit>> call(String userHabitId) async {
    return await repository.getUserHabitById(userHabitId);
  }
}