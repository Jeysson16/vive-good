import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/habit_repository.dart';

class UpdateUserHabitParams extends Equatable {
  final String userHabitId;
  final Map<String, dynamic> updates;

  const UpdateUserHabitParams({
    required this.userHabitId,
    required this.updates,
  });

  @override
  List<Object> get props => [userHabitId, updates];
}

class UpdateUserHabitUseCase implements UseCase<void, UpdateUserHabitParams> {
  final HabitRepository repository;

  UpdateUserHabitUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserHabitParams params) async {
    return await repository.updateUserHabit(params.userHabitId, params.updates);
  }
}