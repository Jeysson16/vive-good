import '../../domain/entities/migration_status.dart';
import '../../domain/entities/conversation_metrics.dart';
import '../../domain/repositories/migration_repository.dart';
import '../../services/database_migration_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

/// Implementación del repositorio de migración usando Supabase
class MigrationRepositoryImpl implements MigrationRepository {
  final SupabaseClient _supabase;

  MigrationRepositoryImpl({required SupabaseClient supabase})
      : _supabase = supabase;

  @override
  Future<void> applyMetricsMigration() async {
    try {
      await DatabaseMigrationService.applyMetricsMigration();
    } catch (e) {
      developer.log('Error aplicando migración: $e');
      throw Exception('Error al aplicar migración: $e');
    }
  }

  @override
  Future<MigrationStatus> verifyMigrationsStatus() async {
    try {
      // Verificar existencia de tablas de métricas
      final symptomsExists = await _checkTableExists('user_symptoms_knowledge');
      final eatingHabitsExists = await _checkTableExists('user_eating_habits');
      final healthyHabitsExists = await _checkTableExists('user_healthy_habits');
      final techAcceptanceExists = await _checkTableExists('user_tech_acceptance');
      final chatSessionsExists = await _checkTableExists('chat_sessions');
      final chatMessagesExists = await _checkTableExists('chat_messages');

      final missingTables = <String>[];
      if (!symptomsExists) missingTables.add('user_symptoms_knowledge');
      if (!eatingHabitsExists) missingTables.add('user_eating_habits');
      if (!healthyHabitsExists) missingTables.add('user_healthy_habits');
      if (!techAcceptanceExists) missingTables.add('user_tech_acceptance');
      if (!chatSessionsExists) missingTables.add('chat_sessions');
      if (!chatMessagesExists) missingTables.add('chat_messages');

      return MigrationStatus(
        conversationsTableExists: false, // Tabla eliminada - se usa chat_sessions
        symptomsKnowledgeTableExists: symptomsExists,
        eatingHabitsTableExists: eatingHabitsExists,
        healthyHabitsTableExists: healthyHabitsExists,
        techAcceptanceTableExists: techAcceptanceExists,
        tableColumnCounts: const {},
        missingTables: missingTables,
        missingColumns: const [],
        allMigrationsApplied: missingTables.isEmpty,
      );
    } catch (e) {
      developer.log('Error verificando estado de migraciones: $e');
      throw Exception('Error al verificar migraciones: $e');
    }
  }

  @override
  Future<void> recordConversationMetrics({
    required String userId,
    required String sessionId,
    required String messageContent,
    required Map<String, dynamic> analysisResult,
  }) async {
    try {
      // Registrar métricas basadas en el análisis
      if (analysisResult.containsKey('symptoms')) {
        await _recordSymptomsKnowledge(
          userId: userId,
          sessionId: sessionId,
          analysisResult: analysisResult,
        );
      }

      if (analysisResult.containsKey('eating_habits')) {
        await _recordEatingHabits(
          userId: userId,
          sessionId: sessionId,
          analysisResult: analysisResult,
        );
      }

      if (analysisResult.containsKey('healthy_habits')) {
        await _recordHealthyHabits(
          userId: userId,
          sessionId: sessionId,
          analysisResult: analysisResult,
        );
      }

      if (analysisResult.containsKey('tech_acceptance')) {
        await _recordTechAcceptance(
          userId: userId,
          sessionId: sessionId,
          analysisResult: analysisResult,
        );
      }
    } catch (e) {
      developer.log('Error registrando métricas: $e');
      throw Exception('Error al registrar métricas: $e');
    }
  }

