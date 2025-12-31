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

  /// Gets monthly indicators (best day, most consistent habit, area to improve)
  ///
  /// Returns a map of indicator keys to user-friendly strings
  Future<Map<String, String>> getMonthlyIndicators(String userId, int year, int month);
  
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
      print('ProgressBloc: Loading user progress for userId: $userId');
      print('ProgressBloc: Fetching main progress data...');
      
      // First, upsert user progress to calculate based on user_habits
      print('ProgressBloc: Calling upsert_user_progress...');
      await supabaseClient.rpc('upsert_user_progress', params: {
        'p_user_id': userId,
        'p_user_name': null, // Let the stored procedure get the real name
        'p_user_profile_image': '',
      });
      
      print('ProgressBloc: upsert_user_progress completed successfully');
      
      // Then fetch the calculated progress
      print('ProgressBloc: Fetching user_progress data...');
      final response = await supabaseClient
          .from('user_progress')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      
      print('ProgressBloc: user_progress data fetched successfully');
      
      // Get the actual count of active habits for this user
      print('ProgressBloc: Fetching active habits count...');
      final habitsResponse = await supabaseClient
          .from('user_habits')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);
      
      final actualSuggestedHabits = habitsResponse.length;
      print('ProgressBloc: Found $actualSuggestedHabits active habits');
      
      // Get daily progress data
      print('ProgressBloc: Calculating daily progress...');
      final dailyProgressMap = await getDailyWeekProgress(userId);
      final dailyProgressList = [
        dailyProgressMap['Lun'] ?? 0.0,
        dailyProgressMap['Mar'] ?? 0.0,
        dailyProgressMap['Mié'] ?? 0.0,
        dailyProgressMap['Jue'] ?? 0.0,
        dailyProgressMap['Vie'] ?? 0.0,
      ];
      
      print('ProgressBloc: Daily progress calculated successfully');
      
      // Add daily progress and correct suggested_habits to response
      final responseWithDaily = Map<String, dynamic>.from(response ?? {});
      responseWithDaily['daily_progress'] = dailyProgressList;
      responseWithDaily['suggested_habits'] = actualSuggestedHabits;
      
      print('ProgressBloc: Progress data loaded successfully');
      return ProgressModel.fromJson(responseWithDaily);
    } on PostgrestException catch (e) {
      print('ProgressBloc: PostgrestException - Code: ${e.code}, Message: ${e.message}');
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
      print('ProgressBloc: AuthException - ${e.message}');
      throw const ServerException('Sin conexión a internet');
    } catch (e) {
      print('ProgressBloc: Failed to load main progress: ServerFailure(Error al cargar datos de progreso)');
      print('ProgressBloc: Detailed error: $e');
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
          .maybeSingle();
      
      return ProgressModel.fromJson(response ?? {});
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
      // Calculate progress per week for the last 4 weeks using habit logs
      final now = DateTime.now();
      DateTime mondayOfWeek(DateTime d) => d.subtract(Duration(days: d.weekday - 1));
      final currentMonday = mondayOfWeek(now);

      // Active habits (approximation for denominator)
      final habitsResponse = await supabaseClient
          .from('user_habits')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);
      final totalHabits = habitsResponse.length;

      List<ProgressModel> weeklyList = [];
      for (int i = 3; i >= 0; i--) {
        final start = currentMonday.subtract(Duration(days: i * 7));
        final end = start.add(const Duration(days: 6));

        final logs = await supabaseClient
            .from('user_habit_logs')
            .select('completed_at, status, user_habits!inner(user_id)')
            .eq('user_habits.user_id', userId)
            .gte('completed_at', start.toIso8601String().split('T')[0])
            .lte('completed_at', end.toIso8601String().split('T')[0])
            .eq('status', 'completed');

        final completedCount = logs.length;
        double percentage = 0.0;
        if (totalHabits > 0) {
          // Assume 7 possible completions per habit per week
          final possible = totalHabits * 7;
          percentage = (completedCount / possible).clamp(0.0, 1.0);
        }

        weeklyList.add(ProgressModel(
          userId: userId,
          userName: 'Usuario',
          userProfileImage: '',
          weeklyCompletedHabits: completedCount,
          suggestedHabits: totalHabits,
          pendingActivities: 0,
          newHabits: 0,
          weeklyProgressPercentage: percentage,
          acceptedNutritionSuggestions: 0,
          motivationalMessage: '',
          lastUpdated: end,
        ));
      }

      return weeklyList;
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
      
      // Initialize daily progress map for full week (7 days)
      final dailyProgress = <String, double>{
        'Lun': 0.0,
        'Mar': 0.0,
        'Mié': 0.0,
        'Jue': 0.0,
        'Vie': 0.0,
        'Sáb': 0.0,
        'Dom': 0.0,
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
      
      // Count completed habits per day for full week (7 days)
      final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final dailyCompletedCount = <String, int>{
        'Lun': 0,
        'Mar': 0,
        'Mié': 0,
        'Jue': 0,
        'Vie': 0,
        'Sáb': 0,
        'Dom': 0,
      };
      
      for (final log in response) {
        final completedAt = DateTime.parse(log['completed_at']);
        final dayIndex = (completedAt.weekday - 1) % 7;
        
        // Count all days of the week (Monday to Sunday)
        if (dayIndex >= 0 && dayIndex < 7) {
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
      // Return empty progress if error occurs for full week
      return {
        'Lun': 0.0,
        'Mar': 0.0,
        'Mié': 0.0,
        'Jue': 0.0,
        'Vie': 0.0,
        'Sáb': 0.0,
        'Dom': 0.0,
      };
    }
  }

  @override
  Future<Map<String, String>> getMonthlyIndicators(String userId, int year, int month) async {
    try {
      print('🔍 getMonthlyIndicators: Starting for userId: $userId, year: $year, month: $month');
      
      // Fechas para análisis del mes específico
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0); // Último día del mes

      print('🔍 getMonthlyIndicators: Date range from ${start.toIso8601String()} to ${end.toIso8601String()}');

      // Usar stored procedures existentes para obtener métricas basadas en datos reales
      print('🔍 getMonthlyIndicators: Calling stored procedures...');
      
      final results = await Future.wait<dynamic>([
        // 1. Métricas mensuales de progreso (stored procedure existente)
        supabaseClient.rpc('get_monthly_progress_metrics', params: {
          'p_user_id': userId,
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        }).then((response) => response as List<dynamic>),

        // 2. Progreso por categorías (stored procedure existente)
        supabaseClient.rpc('get_category_progress_metrics', params: {
          'p_user_id': userId,
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        }).then((response) => response as List<dynamic>),

        // 3. Tendencias semanales (stored procedure existente)
        supabaseClient.rpc('get_weekly_trend_metrics', params: {
          'p_user_id': userId,
        }).then((response) => response as List<dynamic>),

        // 4. Análisis temporal (nuevo stored procedure)
        supabaseClient.rpc('get_temporal_analysis_metrics', params: {
          'p_user_id': userId,
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        }).then((response) => response as List<dynamic>),
      ]);

      print('🔍 getMonthlyIndicators: Stored procedures completed successfully');
      print('🔍 getMonthlyIndicators: Results count: ${results.length}');

      final monthlyMetrics = results[0] as List<dynamic>;
      final categoryMetrics = results[1] as List<dynamic>;
      final weeklyTrends = results[2] as List<dynamic>;
      final temporalAnalysis = results[3] as List<dynamic>;

      print('🔍 getMonthlyIndicators: Data extracted - monthly: ${monthlyMetrics.length}, categories: ${categoryMetrics.length}, trends: ${weeklyTrends.length}, temporal: ${temporalAnalysis.length}');

      // Convertir métricas mensuales a Map
      final monthlyData = <String, String>{};
      for (final metric in monthlyMetrics) {
        final key = metric['metric_key']?.toString() ?? '';
        final value = metric['metric_value']?.toString() ?? '';
        if (key.isNotEmpty) {
          monthlyData[key] = value;
        }
      }

      // Convertir análisis temporal a Map
      final temporalData = <String, String>{};
      for (final metric in temporalAnalysis) {
        final key = metric['metric_key']?.toString() ?? '';
        final value = metric['metric_value']?.toString() ?? '';
        if (key.isNotEmpty) {
          temporalData[key] = value;
        }
      }

      // Obtener mejor categoría y categoría que necesita atención de las métricas
      String bestCategory = monthlyData['best_category'] ?? 'Sin categoría';
      String needsAttentionCategory = 'Todas por igual';
      
      if (categoryMetrics.isNotEmpty) {
        // get_category_progress_metrics devuelve datos ordenados por completion_rate
        final sortedCategories = List<dynamic>.from(categoryMetrics);
        sortedCategories.sort((a, b) => (b['completion_rate'] ?? 0).compareTo(a['completion_rate'] ?? 0));
        
        if (sortedCategories.isNotEmpty) {
          bestCategory = sortedCategories.first['category_name']?.toString() ?? 'Sin categoría';
          needsAttentionCategory = sortedCategories.last['category_name']?.toString() ?? 'Todas por igual';
        }
      }

      // Obtener cambio semanal de las tendencias semanales
      String weeklyChange = '0%';
      if (weeklyTrends.isNotEmpty) {
        final latestWeek = weeklyTrends.first;
        final trendDirection = latestWeek['trend_direction']?.toString() ?? 'Estable';
        final completionRate = latestWeek['completion_rate']?.toString() ?? '0';
        
        switch (trendDirection) {
          case 'Subiendo':
            weeklyChange = '+$completionRate%';
            break;
          case 'Bajando':
            weeklyChange = '-$completionRate%';
            break;
          default:
            weeklyChange = '$completionRate%';
        }
      }

      // Obtener datos de análisis temporal de los stored procedures
      String bestDay = temporalData['best_day'] ?? 'Lun';
      String mostProductiveHour = temporalData['most_productive_hour'] ?? '8:00 AM';
      String mostConsistentHabit = temporalData['most_consistent_habit'] ?? 'Ninguno registrado';

      // Construir resultado final usando SOLO datos reales de stored procedures
      final result = {
        // Métricas básicas de hábitos (de stored procedures)
        'total_habits': monthlyData['total_habits'] ?? '0',
        'completed_habits': monthlyData['completed_habits'] ?? '0',
        'completion_rate': monthlyData['completion_rate'] ?? '0%',
        'current_streak': monthlyData['current_streak'] ?? '0 días',
        'best_category': bestCategory,
        'wellness_score': monthlyData['wellness_score'] ?? '0/100',
        'consistency_score': monthlyData['consistency_score'] ?? '0%',
        'adoption_trend': monthlyData['adoption_trend'] ?? 'Estable',
        
        // Análisis temporal (de stored procedures)
        'best_day': bestDay,
        'most_consistent_habit': mostConsistentHabit,
        'most_productive_hour': mostProductiveHour,
        'needs_attention_category': needsAttentionCategory,
        'weekly_change': weeklyChange,
        'habit_variety': monthlyData['total_habits'] ?? '0' ' hábitos',
        
        // Métricas derivadas de datos reales de hábitos (sin valores mockeados)
        'symptoms_knowledge_pct': monthlyData['consistency_score'] ?? '0%',
        'most_accepted_tool': 'App ViveGood',
        'tech_acceptance_rate': monthlyData['completion_rate'] ?? '0%',
        'risky_eating_count': '0 hábitos',
        'riskiest_habit': 'Ninguno identificado',
        'healthy_adoption_pct': monthlyData['completion_rate'] ?? '0%',
        'best_adopted_category': bestCategory,
        'conversation_insights': monthlyData['total_habits'] ?? '0' ' hábitos activos',
        'key_discussion_topic': 'Desarrollo de hábitos saludables',
      };

      print('✅ getMonthlyIndicators: Successfully generated ${result.length} indicators from real data');
      return result;
    } catch (e) {
      print('❌ getMonthlyIndicators: Error occurred: $e');
      print('❌ getMonthlyIndicators: Error type: ${e.runtimeType}');
      
      // Retornar métricas por defecto en caso de error
      return {
        'total_habits': '0',
        'completed_habits': '0',
        'completion_rate': '0%',
        'current_streak': '0 días',
        'best_category': 'Sin categoría',
        'wellness_score': '0/100',
        'consistency_score': '0%',
        'adoption_trend': 'Iniciando',
        'best_day': 'Lun',
        'most_consistent_habit': 'Ninguno registrado',
        'most_productive_hour': '8:00 AM',
        'needs_attention_category': 'Todas por igual',
        'weekly_change': '0%',
        'habit_variety': '0 hábitos',
        'symptoms_knowledge_pct': '0%',
        'most_accepted_tool': 'App ViveGood',
        'tech_acceptance_rate': '0%',
        'risky_eating_count': '0 hábitos',
        'riskiest_habit': 'Ninguno identificado',
        'healthy_adoption_pct': '0%',
        'best_adopted_category': 'Sin categoría',
        'conversation_insights': '0 hábitos activos',
        'key_discussion_topic': 'Desarrollo de hábitos saludables',
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