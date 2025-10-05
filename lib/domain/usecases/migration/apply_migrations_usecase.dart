import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/migration_status.dart';
import '../../repositories/migration_repository.dart';

/// Caso de uso para aplicar migraciones de base de datos
/// Siguiendo Clean Architecture - Encapsula la lógica de negocio
class ApplyMigrationsUseCase implements UseCase<void, NoParams> {
  final MigrationRepository repository;

  ApplyMigrationsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.applyMetricsMigration();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Caso de uso para verificar el estado de las migraciones
class VerifyMigrationsUseCase implements UseCase<MigrationStatus, NoParams> {
  final MigrationRepository repository;

  VerifyMigrationsUseCase(this.repository);

  @override
  Future<Either<Failure, MigrationStatus>> call(NoParams params) async {
    try {
      final status = await repository.verifyMigrationsStatus();
      return Right(status);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Parámetros para registrar métricas de conversación
class RecordConversationMetricsParams {
  final String userId;
  final String sessionId;
  final String messageContent;
  final Map<String, dynamic> analysisResult;

  const RecordConversationMetricsParams({
    required this.userId,
    required this.sessionId,
    required this.messageContent,
    required this.analysisResult,
  });
}

/// Caso de uso para registrar métricas de conversación
class RecordConversationMetricsUseCase
    implements UseCase<void, RecordConversationMetricsParams> {
  final MigrationRepository repository;

  RecordConversationMetricsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    RecordConversationMetricsParams params,
  ) async {
    try {
      await repository.recordConversationMetrics(
        userId: params.userId,
        sessionId: params.sessionId,
        messageContent: params.messageContent,
        analysisResult: params.analysisResult,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
