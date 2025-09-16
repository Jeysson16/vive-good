import 'package:vive_good_app/data/models/user_habit_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/models/category_model.dart';
import 'package:vive_good_app/data/models/habit_breakdown_model.dart';

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
      final response = await supabaseClient
          .from('user_habits')
          .select('*, habits(*)')
          .eq('user_id', userId);

      if (response == null) {
        throw ServerFailure('No data received from Supabase');
      }

      final List<UserHabitModel> userHabits = [];
      for (var item in response) {
        userHabits.add(UserHabitModel.fromJson(item));
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
      var query = supabaseClient
          .from('user_habits')
          .select('*, habits(*)')
          .eq('user_id', userId)
          .limit(limit);

      // TODO: Implement logic for includeCompletionStatus if needed, e.g., joining with habit_logs

      final response = await query;

      if (response == null) {
        throw ServerFailure('No data received from Supabase');
      }

      final List<UserHabitModel> userHabits = [];
      for (var item in response) {
        userHabits.add(UserHabitModel.fromJson(item));
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
        params: {
          'p_user_id': userId,
          'p_year': year,
          'p_month': month,
        },
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
