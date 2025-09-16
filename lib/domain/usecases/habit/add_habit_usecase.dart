import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/core/usecases/usecase.dart';
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/repositories/habit_repository.dart';

class AddHabitUseCase implements UseCase<void, Habit> {
  final HabitRepository repository;

  AddHabitUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Habit habit) async {
    return await repository.addHabit(habit);
  }
}
