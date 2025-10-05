import '../entities/migration_status.dart';
import '../entities/conversation_metrics.dart';

/// Repositorio abstracto para operaciones de migración de base de datos
/// Siguiendo Clean Architecture - Define el contrato para las migraciones
abstract class MigrationRepository {
  /// Aplica las migraciones de métricas (conversations eliminada)
  Future<void> applyMetricsMigration();

  /// Verifica el estado de las migraciones aplicadas
  Future<MigrationStatus> verifyMigrationsStatus();

  /// Registra métricas de conversación automáticamente
  Future<void> recordConversationMetrics({
    required String userId,
    required String sessionId,
    required String messageContent,
    required Map<String, dynamic> analysisResult,
  });

  /// Obtiene métricas de conocimiento de síntomas del usuario
  Future<List<SymptomsKnowledgeMetric>> getUserSymptomsKnowledge(String userId);

  /// Obtiene métricas de hábitos alimenticios del usuario
  Future<List<EatingHabitsMetric>> getUserEatingHabits(String userId);

  /// Obtiene métricas de hábitos saludables del usuario
  Future<List<HealthyHabitsMetric>> getUserHealthyHabits(String userId);

  /// Obtiene métricas de aceptación tecnológica del usuario
  Future<List<TechAcceptanceMetric>> getUserTechAcceptance(String userId);

  /// Verifica si una tabla específica existe
  Future<bool> checkTableExists(String tableName);

  /// Verifica si una columna específica existe en una tabla
  Future<bool> checkColumnExists(String tableName, String columnName);

  /// Obtiene información de columnas de una tabla
  Future<List<TableColumn>> getTableColumns(String tableName);
}