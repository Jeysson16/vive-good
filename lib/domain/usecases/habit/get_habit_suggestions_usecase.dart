import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

class GetHabitSuggestionsParams {
  final String userId;
  final String? categoryId;
  final int limit;

  const GetHabitSuggestionsParams({
    required this.userId,
    this.categoryId,
    this.limit = 10,
  });
}

class GetHabitSuggestionsUseCase implements UseCase<List<Habit>, GetHabitSuggestionsParams> {
  final HabitRepository repository;

  GetHabitSuggestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Habit>>> call(GetHabitSuggestionsParams params) async {
    return await repository.getHabitSuggestions(
      userId: params.userId,
      categoryId: params.categoryId,
      limit: params.limit,
    );
  }
}