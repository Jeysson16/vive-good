import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/category_evolution.dart';
import '../../repositories/habit_repository.dart';

/// Caso de uso para obtener análisis temporal de evolución por categoría
/// Siguiendo Clean Architecture - Domain Layer
class GetCategoryEvolutionUseCase implements UseCase<List<CategoryEvolution>, GetCategoryEvolutionParams> {
  final HabitRepository repository;

  GetCategoryEvolutionUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEvolution>>> call(GetCategoryEvolutionParams params) async {
    return await repository.getCategoryEvolution(
      userId: params.userId,
      year: params.year,
      month: params.month,
    );
  }
}

/// Parámetros para el caso de uso GetCategoryEvolutionUseCase
class GetCategoryEvolutionParams extends Equatable {
  final String userId;
  final int year;
  final int month;

  const GetCategoryEvolutionParams({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [userId, year, month];

  @override
  String toString() {
    return 'GetCategoryEvolutionParams(userId: $userId, year: $year, month: $month)';
  }
}