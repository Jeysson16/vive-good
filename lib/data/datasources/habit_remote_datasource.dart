import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/data/models/category_model.dart';
import 'package:vive_good_app/data/models/habit_breakdown_model.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/models/user_habit_model.dart';

abstract class HabitRemoteDataSource {
  Future<List<UserHabitModel>> getUserHabits(String userId);
  Future<List<CategoryModel>> getHabitCategories();
  Future<void> addHabit(HabitModel habit);
  Future<void> deleteHabit(String habitId);
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
        throw ServerFailure('No data received from Supabase');
      }

      final List<UserHabitModel> userHabits = [];
      for (var item in response) {
        // Mapear los datos del stored procedure al formato esperado por UserHabitModel
        final mappedItem = {
          'id': item['user_habit_id'],
          'user_id': userId,
          'habit_id': item['habit_id'],
          'frequency': item['frequency'],
          'scheduled_time': item['scheduled_time'],
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
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getHabitCategories() async {
    try {
      final response = await supabaseClient.from('categories').select();

      if (response == null) {
        throw ServerFailure('No data received from Supabase');
      }

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    try {
      await supabaseClient.from('habits').insert(habit.toJson());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    try {
      await supabaseClient.from('habits').delete().eq('id', habitId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logHabitCompletion(String habitId, DateTime date) async {
    try {
      await supabaseClient.from('habit_logs').insert({
        'habit_id': habitId,
        'completion_date': date.toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<HabitModel>> getHabitSuggestions({
    String? userId,
    String? categoryId,
    int? limit,
  }) async {
    try {
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
        throw ServerFailure('No data received from Supabase');
      }

      return (response as List)
          .map((json) => HabitModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
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
      print('🔍 DATASOURCE DEBUG: Calling get_dashboard_habits with userId: $userId');
      final response = await supabaseClient.rpc(
        'get_dashboard_habits',
        params: {
          'p_user_id': userId,
          'p_date': DateTime.now().toIso8601String().split('T')[0], // Solo la fecha
        },
      );
      
      print('🔍 DATASOURCE DEBUG: Raw response from get_dashboard_habits: $response');
      print('🔍 DATASOURCE DEBUG: Response type: ${response.runtimeType}');
      print('🔍 DATASOURCE DEBUG: Response length: ${response?.length ?? 0}');

      if (response == null) {
        throw ServerFailure('No data received from Supabase');
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
            'icon_name': item['category_icon'],
            'icon_color': item['category_color'],
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
      throw ServerFailure(e.toString());
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
        throw ServerFailure('No data received from Supabase');
      }

      return (response as List)
          .map((json) => HabitBreakdownModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