  Future<bool> _checkTableExists(String tableName) async {
    try {
      final result = await _supabase
          .from('information_schema.tables')
          .select('table_name')
          .eq('table_name', tableName)
          .eq('table_schema', 'public');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _recordSymptomsKnowledge({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> analysisResult,
  }) async {
    final symptoms = analysisResult['symptoms'] as Map<String, dynamic>;
    await _supabase.from('user_symptoms_knowledge').insert({
      'user_id': userId,
      'session_id': sessionId,
      'symptom_type': symptoms['type'] ?? 'general',
      'knowledge_level': symptoms['knowledge_level'] ?? 'basic',
      'risk_factors_identified': symptoms['risk_factors'] ?? [],
      'symptoms_mentioned': symptoms['mentioned'] ?? [],
      'metadata': symptoms,
    });
  }

  Future<void> _recordEatingHabits({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> analysisResult,
  }) async {
    final habits = analysisResult['eating_habits'] as Map<String, dynamic>;
    await _supabase.from('user_eating_habits').insert({
      'user_id': userId,
      'session_id': sessionId,
      'habit_type': habits['type'] ?? 'general',
      'risk_level': habits['risk_level'] ?? 'low',
      'frequency': habits['frequency'] ?? 'occasional',
      'habits_identified': habits['identified'] ?? [],
      'recommendations_given': habits['recommendations'] ?? [],
      'metadata': habits,
    });
  }

  Future<void> _recordHealthyHabits({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> analysisResult,
  }) async {
    final habits = analysisResult['healthy_habits'] as Map<String, dynamic>;
    await _supabase.from('user_healthy_habits').insert({
      'user_id': userId,
      'session_id': sessionId,
      'habit_category': habits['category'] ?? 'general',
      'current_level': habits['current_level'] ?? 'beginner',
      'target_level': habits['target_level'] ?? 'intermediate',
      'habits_tracked': habits['tracked'] ?? [],
      'progress_indicators': habits['progress'] ?? {},
      'metadata': habits,
    });
  }

  Future<void> _recordTechAcceptance({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> analysisResult,
  }) async {
    final tech = analysisResult['tech_acceptance'] as Map<String, dynamic>;
    await _supabase.from('user_tech_acceptance').insert({
      'user_id': userId,
      'session_id': sessionId,
      'tech_category': tech['category'] ?? 'general',
      'acceptance_level': tech['acceptance_level'] ?? 'neutral',
      'usage_frequency': tech['usage_frequency'] ?? 'occasional',
      'features_used': tech['features_used'] ?? [],
      'barriers_identified': tech['barriers'] ?? [],
      'metadata': tech,
    });
  }

  @override
  Future<List<SymptomsKnowledgeMetric>> getUserSymptomsKnowledge(String userId) async {
    try {
      final response = await _supabase
          .from('user_symptoms_knowledge')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => SymptomsKnowledgeMetric.fromMap(json))
          .toList();
    } catch (e) {
      developer.log('Error obteniendo métricas de síntomas: $e');
      return [];
    }
  }

  @override
  Future<List<EatingHabitsMetric>> getUserEatingHabits(String userId) async {
    try {
      final response = await _supabase
          .from('user_eating_habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => EatingHabitsMetric.fromMap(json))
          .toList();
    } catch (e) {
      developer.log('Error obteniendo métricas de hábitos alimenticios: $e');
      return [];
    }
  }

  @override
  Future<List<HealthyHabitsMetric>> getUserHealthyHabits(String userId) async {
    try {
      final response = await _supabase
          .from('user_healthy_habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => HealthyHabitsMetric.fromMap(json))
          .toList();
    } catch (e) {
      developer.log('Error obteniendo métricas de hábitos saludables: $e');
      return [];
    }
  }

  @override
  Future<List<TechAcceptanceMetric>> getUserTechAcceptance(String userId) async {
    try {
      final response = await _supabase
          .from('user_tech_acceptance')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => TechAcceptanceMetric.fromMap(json))
          .toList();
    } catch (e) {
      developer.log('Error obteniendo métricas de aceptación tecnológica: $e');
      return [];
    }
  }

  @override
  Future<bool> checkTableExists(String tableName) async {
    return await _checkTableExists(tableName);
  }

  @override
  Future<bool> checkColumnExists(String tableName, String columnName) async {
    try {
      final result = await _supabase
          .from('information_schema.columns')
          .select('column_name')
          .eq('table_name', tableName)
          .eq('column_name', columnName)
          .eq('table_schema', 'public');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<TableColumn>> getTableColumns(String tableName) async {
    try {
      final result = await _supabase
          .from('information_schema.columns')
          .select('column_name, data_type, is_nullable')
          .eq('table_name', tableName)
          .eq('table_schema', 'public')
          .order('ordinal_position');
      
      return (result as List)
          .map((json) => TableColumn.fromMap(json))
          .toList();
    } catch (e) {
      developer.log('Error obteniendo columnas de tabla: $e');
      return [];
    }
  }
}