import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_good_app/core/error/exceptions.dart';
import 'package:vive_good_app/data/models/category_model.dart';
import 'package:vive_good_app/data/models/habit_breakdown_model.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/models/user_habit_model.dart';
import 'package:vive_good_app/data/models/habit_statistics_model.dart';
import 'package:vive_good_app/data/models/category_evolution_model.dart';

abstract class HabitRemoteDataSource {
  Future<List<UserHabitModel>> getUserHabits(String userId);
  Future<UserHabitModel> getUserHabitById(String userHabitId);
  Future<List<CategoryModel>> getHabitCategories();
  Future<void> addHabit(HabitModel habit);
  Future<void> deleteHabit(String habitId);
  Future<void> updateUserHabit(
    String userHabitId,
    Map<String, dynamic> updates,
  );
  Future<void> deleteUserHabit(String userHabitId);
  Future<void> logHabitCompletion(String habitId, DateTime date);
  Future<List<HabitModel>> getHabitSuggestions({
    String? userId,
    String? categoryId,
    int? limit,
  });
  Future<List<UserHabitModel>> getDashboardHabits(
    String userId,
    int limit,
    bool includeCompletionStatus,
  );
  Future<List<HabitBreakdownModel>> getMonthlyHabitsBreakdown(
    String userId,
    int year,
    int month,
  );
  
  /// Obtiene estadísticas detalladas de hábitos por categoría
  Future<List<HabitStatisticsModel>> getHabitStatistics({
    required String userId,
    required int year,
    required int month,
  });
  
  /// Obtiene análisis temporal de evolución por categoría
  Future<List<CategoryEvolutionModel>> getCategoryEvolution({
    required String userId,
    required int year,
    required int month,
  });
}

class HabitRemoteDataSourceImpl implements HabitRemoteDataSource {
  final SupabaseClient supabaseClient;

  HabitRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<UserHabitModel>> getUserHabits(String userId) async {
    try {
      // Usar el stored procedure get_user_habits_with_details
      final response = await supabaseClient.rpc(
        'get_user_habits_with_details',
        params: {
          'p_user_id': userId,
          'p_category_id': null, // null para obtener todos los hábitos
        },
      );

      if (response == null) {
        throw ServerException('No data received from Supabase');
      }

      final List<UserHabitModel> userHabits = [];
      for (var item in response) {
        // Mapear los datos del stored procedure al formato esperado por UserHabitModel
        final mappedItem = {
          'id': item['user_habit_id'],
          'user_id': userId,
          'habit_id': item['habit_id'],
          'frequency': item['frequency'],
          'frequency_details': item['frequency_details'],
          'scheduled_time': item['scheduled_time'],
          'notification_time': item['notification_time'],
          'notifications_enabled': item['notifications_enabled'],
          'start_date': item['start_date'],
          'end_date': item['end_date'],
          'is_active': item['is_active'],
          'created_at': item['created_at'],
          'updated_at': item['updated_at'],
          'custom_name':
              item['habit_name'], // Ahora incluye nombres personalizados
          'custom_description': item['habit_description'],
          'is_completed_today': item['is_completed_today'],
          'completion_count_today': item['completion_count_today'],
          'last_completed_at': item['last_completed_at'],
          'streak_count': item['streak_count'],
          'total_completions': item['total_completions'],
          'habits': {
            'id': item['habit_id'],
            'name': item['habit_name'],
            'description': item['habit_description'],
            'category_id': item['category_id'],
            'icon_name': item['habit_icon_name'],
            'icon_color': item['habit_icon_color'],
            'created_at': item['created_at'],
            'updated_at': item['updated_at'],
          },
        };
        userHabits.add(UserHabitModel.fromJson(mappedItem));
      }

      return userHabits;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserHabitModel> getUserHabitById(String userHabitId) async {
    try {
      final response = await supabaseClient
          .from('user_habits')
          .select('''
            *,
            habits (
              id,
              name,
              description,
              category_id,
              icon_name,
              icon_color,
              created_at,
              updated_at
            )
          ''')
          .eq('id', userHabitId)
          .maybeSingle();

      if (response == null) {
        throw ServerException('Habit not found');
      }

      return UserHabitModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getHabitCategories() async {
    try {
      print('🔍 [DEBUG] Fetching categories from Supabase...');
      final response = await supabaseClient.from('categories').select();
      print('🔍 [DEBUG] Raw response from categories: $response');

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      print('✅ [DEBUG] Categories loaded: ${categories.length} categories');
      for (var category in categories) {
        print('   - ${category.name} (${category.id})');
      }

      return categories;
    } catch (e) {
      print('❌ [DEBUG] Error loading categories: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    try {
      // Verificar si el hábito ya existe por ID primero
      final existingById = await supabaseClient
          .from('habits')
          .select('id')
          .eq('id', habit.id)
          .limit(1)
          .maybeSingle();
      
      if (existingById != null) {
        print('🔄 [HABIT] Habit with ID ${habit.id} already exists, skipping insertion');
        return;
      }
      
      // Si no existe por ID, verificar por nombre
      final existingByName = await supabaseClient
          .from('habits')
          .select('id, name')
          .eq('name', habit.name)
          .limit(1);
      
      if (existingByName.isNotEmpty) {
        print('🔄 [HABIT] Habit with name "${habit.name}" already exists (found ${existingByName.length} duplicates), skipping insertion');
        return;
      }
      
      // Solo insertar si no existe ni por ID ni por nombre
      await supabaseClient.from('habits').insert(habit.toJson());
      print('✅ [HABIT] Successfully added habit: ${habit.name} (${habit.id})');
      
    } catch (e) {
      print('❌ [HABIT] Error adding habit ${habit.name}: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    try {
      await supabaseClient.from('habits').delete().eq('id', habitId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserHabit(
    String userHabitId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await supabaseClient
          .from('user_habits')
          .update(updates)
          .eq('id', userHabitId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteUserHabit(String userHabitId) async {
    try {
      // Eliminar en cascada: primero los logs, luego el user_habit
      await supabaseClient
          .from('habit_logs')
          .delete()
          .eq('user_habit_id', userHabitId);

      await supabaseClient.from('user_habits').delete().eq('id', userHabitId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logHabitCompletion(String habitId, DateTime date) async {
    try {
      // habitId is actually user_habit_id in this context
      await supabaseClient.from('user_habit_logs').insert({
        'user_habit_id': habitId,
        'completed_at': date.toIso8601String(),
        'status': 'completed',
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HabitModel>> getHabitSuggestions({
    String? userId,
    String? categoryId,
    int? limit,
  }) async {
    try {
      print('DEBUG getHabitSuggestions - params: userId=' + (userId ?? 'null') + ', categoryId=' + (categoryId ?? 'null') + ', limit=' + ((limit ?? 10).toString()));
      // Llamar al stored procedure get_popular_habit_suggestions
      final response = await supabaseClient.rpc(
        'get_popular_habit_suggestions',
        params: {
          'p_user_id': userId,
          'p_category_id': categoryId,
          'p_limit': limit ?? 10,
        },
      );

      if (response == null) {
        throw ServerException('No data received from Supabase');
      }

      final list = (response as List)
          .map((json) {
            try {
              print('DEBUG getHabitSuggestions - processing item: ' + json.toString());
              return HabitModel.fromJson(json);
            } catch (e) {
              print('DEBUG getHabitSuggestions - error processing item: $e');
              print('DEBUG getHabitSuggestions - problematic json: ' + json.toString());
              throw e;
            }
          })
          .toList();
      print('DEBUG getHabitSuggestions - received count: ' + list.length.toString());
      return list;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<UserHabitModel>> getDashboardHabits(
    String userId,
    int limit,
    bool includeCompletionStatus,
  ) async {
    try {
      // Usar el stored procedure get_dashboard_habits para obtener información completa
      final response = await supabaseClient.rpc(
        'get_dashboard_habits',
        params: {
          'p_user_id': userId,
          'p_date': DateTime.now().toIso8601String().split(
            'T',
          )[0], // Solo la fecha
        },
      );

      if (response == null) {
        throw ServerException('No data received from Supabase');
      }

      final List<UserHabitModel> userHabits = [];
      for (var item in response) {
        // Mapear los datos del stored procedure al formato esperado por UserHabitModel
        final mappedItem = {
          'id': item['user_habit_id'],
          'user_id': userId,
          'habit_id': item['habit_id'],
          'frequency': item['frequency'],
          'frequency_details': item['frequency_details'],
          'scheduled_time': item['scheduled_time'],
          'notification_time': item['notification_time'],
          'notifications_enabled': item['notifications_enabled'],
          'start_date': item['start_date'],
          'end_date': item['end_date'],
          'is_active': item['is_active'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'custom_name': item['habit_name'],
          'custom_description': item['habit_description'],
          'is_completed_today': item['is_completed_today'],
          'completion_count_today': item['completion_count_today'],
          'last_completed_at': item['last_completed_at'],
          'streak_count': item['streak_count'],
          'total_completions': item['total_completions'],
          'habits': {
            'id': item['habit_id'],
            'name': item['habit_name'],
            'description': item['habit_description'],
            'category_id': item['category_id'],
            'icon_name': item['habit_icon_name'],
            'icon_color': item['habit_icon_color'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        };
        userHabits.add(UserHabitModel.fromJson(mappedItem));
      }

      // Aplicar límite si se especifica
      if (limit > 0 && userHabits.length > limit) {
        return userHabits.take(limit).toList();
      }

      return userHabits;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HabitBreakdownModel>> getMonthlyHabitsBreakdown(
    String userId,
    int year,
    int month,
  ) async {
    try {
      // Llamar al stored procedure get_monthly_habits_breakdown
      final response = await supabaseClient.rpc(
        'get_monthly_habits_breakdown',
        params: {'p_user_id': userId, 'p_year': year, 'p_month': month},
      );

      if (response == null) {
        throw ServerException('No data received from Supabase');
      }

      return (response as List)
          .map((json) => HabitBreakdownModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HabitStatisticsModel>> getHabitStatistics({
    required String userId,
    required int year,
    required int month,
  }) async {
    return await _retryWithBackoff(() async {
      try {
        print('HabitRemoteDataSource: Calling get_habit_statistics with params: userId=$userId, year=$year, month=$month');
        
        // Llamar al stored procedure get_habit_statistics
        final response = await supabaseClient.rpc(
          'get_habit_statistics',
          params: {'p_user_id': userId, 'p_year': year, 'p_month': month},
        );

        print('HabitRemoteDataSource: get_habit_statistics response: $response');

        if (response == null) {
          print('HabitRemoteDataSource: No data received from get_habit_statistics');
          throw ServerException('No data received from Supabase');
        }

        final result = (response as List)
            .map((json) => HabitStatisticsModel.fromJson(json))
            .toList();
        
        print('HabitRemoteDataSource: Successfully parsed ${result.length} habit statistics');
        return result;
      } on PostgrestException catch (e) {
        print('HabitRemoteDataSource: PostgrestException in get_habit_statistics - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}');
        throw ServerException('PostgrestException: ${e.message} (Code: ${e.code})');
      } catch (e) {
        print('HabitRemoteDataSource: General exception in get_habit_statistics: $e');
        throw ServerException(e.toString());
      }
    });
  }

  @override
  Future<List<CategoryEvolutionModel>> getCategoryEvolution({
    required String userId,
    required int year,
    required int month,
  }) async {
    return await _retryWithBackoff(() async {
      try {
        print('HabitRemoteDataSource: Calling get_category_evolution with params: userId=$userId, year=$year, month=$month');
        
        // Llamar al stored procedure get_category_evolution
        final response = await supabaseClient.rpc(
          'get_category_evolution',
          params: {'p_user_id': userId, 'p_year': year, 'p_month': month},
        );

        print('HabitRemoteDataSource: get_category_evolution response: $response');

        if (response == null) {
          print('HabitRemoteDataSource: No data received from get_category_evolution');
          throw ServerException('No data received from Supabase');
        }

        final result = (response as List)
            .map((json) => CategoryEvolutionModel.fromJson(json))
            .toList();
        
        print('HabitRemoteDataSource: Successfully parsed ${result.length} category evolution items');
        return result;
      } on PostgrestException catch (e) {
        print('HabitRemoteDataSource: PostgrestException in get_category_evolution - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}');
        throw ServerException('PostgrestException: ${e.message} (Code: ${e.code})');
      } catch (e) {
        print('HabitRemoteDataSource: General exception in get_category_evolution: $e');
        throw ServerException(e.toString());
      }
    });
  }

  /// Función de retry con backoff exponencial
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }

        print('HabitRemoteDataSource: Retry attempt $attempt/$maxRetries after error: $e');
        
        // Solo hacer retry en errores temporales
        if (e is PostgrestException && 
            (e.code == 'PGRST202' || e.code == 'PGRST301' || e.message.contains('timeout'))) {
          await Future.delayed(delay);
          delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Max retries exceeded');
  }
}
