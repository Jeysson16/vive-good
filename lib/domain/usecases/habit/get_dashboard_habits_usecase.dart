import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_habit.dart';
import '../../repositories/habit_repository.dart';

class GetDashboardHabitsParams {
  final String userId;
  final int limit;
  final bool includeCompletionStatus;

  const GetDashboardHabitsParams({
    required this.userId,
    this.limit = 10,
    this.includeCompletionStatus = true,
  });
}

class GetDashboardHabitsUseCase implements UseCase<List<UserHabit>, GetDashboardHabitsParams> {
  final HabitRepository repository;

  GetDashboardHabitsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserHabit>>> call(GetDashboardHabitsParams params) async {
    return await repository.getDashboardHabits(params.userId, params.limit, params.includeCompletionStatus);
  }
}