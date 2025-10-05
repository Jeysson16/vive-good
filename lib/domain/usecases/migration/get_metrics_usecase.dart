import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/conversation_metrics.dart';
import '../../repositories/migration_repository.dart';

/// Parámetros para obtener métricas por usuario
class GetUserMetricsParams {
  final String userId;

  const GetUserMetricsParams({required this.userId});
}

/// Caso de uso para obtener métricas de conocimiento de síntomas
class GetUserSymptomsKnowledgeUseCase
    implements UseCase<List<SymptomsKnowledgeMetric>, GetUserMetricsParams> {
  final MigrationRepository repository;

  GetUserSymptomsKnowledgeUseCase(this.repository);

  @override
  Future<Either<Failure, List<SymptomsKnowledgeMetric>>> call(
    GetUserMetricsParams params,
  ) async {
    try {
      final metrics = await repository.getUserSymptomsKnowledge(params.userId);
      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Caso de uso para obtener métricas de hábitos alimenticios
class GetUserEatingHabitsUseCase
    implements UseCase<List<EatingHabitsMetric>, GetUserMetricsParams> {
  final MigrationRepository repository;

  GetUserEatingHabitsUseCase(this.repository);

  @override
  Future<Either<Failure, List<EatingHabitsMetric>>> call(
    GetUserMetricsParams params,
  ) async {
    try {
      final metrics = await repository.getUserEatingHabits(params.userId);
      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Caso de uso para obtener métricas de hábitos saludables
class GetUserHealthyHabitsUseCase
    implements UseCase<List<HealthyHabitsMetric>, GetUserMetricsParams> {
  final MigrationRepository repository;

  GetUserHealthyHabitsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HealthyHabitsMetric>>> call(
    GetUserMetricsParams params,
  ) async {
    try {
      final metrics = await repository.getUserHealthyHabits(params.userId);
      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Caso de uso para obtener métricas de aceptación tecnológica
class GetUserTechAcceptanceUseCase
    implements UseCase<List<TechAcceptanceMetric>, GetUserMetricsParams> {
  final MigrationRepository repository;

  GetUserTechAcceptanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<TechAcceptanceMetric>>> call(
    GetUserMetricsParams params,
  ) async {
    try {
      final metrics = await repository.getUserTechAcceptance(params.userId);
      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Parámetros para verificar tabla
class CheckTableParams {
  final String tableName;

  const CheckTableParams({required this.tableName});
}

/// Caso de uso para verificar si una tabla existe
class CheckTableExistsUseCase implements UseCase<bool, CheckTableParams> {
  final MigrationRepository repository;

  CheckTableExistsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckTableParams params) async {
    try {
      final exists = await repository.checkTableExists(params.tableName);
      return Right(exists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
