import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/admin/admin_dashboard_stats.dart';
import '../../domain/entities/admin/user_evaluation.dart';
import '../../domain/entities/admin/tech_acceptance_indicators.dart';
import '../../domain/entities/admin/knowledge_symptoms_indicators.dart';
import '../../domain/entities/admin/risk_habits_indicators.dart';
import '../../domain/entities/admin/admin_user.dart';
import '../../domain/entities/admin/admin_category.dart';
import '../../domain/entities/admin/admin_habit.dart';
import '../../domain/entities/admin/consolidated_report.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AdminDashboardStats>> getDashboardStats() async {
    try {
      final result = await remoteDataSource.getDashboardStats();
      
      final stats = AdminDashboardStats(
        totalUsers: result['total_users'] ?? 0,
        activeUsers: result['active_users'] ?? 0,
        totalHabits: result['total_habits'] ?? 0,
        totalEvaluations: result['total_evaluations'] ?? 0,
        totalConsultations: result['total_consultations'] ?? 0,
        averageRating: result['average_rating'] != null 
            ? (result['average_rating']).toDouble()
            : 0.0,
        totalCategories: result['total_categories'] ?? 0,
        totalRoles: result['total_roles'] ?? 0,
        lastUpdated: result['last_updated'] != null 
            ? DateTime.parse(result['last_updated'])
            : DateTime.now(),
      );
      
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserEvaluation>>> getUserEvaluations({
    DateTime? startDate,
    DateTime? endDate,
    String? roleFilter,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await remoteDataSource.getUserEvaluations(
        startDate: startDate,
        endDate: endDate,
        roleFilter: roleFilter,
        limit: limit,
        offset: offset,
      );
      
      final evaluations = result.map((item) => UserEvaluation(
        userId: item['user_id'] ?? '',
        userName: item['user_name'] ?? '',
        userEmail: item['user_email'] ?? '',
        roleName: item['role_name'],
        lastLogin: item['last_login'] != null 
            ? DateTime.parse(item['last_login'])
            : null,
        totalHabits: item['total_habits'] ?? 0,
        completedHabits: item['completed_habits'] ?? 0,
        completionRate: (item['completion_rate'] ?? 0.0).toDouble(),
        totalConsultations: item['total_consultations'] ?? 0,
        averageRating: item['average_rating'] != null 
            ? (item['average_rating']).toDouble()
            : null,
        createdAt: item['created_at'] != null 
            ? DateTime.parse(item['created_at'])
            : DateTime.now(),
        isActive: item['is_active'] ?? true,
      )).toList();
      
      return Right(evaluations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TechAcceptanceIndicators>>> getTechAcceptanceIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getTechAcceptanceIndicators(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      final indicators = result.map((item) => TechAcceptanceIndicators(
        userId: item['user_id'] ?? '',
        userName: item['user_name'] ?? '',
        perceivedUsefulness: (item['perceived_usefulness'] ?? 0.0).toDouble(),
        perceivedEaseOfUse: (item['perceived_ease_of_use'] ?? 0.0).toDouble(),
        attitudeTowardUsing: (item['attitude_toward_using'] ?? 0.0).toDouble(),
        behavioralIntention: (item['behavioral_intention'] ?? 0.0).toDouble(),
        actualSystemUse: (item['actual_system_use'] ?? 0.0).toDouble(),
        overallScore: (item['overall_score'] ?? 0.0).toDouble(),
        acceptanceLevel: item['acceptance_level'] ?? 'Bajo',
        evaluationDate: item['evaluation_date'] != null 
            ? DateTime.parse(item['evaluation_date'])
            : DateTime.now(),
        additionalMetrics: item['additional_metrics'],
      )).toList();
      
      return Right(indicators);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<KnowledgeSymptomsIndicators>>> getKnowledgeSymptomsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getKnowledgeSymptomsIndicators(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      final indicators = result.map((item) => KnowledgeSymptomsIndicators(
        userId: item['user_id'] ?? '',
        userName: item['user_name'] ?? '',
        knowledgeScore: (item['knowledge_score'] ?? 0.0).toDouble(),
        totalSymptoms: item['total_symptoms'] ?? 0,
        identifiedSymptoms: item['identified_symptoms'] ?? 0,
        identificationRate: (item['identification_rate'] ?? 0.0).toDouble(),
        strongAreas: List<String>.from(item['strong_areas'] ?? []),
        weakAreas: List<String>.from(item['weak_areas'] ?? []),
        knowledgeLevel: item['knowledge_level'] ?? 'Bajo',
        evaluationDate: item['evaluation_date'] != null 
            ? DateTime.parse(item['evaluation_date'])
            : DateTime.now(),
        detailedScores: item['detailed_scores'],
      )).toList();
      
      return Right(indicators);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<RiskHabitsIndicators>>> getRiskHabitsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getRiskHabitsIndicators(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      final indicators = result.map((item) => RiskHabitsIndicators(
        userId: item['user_id'] ?? '',
        userName: item['user_name'] ?? '',
        totalRiskHabits: item['total_risk_habits'] ?? 0,
        highRiskHabits: item['high_risk_habits'] ?? 0,
        mediumRiskHabits: item['medium_risk_habits'] ?? 0,
        lowRiskHabits: item['low_risk_habits'] ?? 0,
        riskScore: (item['risk_score'] ?? 0.0).toDouble(),
        riskLevel: item['risk_level'] ?? 'Bajo',
        mainRiskCategories: List<String>.from(item['main_risk_categories'] ?? []),
        habitsByCategory: Map<String, int>.from(item['habits_by_category'] ?? {}),
        evaluationDate: item['evaluation_date'] != null 
            ? DateTime.parse(item['evaluation_date'])
            : DateTime.now(),
        recommendations: item['recommendations'],
      )).toList();
      
      return Right(indicators);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AdminUser>>> getAdminUsers({
    String? roleFilter,
    bool? activeOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await remoteDataSource.getAdminUsers(
        roleFilter: roleFilter,
        activeOnly: activeOnly,
        limit: limit,
        offset: offset,
      );
      
      final users = result.map((item) => AdminUser(
        id: item['id'] ?? '',
        email: item['email'] ?? '',
        fullName: item['full_name'] ?? '',
        avatarUrl: item['avatar_url'],
        roleName: item['role_name'] ?? '',
        roleId: item['role_id'] ?? '',
        createdAt: item['created_at'] != null 
            ? DateTime.parse(item['created_at'])
            : DateTime.now(),
        lastSignInAt: item['last_sign_in_at'] != null 
            ? DateTime.parse(item['last_sign_in_at'])
            : null,
        isActive: item['is_active'] ?? true,
        metadata: item['metadata'],
      )).toList();
      
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AdminCategory>>> getAdminCategories({
    bool? activeOnly,
  }) async {
    try {
      final result = await remoteDataSource.getAdminCategories(
        activeOnly: activeOnly,
      );
      
      final categories = result.map((item) => AdminCategory(
        id: item['id'] ?? '',
        name: item['name'] ?? '',
        description: item['description'] ?? '',
        iconName: item['icon_name'],
        colorCode: item['color_code'],
        habitCount: item['habit_count'] ?? 0,
        isActive: item['is_active'] ?? true,
        createdAt: item['created_at'] != null 
            ? DateTime.parse(item['created_at'])
            : DateTime.now(),
        updatedAt: item['updated_at'] != null 
            ? DateTime.parse(item['updated_at'])
            : null,
      )).toList();
      
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AdminCategory>> createAdminCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorCode,
    String? creatorId,
  }) async {
    try {
      final result = await remoteDataSource.createAdminCategory(
        name: name,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
        creatorId: creatorId,
      );
      
      final category = AdminCategory(
        id: result['id'] ?? '',
        name: result['name'] ?? '',
        description: result['description'],
        iconName: result['icon_name'],
        colorCode: result['color_code'],
        habitCount: result['habit_count'] ?? 0,
        isActive: result['is_active'] ?? true,
        createdAt: result['created_at'] != null 
            ? DateTime.parse(result['created_at'])
            : DateTime.now(),
        updatedAt: result['updated_at'] != null 
            ? DateTime.parse(result['updated_at'])
            : null,
      );
      
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AdminCategory>> updateAdminCategory({
    required String categoryId,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
    String? updaterId,
  }) async {
    try {
      final result = await remoteDataSource.updateAdminCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
        updaterId: updaterId,
      );
      
      final category = AdminCategory(
        id: result['id'] ?? '',
        name: result['name'] ?? '',
        description: result['description'],
        iconName: result['icon_name'],
        colorCode: result['color_code'],
        habitCount: result['habit_count'] ?? 0,
        isActive: result['is_active'] ?? true,
        createdAt: result['created_at'] != null 
            ? DateTime.parse(result['created_at'])
            : DateTime.now(),
        updatedAt: result['updated_at'] != null 
            ? DateTime.parse(result['updated_at'])
            : null,
      );
      
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAdminCategory(String categoryId) async {
    try {
      final result = await remoteDataSource.deleteAdminCategory(categoryId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AdminHabit>>> getAdminHabits({
    String? categoryId,
    bool? activeOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await remoteDataSource.getAdminHabits(
        categoryId: categoryId,
        activeOnly: activeOnly,
        limit: limit,
        offset: offset,
      );
      
      final habits = result.map((item) => AdminHabit(
        id: item['id'] ?? '',
        name: item['name'] ?? '',
        description: item['description'] ?? '',
        categoryId: item['category_id'] ?? '',
        categoryName: item['category_name'] ?? '',
        iconName: item['icon_name'],
        colorCode: item['color_code'],
        userCount: item['user_count'] ?? 0,
        averageCompletion: (item['average_completion'] ?? 0.0).toDouble(),
        isActive: item['is_active'] ?? true,
        createdAt: item['created_at'] != null 
            ? DateTime.parse(item['created_at'])
            : DateTime.now(),
        updatedAt: item['updated_at'] != null 
            ? DateTime.parse(item['updated_at'])
            : null,
      )).toList();
      
      return Right(habits);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AdminHabit>> createAdminHabit({
    required String name,
    required String categoryId,
    String? description,
    String? iconName,
    String? colorCode,
    String? difficultyLevel,
    int? estimatedDuration,
    String? creatorId,
  }) async {
    try {
      final result = await remoteDataSource.createAdminHabit(
        name: name,
        categoryId: categoryId,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
        difficultyLevel: difficultyLevel,
        estimatedDuration: estimatedDuration,
        creatorId: creatorId,
      );
      
      final habit = AdminHabit(
        id: result['id'] ?? '',
        name: result['name'] ?? '',
        description: result['description'] ?? '',
        categoryId: result['category_id'] ?? '',
        categoryName: result['category_name'] ?? '',
        iconName: result['icon_name'],
        colorCode: result['color_code'],
        userCount: result['user_count'] ?? 0,
        averageCompletion: (result['average_completion'] ?? 0.0).toDouble(),
        isActive: result['is_active'] ?? true,
        createdAt: result['created_at'] != null 
            ? DateTime.parse(result['created_at'])
            : DateTime.now(),
        updatedAt: result['updated_at'] != null 
            ? DateTime.parse(result['updated_at'])
            : null,
      );
      
      return Right(habit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
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
  }) async {
    try {
      final result = await remoteDataSource.updateAdminHabit(
        habitId: habitId,
        name: name,
        description: description,
        categoryId: categoryId,
        iconName: iconName,
        colorCode: colorCode,
        difficultyLevel: difficultyLevel,
        estimatedDuration: estimatedDuration,
        isActive: isActive,
        updaterId: updaterId,
      );
      
      final habit = AdminHabit(
        id: result['id'] ?? '',
        name: result['name'] ?? '',
        description: result['description'] ?? '',
        categoryId: result['category_id'] ?? '',
        categoryName: result['category_name'] ?? '',
        iconName: result['icon_name'],
        colorCode: result['color_code'],
        userCount: result['user_count'] ?? 0,
        averageCompletion: (result['average_completion'] ?? 0.0).toDouble(),
        isActive: result['is_active'] ?? true,
        createdAt: result['created_at'] != null 
            ? DateTime.parse(result['created_at'])
            : DateTime.now(),
        updatedAt: result['updated_at'] != null 
            ? DateTime.parse(result['updated_at'])
            : null,
      );
      
      return Right(habit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAdminHabit(String habitId) async {
    try {
      final result = await remoteDataSource.deleteAdminHabit(habitId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ConsolidatedReport>>> getConsolidatedReport({
    DateTime? startDate,
    DateTime? endDate,
    String? roleFilter,
  }) async {
    try {
      final result = await remoteDataSource.getConsolidatedReport(
        startDate: startDate,
        endDate: endDate,
        roleFilter: roleFilter,
      );
      
      final reports = result.map((item) => ConsolidatedReport(
        userId: item['user_id'] ?? '',
        userName: item['user_name'] ?? '',
        userEmail: item['user_email'] ?? '',
        roleName: item['role_name'],
        lastLogin: item['last_login'] != null 
            ? DateTime.parse(item['last_login'])
            : null,
        totalHabits: item['total_habits'] ?? 0,
        completedHabits: item['completed_habits'] ?? 0,
        completionRate: (item['completion_rate'] ?? 0.0).toDouble(),
        totalConsultations: item['total_consultations'] ?? 0,
        averageRating: item['average_rating'] != null 
            ? (item['average_rating']).toDouble()
            : null,
        techAcceptanceScore: item['tech_acceptance_score'] != null 
            ? (item['tech_acceptance_score']).toDouble()
            : null,
        techAcceptanceLevel: item['tech_acceptance_level'],
        knowledgeScore: item['knowledge_score'] != null 
            ? (item['knowledge_score']).toDouble()
            : null,
        knowledgeLevel: item['knowledge_level'],
        totalRiskHabits: item['total_risk_habits'] ?? 0,
        riskScore: item['risk_score'] != null 
            ? (item['risk_score']).toDouble()
            : null,
        riskLevel: item['risk_level'],
        createdAt: item['created_at'] != null 
            ? DateTime.parse(item['created_at'])
            : DateTime.now(),
        isActive: item['is_active'] ?? true,
      )).toList();
      
      return Right(reports);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAdminPermissions(String userId) async {
    try {
      print('🏛️ [ADMIN_REPOSITORY] Verificando permisos de admin para userId: $userId');
      
      final result = await remoteDataSource.checkAdminPermissions(userId);
      
      print('🏛️ [ADMIN_REPOSITORY] Resultado del datasource: $result');
      
      return Right(result);
    } on ServerException catch (e) {
      print('❌ [ADMIN_REPOSITORY] ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [ADMIN_REPOSITORY] Error inesperado: $e');
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportToExcel({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Reporte'];
      
      // Obtener datos según el tipo de reporte
      List<dynamic> data = [];
      List<String> headers = [];
      
      switch (reportType) {
        case 'consolidated':
          final result = await getConsolidatedReport(
            startDate: startDate,
            endDate: endDate,
            roleFilter: filters?['roleFilter'],
          );
          result.fold(
            (failure) => throw Exception(failure.toString()),
            (reports) {
              data = reports;
              headers = [
                'ID Usuario', 'Nombre', 'Email', 'Rol', 'Último Login',
                'Total Hábitos', 'Hábitos Completados', 'Tasa Completitud',
                'Total Consultas', 'Rating Promedio', 'Score Aceptación Tech',
                'Nivel Aceptación Tech', 'Score Conocimiento', 'Nivel Conocimiento',
                'Total Hábitos Riesgo', 'Score Riesgo', 'Nivel Riesgo',
                'Fecha Creación', 'Activo'
              ];
            },
          );
          break;
        case 'users':
          final result = await getUserEvaluations(
            startDate: startDate,
            endDate: endDate,
            roleFilter: filters?['roleFilter'],
          );
          result.fold(
            (failure) => throw Exception(failure.toString()),
            (evaluations) {
              data = evaluations;
              headers = [
                'ID Usuario', 'Nombre', 'Email', 'Rol', 'Último Login',
                'Total Hábitos', 'Hábitos Completados', 'Tasa Completitud',
                'Total Consultas', 'Rating Promedio', 'Fecha Creación', 'Activo'
              ];
            },
          );
          break;
        default:
          throw Exception('Tipo de reporte no válido');
      }
      
      // Agregar headers
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }
      
      // Agregar datos
      for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final item = data[rowIndex];
        List<dynamic> rowData = [];
        
        if (reportType == 'consolidated' && item is ConsolidatedReport) {
          rowData = [
            item.userId, item.userName, item.userEmail, item.roleName ?? '',
            item.lastLogin?.toString() ?? '', item.totalHabits, item.completedHabits,
            item.completionRate, item.totalConsultations, item.averageRating ?? 0,
            item.techAcceptanceScore ?? 0, item.techAcceptanceLevel ?? '',
            item.knowledgeScore ?? 0, item.knowledgeLevel ?? '',
            item.totalRiskHabits, item.riskScore ?? 0, item.riskLevel ?? '',
            item.createdAt.toString(), item.isActive
          ];
        } else if (reportType == 'users' && item is UserEvaluation) {
          rowData = [
            item.userId, item.userName, item.userEmail, item.roleName ?? '',
            item.lastLogin?.toString() ?? '', item.totalHabits, item.completedHabits,
            item.completionRate, item.totalConsultations, item.averageRating ?? 0,
            item.createdAt.toString(), item.isActive
          ];
        }
        
        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cellValue = rowData[colIndex];
          sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex + 1))
              .value = cellValue is String 
                  ? TextCellValue(cellValue)
                  : cellValue is num 
                      ? DoubleCellValue(cellValue.toDouble())
                      : cellValue is bool
                          ? BoolCellValue(cellValue)
                          : TextCellValue(cellValue.toString());
        }
      }
      
      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_${reportType}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      return Right(filePath);
    } catch (e) {
      return Left(ServerFailure('Error al exportar a Excel: ${e.toString()}'));
    }
  }
}