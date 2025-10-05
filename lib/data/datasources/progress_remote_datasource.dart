import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/progress.dart';

abstract class ProgressRemoteDataSource {
  /// Gets user progress from the remote server
  /// 
  /// Throws [ServerException] for all error codes
  Future<ProgressModel> getUserProgress(String userId);
  
  /// Updates user progress on the remote server
  /// 
  /// Throws [ServerException] for all error codes
  Future<ProgressModel> updateUserProgress(String userId, ProgressModel progress);
  
  /// Gets weekly progress data
  /// 
  /// Throws [ServerException] for all error codes
  Future<ProgressModel> getWeeklyProgress(String userId);
  
  /// Gets monthly progress data
  /// 
  /// Throws [ServerException] for all error codes
  Future<List<ProgressModel>> getMonthlyProgress(String userId);
  
  /// Gets daily progress data for the current week
  /// 
  /// Returns a map with day names as keys and completion percentages as values
  /// Throws [ServerException] for all error codes
  Future<Map<String, double>> getDailyWeekProgress(String userId);
  
  /// Gets user streak from the database
  /// 
  /// Returns the current streak count
  /// Throws [ServerException] for all error codes
  Future<int> getUserStreak(String userId);
}

class ProgressRemoteDataSourceImpl implements ProgressRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  final SupabaseClient supabaseClient;

  ProgressRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'https://api.vivegood.com/v1',
    SupabaseClient? supabaseClient,
  }) : supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<ProgressModel> getUserProgress(String userId) async {
    try {
      // First, upsert user progress to calculate based on user_habits
      await supabaseClient.rpc('upsert_user_progress', params: {
        'p_user_id': userId,
        'p_user_name': 'Usuario',
        'p_user_profile_image': '',
      });
      
      // Then fetch the calculated progress
      final response = await supabaseClient
          .from('user_progress')
          .select('*')
          .eq('user_id', userId)
          .single();
      
      // Get the actual count of active habits for this user
      final habitsResponse = await supabaseClient
          .from('user_habits')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);
      
      final actualSuggestedHabits = habitsResponse.length;
      
      // Get daily progress data
      final dailyProgressMap = await getDailyWeekProgress(userId);
      final dailyProgressList = [
        dailyProgressMap['Lun'] ?? 0.0,
        dailyProgressMap['Mar'] ?? 0.0,
        dailyProgressMap['Mié'] ?? 0.0,
        dailyProgressMap['Jue'] ?? 0.0,
        dailyProgressMap['Vie'] ?? 0.0,
      ];
      
      // Add daily progress and correct suggested_habits to response
      final responseWithDaily = Map<String, dynamic>.from(response);
      responseWithDaily['daily_progress'] = dailyProgressList;
      responseWithDaily['suggested_habits'] = actualSuggestedHabits;
      
      return ProgressModel.fromJson(responseWithDaily);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows returned - user doesn't exist
        throw const ServerException('No se encontraron datos de progreso para este usuario');
      } else if (e.code?.startsWith('08') == true) {
        // Connection error codes
        throw const ServerException('Problema de conexión con el servidor');
      } else {
        throw const ServerException('Error al cargar datos de progreso');
      }
    } on AuthException catch (e) {
      throw const ServerException('Sin conexión a internet');
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw const ServerException('Problema de autenticación');
      } else {
        throw const ServerException('Error al cargar progreso');
      }
    }
  }

  @override
  Future<ProgressModel> updateUserProgress(String userId, ProgressModel progress) async {
    try {
      // Update user progress in Supabase
      final response = await supabaseClient
          .from('user_progress')
          .update({
            'user_name': progress.userName,
            'user_profile_image': progress.userProfileImage,
            'accepted_nutrition_suggestions': progress.acceptedNutritionSuggestions,
            'motivational_message': progress.motivationalMessage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .select()
          .single();
      
      return ProgressModel.fromJson(response);
    } catch (e) {
      throw const ServerException('Error al actualizar progreso');
    }
  }

  @override
  Future<ProgressModel> getWeeklyProgress(String userId) async {
    try {
      // Use the same method as getUserProgress since it calculates weekly data
      return await getUserProgress(userId);
    } catch (e) {
      throw const ServerException('Error al obtener progreso semanal');
    }
  }

  @override
  Future<List<ProgressModel>> getMonthlyProgress(String userId) async {
    try {
      // For monthly progress, we'll return the current progress
      // In a real implementation, you might want to fetch historical data
      final currentProgress = await getUserProgress(userId);
      return [currentProgress];
    } catch (e) {
      throw const ServerException('Error al obtener progreso mensual');
    }
  }

  @override
  Future<Map<String, double>> getDailyWeekProgress(String userId) async {
    try {
      // Get the start and end of the current week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));
      
      // Query habit logs for the current week with JOIN to user_habits
      final response = await supabaseClient
          .from('user_habit_logs')
          .select('completed_at, status, user_habits!inner(user_id)')
          .eq('user_habits.user_id', userId)
          .gte('completed_at', startOfWeek.toIso8601String().split('T')[0])
          .lte('completed_at', endOfWeek.toIso8601String().split('T')[0]);
      
      // Initialize daily progress map
      final dailyProgress = <String, double>{
        'Lun': 0.0,
        'Mar': 0.0,
        'Mié': 0.0,
        'Jue': 0.0,
        'Vie': 0.0,
      };
      
      // Get total active habits for this user
      final habitsResponse = await supabaseClient
          .from('user_habits')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);
      
      final totalHabits = habitsResponse.length;
      
      if (totalHabits == 0) {
        return dailyProgress;
      }
      
      // Count completed habits per day
      final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
      final dailyCompletedCount = <String, int>{
        'Lun': 0,
        'Mar': 0,
        'Mié': 0,
        'Jue': 0,
        'Vie': 0,
      };
      
      for (final log in response) {
        final completedAt = DateTime.parse(log['completed_at']);
        final dayIndex = (completedAt.weekday - 1) % 7;
        
        // Only count weekdays (Monday to Friday)
        if (dayIndex < 5) {
          final dayName = dayNames[dayIndex];
          
          // Check if status indicates completion
          if (log['status'] == 'completed') {
            dailyCompletedCount[dayName] = dailyCompletedCount[dayName]! + 1;
          }
        }
      }
      
      // Calculate completion percentage for each day
      for (final dayName in dayNames) {
        final completedCount = dailyCompletedCount[dayName]!;
        dailyProgress[dayName] = (completedCount / totalHabits).clamp(0.0, 1.0);
      }
      
      return dailyProgress;
    } catch (e) {
      // Return empty progress if error occurs
      return {
        'Lun': 0.0,
        'Mar': 0.0,
        'Mié': 0.0,
        'Jue': 0.0,
        'Vie': 0.0,
      };
    }
  }

  @override
  Future<int> getUserStreak(String userId) async {
    try {
      // Call the calculate_user_streak function from the database
      final response = await supabaseClient.rpc('calculate_user_streak', params: {
        'p_user_id': userId,
      });
      
      return response as int? ?? 0;
    } catch (e) {
      // Return 0 if error occurs
      return 0;
    }
  }

  ProgressModel _getDefaultProgress(String userId) {
    return ProgressModel(
      userId: userId,
      userName: 'Usuario',
      userProfileImage: '',
      weeklyCompletedHabits: 0,
      suggestedHabits: 0,
      pendingActivities: 0,
      newHabits: 0,
      weeklyProgressPercentage: 0.0,
      acceptedNutritionSuggestions: 0,
      motivationalMessage: 'Comienza tu viaje hacia una vida más saludable',
      lastUpdated: DateTime.now(),
    );
  }
}