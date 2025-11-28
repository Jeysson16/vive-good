import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/exceptions.dart';

abstract class AdminRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<Map<String, dynamic>>> getUserEvaluations({
    String? roleFilter,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });
  Future<List<Map<String, dynamic>>> getTechAcceptanceIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getKnowledgeSymptomsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getRiskHabitsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getAdminUsers({
    String? roleFilter,
    bool? activeOnly,
    int? limit,
    int? offset,
  });
  Future<List<Map<String, dynamic>>> getAdminCategories({
    bool? activeOnly,
  });
  Future<Map<String, dynamic>> createAdminCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorCode,
    String? creatorId,
  });
  Future<Map<String, dynamic>> updateAdminCategory({
    required String categoryId,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
    String? updaterId,
  });
  Future<bool> deleteAdminCategory(String categoryId);
  Future<List<Map<String, dynamic>>> getAdminHabits({
    String? categoryId,
    bool? activeOnly,
    int? limit,
    int? offset,
  });
  Future<List<Map<String, dynamic>>> getConsolidatedReport({
    DateTime? startDate,
    DateTime? endDate,
    String? roleFilter,
  });
  Future<bool> checkAdminPermissions(String userId);

  /// Crea un nuevo hábito
  Future<Map<String, dynamic>> createAdminHabit({
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
  Future<Map<String, dynamic>> updateAdminHabit({
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
  Future<bool> deleteAdminHabit(String habitId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient supabaseClient;

  AdminRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await supabaseClient.rpc('get_admin_dashboard_stats_final');
      
      if (response == null) {
        return {};
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw ServerException('Failed to get dashboard stats: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserEvaluations({
    String? roleFilter,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (roleFilter != null) params['role_filter'] = roleFilter;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (limit != null) params['limit_count'] = limit;
      if (offset != null) params['offset_count'] = offset;

      final response = await supabaseClient.rpc('get_admin_user_evaluations_final');
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get user evaluations: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTechAcceptanceIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final response = await supabaseClient.rpc('get_admin_tech_acceptance_indicators_final');
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get tech acceptance indicators: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getKnowledgeSymptomsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final response = await supabaseClient.rpc('get_admin_knowledge_symptoms_indicators', params: params);
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get knowledge symptoms indicators: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRiskHabitsIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final response = await supabaseClient.rpc('get_admin_risk_habits_indicators', params: params);
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get risk habits indicators: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAdminUsers({
    String? roleFilter,
    bool? activeOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (roleFilter != null) params['role_filter'] = roleFilter;
      if (activeOnly != null) params['active_only'] = activeOnly;
      if (limit != null) params['limit_count'] = limit;
      if (offset != null) params['offset_count'] = offset;

      final response = await supabaseClient.rpc('get_admin_users_list', params: params);
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get admin users: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAdminCategories({
    bool? activeOnly,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (activeOnly != null) params['active_only'] = activeOnly;

      final response = await supabaseClient.rpc('get_admin_categories_with_habits', params: params);
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get admin categories: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAdminHabits({
    String? categoryId,
    bool? activeOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (categoryId != null) params['category_id'] = categoryId;
      if (activeOnly != null) params['active_only'] = activeOnly;
      if (limit != null) params['limit_count'] = limit;
      if (offset != null) params['offset_count'] = offset;

      final response = await supabaseClient.rpc('get_admin_habits_with_category', params: params);
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get admin habits: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getConsolidatedReport({
    DateTime? startDate,
    DateTime? endDate,
    String? roleFilter,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (roleFilter != null) params['role_filter'] = roleFilter;

      final response = await supabaseClient.rpc('get_admin_consolidated_report_final');
      
      if (response == null) {
        return [];
      }

      final List<dynamic> data = response is List ? response : [response];
      
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      throw ServerException('Failed to get consolidated report: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createAdminCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorCode,
    String? creatorId,
  }) async {
    try {
      final params = <String, dynamic>{
        'category_name': name,
      };
      if (description != null) params['category_description'] = description;
      if (iconName != null) params['category_icon'] = iconName;
      if (colorCode != null) params['category_color'] = colorCode;
      if (creatorId != null) params['creator_id'] = creatorId;

      final response = await supabaseClient.rpc('create_admin_category', params: params);
      
      if (response == null) {
        throw ServerException('No response from server');
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw ServerException('Failed to create category: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateAdminCategory({
    required String categoryId,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
    String? updaterId,
  }) async {
    try {
      final params = <String, dynamic>{
        'category_id': categoryId,
      };
      if (name != null) params['category_name'] = name;
      if (description != null) params['category_description'] = description;
      if (iconName != null) params['category_icon'] = iconName;
      if (colorCode != null) params['category_color'] = colorCode;
      if (updaterId != null) params['updater_id'] = updaterId;

      final response = await supabaseClient.rpc('update_admin_category', params: params);
      
      if (response == null) {
        throw ServerException('No response from server');
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw ServerException('Failed to update category: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteAdminCategory(String categoryId) async {
    try {
      final response = await supabaseClient.rpc(
        'delete_admin_category',
        params: {'category_id': categoryId},
      );

      return response as bool? ?? false;
    } catch (e) {
      throw ServerException('Failed to delete category: ${e.toString()}');
    }
  }

  @override
  Future<bool> checkAdminPermissions(String userId) async {
    try {
      print('🔍 [ADMIN_DATASOURCE] Verificando permisos de admin para usuario: $userId');
      
      final response = await supabaseClient.rpc(
        'is_user_admin',
        params: {'user_uuid': userId},
      );

      print('📡 [ADMIN_DATASOURCE] Respuesta de Supabase: $response (tipo: ${response.runtimeType})');
      
      final isAdmin = response as bool? ?? false;
      print('✅ [ADMIN_DATASOURCE] Resultado final: $isAdmin');
      
      return isAdmin;
    } catch (e) {
      print('❌ [ADMIN_DATASOURCE] Error al verificar permisos de admin: $e');
      throw ServerException('Failed to check admin permissions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createAdminHabit({
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
      final params = <String, dynamic>{
        'p_name': name,
        'p_category_id': categoryId,
      };
      
      if (description != null) params['p_description'] = description;
      if (iconName != null) params['p_icon_name'] = iconName;
      if (colorCode != null) params['p_color_code'] = colorCode;
      if (difficultyLevel != null) params['p_difficulty_level'] = difficultyLevel;
      if (estimatedDuration != null) params['p_estimated_duration'] = estimatedDuration;
      if (creatorId != null) params['p_creator_id'] = creatorId;

      final response = await supabaseClient.rpc('create_admin_habit', params: params);
      
      if (response == null || (response is List && response.isEmpty)) {
        throw ServerException('No data returned from create habit');
      }

      final data = response is List ? response.first : response;
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw ServerException('Failed to create admin habit: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateAdminHabit({
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
      final params = <String, dynamic>{
        'p_habit_id': habitId,
      };
      
      if (name != null) params['p_name'] = name;
      if (description != null) params['p_description'] = description;
      if (categoryId != null) params['p_category_id'] = categoryId;
      if (iconName != null) params['p_icon_name'] = iconName;
      if (colorCode != null) params['p_color_code'] = colorCode;
      if (difficultyLevel != null) params['p_difficulty_level'] = difficultyLevel;
      if (estimatedDuration != null) params['p_estimated_duration'] = estimatedDuration;
      if (isActive != null) params['p_is_active'] = isActive;
      if (updaterId != null) params['p_updater_id'] = updaterId;

      final response = await supabaseClient.rpc('update_admin_habit', params: params);
      
      if (response == null || (response is List && response.isEmpty)) {
        throw ServerException('No data returned from update habit');
      }

      final data = response is List ? response.first : response;
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw ServerException('Failed to update admin habit: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteAdminHabit(String habitId) async {
    try {
      final response = await supabaseClient.rpc('delete_admin_habit', params: {
        'p_habit_id': habitId,
      });
      
      return response == true;
    } catch (e) {
      throw ServerException('Failed to delete admin habit: ${e.toString()}');
    }
  }
}