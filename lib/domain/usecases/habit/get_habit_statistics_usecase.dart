import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/habit_statistics.dart';
import '../../repositories/habit_repository.dart';

/// Caso de uso para obtener estadísticas detalladas de hábitos por categoría
/// Siguiendo Clean Architecture - Domain Layer
class GetHabitStatisticsUseCase implements UseCase<List<HabitStatistics>, GetHabitStatisticsParams> {
  final HabitRepository repository;

  GetHabitStatisticsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HabitStatistics>>> call(GetHabitStatisticsParams params) async {
    return await repository.getHabitStatistics(
      userId: params.userId,
      year: params.year,
      month: params.month,
    );
  }
}

/// Parámetros para el caso de uso GetHabitStatisticsUseCase
class GetHabitStatisticsParams extends Equatable {
  final String userId;
  final int year;
  final int month;

  const GetHabitStatisticsParams({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [userId, year, month];

  @override
  String toString() {
    return 'GetHabitStatisticsParams(userId: $userId, year: $year, month: $month)';
  }
}