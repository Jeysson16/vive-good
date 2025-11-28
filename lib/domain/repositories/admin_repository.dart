import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/admin/admin_dashboard_stats.dart';
import '../entities/admin/user_evaluation.dart';
import '../entities/admin/tech_acceptance_indicators.dart';
import '../entities/admin/knowledge_symptoms_indicators.dart';
import '../entities/admin/risk_habits_indicators.dart';
import '../entities/admin/admin_user.dart';
import '../entities/admin/admin_category.dart';
import '../entities/admin/admin_habit.dart';
import '../entities/admin/consolidated_report.dart';

abstract class AdminRepository {
  /// Obtiene las estadísticas del dashboard de administración
  Future<Either<Failure, AdminDashboardStats>> getDashboardStats();

  /// Obtiene las evaluaciones de usuarios con filtros opcionales
  Future<Either<Failure, List<UserEvaluation>>> getUserEvaluations({
    String? roleFilter,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Obtiene los indicadores de aceptación tecnológica
  Future<Either<Failure, List<TechAcceptanceIndicators>>> getTechAcceptanceIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obtiene los indicadores de conocimiento de síntomas
  Future<Either<Failure, List<KnowledgeSymptomsIndicators>>> getKnowledgeSymptomsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obtiene los indicadores de hábitos de riesgo
  Future<Either<Failure, List<RiskHabitsIndicators>>> getRiskHabitsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obtiene la lista de usuarios con roles para administración
  Future<Either<Failure, List<AdminUser>>> getAdminUsers({
    String? roleFilter,
    bool? activeOnly,
    int? limit,
    int? offset,
  });

  /// Obtiene las categorías con información de administración
  Future<Either<Failure, List<AdminCategory>>> getAdminCategories({
    bool? activeOnly,
  });

  /// Crea una nueva categoría
  Future<Either<Failure, AdminCategory>> createAdminCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorCode,
    String? creatorId,
  });

  /// Actualiza una categoría existente
  Future<Either<Failure, AdminCategory>> updateAdminCategory({
    required String categoryId,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
    String? updaterId,
  });

  /// Elimina una categoría
  Future<Either<Failure, bool>> deleteAdminCategory(String categoryId);

  /// Obtiene los hábitos con información de administración
  Future<Either<Failure, List<AdminHabit>>> getAdminHabits({
    String? categoryId,
    bool? activeOnly,
    int? limit,
    int? offset,
  });

  /// Crea un nuevo hábito
  Future<Either<Failure, AdminHabit>> createAdminHabit({
    required String name,
    required String categoryId,
    String? description,
    String? iconName,
    String? colorCode,
    String? difficultyLevel,
    int? estimatedDuration,
    String? creatorId,
  });

  /// Actualiza un hábito existente
  Future<Either<Failure, AdminHabit>> updateAdminHabit({
    required String habitId,
    String? name,
    String? description,
    String? categoryId,
    String? iconName,
    String? colorCode,
    String? difficultyLevel,
    int? estimatedDuration,
    bool? isActive,
    String? updaterId,
  });

  /// Elimina un hábito
  Future<Either<Failure, bool>> deleteAdminHabit(String habitId);

  /// Obtiene el reporte consolidado para exportación
  Future<Either<Failure, List<ConsolidatedReport>>> getConsolidatedReport({
    DateTime? startDate,
    DateTime? endDate,
    String? roleFilter,
  });

  /// Verifica si el usuario actual tiene permisos de administrador
  Future<Either<Failure, bool>> checkAdminPermissions(String userId);

  /// Exporta datos a Excel
  Future<Either<Failure, String>> exportToExcel({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  });
}