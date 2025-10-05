import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/habit_repository.dart';

class DeleteUserHabitUseCase implements UseCase<void, String> {
  final HabitRepository repository;

  DeleteUserHabitUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String userHabitId) async {
    return await repository.deleteUserHabit(userHabitId);
  }
}