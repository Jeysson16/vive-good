import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/habit_log.dart';
import '../../repositories/habit_repository.dart';

class LogHabitCompletionUseCase
    implements UseCase<void, LogHabitCompletionParams> {
  final HabitRepository repository;

  LogHabitCompletionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LogHabitCompletionParams params) async {
    return await repository.logHabitCompletion(params.habitId, params.date);
  }
}

class LogHabitCompletionParams extends Equatable {
  final String habitId;
  final DateTime date;

  const LogHabitCompletionParams({required this.habitId, required this.date});

  @override
  List<Object> get props => [habitId, date];
}
