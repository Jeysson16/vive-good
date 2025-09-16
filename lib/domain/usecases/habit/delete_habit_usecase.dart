import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/core/usecases/usecase.dart';
import 'package:vive_good_app/domain/repositories/habit_repository.dart';

class DeleteHabitUseCase implements UseCase<void, String> {
  final HabitRepository repository;

  DeleteHabitUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String habitId) async {
    return await repository.deleteHabit(habitId);
  }
}
