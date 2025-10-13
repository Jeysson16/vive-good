import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio simplificado para obtener el progreso del usuario para acciones rápidas
class UserProgressService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene el progreso del día actual del usuario
  static Future<Map<String, dynamic>> getTodayProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Obtener hábitos completados hoy
      final habitsCompletedToday = await _supabase
          .from('user_habit_logs')
          .select('id, user_habit_id')
          .eq('user_id', user.id)
          .gte('completed_at', startOfDay.toIso8601String())
          .lte('completed_at', endOfDay.toIso8601String());

      // Obtener total de hábitos activos del usuario
      final totalActiveHabits = await _supabase
          .from('user_habits')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Obtener actividades pendientes para hoy
      final pendingActivitiesToday = await _supabase
          .from('calendar_events')
          .select('id, title')
          .eq('user_id', user.id)
          .eq('is_completed', false)
          .gte('event_date', startOfDay.toIso8601String())
          .lte('event_date', endOfDay.toIso8601String());

      // Obtener síntomas registrados hoy
      final symptomsToday = await _supabase
          .from('user_symptoms')
          .select('id, symptom_name, severity')
          .eq('user_id', user.id)
          .gte('occurred_at', startOfDay.toIso8601String())
          .lte('occurred_at', endOfDay.toIso8601String());

      // Calcular porcentaje de progreso
      final completedHabitsCount = habitsCompletedToday.length;
      final totalHabitsCount = totalActiveHabits.length;
      final progressPercentage = totalHabitsCount > 0 
          ? (completedHabitsCount / totalHabitsCount * 100).round()
          : 0;

      return {
        'date': now.toIso8601String(),
        'completed_habits': completedHabitsCount,
        'total_habits': totalHabitsCount,
        'progress_percentage': progressPercentage,
        'pending_activities': pendingActivitiesToday.length,
        'symptoms_registered': symptomsToday.length,
        'habits_completed_today': habitsCompletedToday,
        'pending_activities_today': pendingActivitiesToday,
        'symptoms_today': symptomsToday,
      };
    } catch (e) {
      throw Exception('Error al obtener progreso de hoy: $e');
    }
  }

  /// Obtiene el progreso de la semana actual
  static Future<Map<String, dynamic>> getWeekProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfWeekDay.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // Obtener hábitos completados esta semana
      final habitsCompletedWeek = await _supabase
          .from('user_habit_logs')
          .select('id, completed_at, user_habit_id')
          .eq('user_id', user.id)
          .gte('completed_at', startOfWeekDay.toIso8601String())
          .lte('completed_at', endOfWeek.toIso8601String());

      // Obtener total de hábitos activos del usuario
      final totalActiveHabits = await _supabase
          .from('user_habits')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Calcular progreso por día de la semana
      final dailyProgress = <String, int>{};
      final daysOfWeek = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      
      for (int i = 0; i < 7; i++) {
        final day = startOfWeekDay.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
        
        final habitsForDay = habitsCompletedWeek.where((habit) {
          final completedAt = DateTime.parse(habit['completed_at']);
          return completedAt.isAfter(dayStart) && completedAt.isBefore(dayEnd);
        }).length;
        
        dailyProgress[daysOfWeek[i]] = habitsForDay;
      }

      // Calcular porcentaje de progreso semanal
      final totalPossibleHabits = totalActiveHabits.length * 7;
      final totalCompletedHabits = habitsCompletedWeek.length;
      final weekProgressPercentage = totalPossibleHabits > 0 
          ? (totalCompletedHabits / totalPossibleHabits * 100).round()
          : 0;

      return {
        'week_start': startOfWeekDay.toIso8601String(),
        'week_end': endOfWeek.toIso8601String(),
        'total_completed_habits': totalCompletedHabits,
        'total_possible_habits': totalPossibleHabits,
        'week_progress_percentage': weekProgressPercentage,
        'daily_progress': dailyProgress,
        'active_habits_count': totalActiveHabits.length,
      };
    } catch (e) {
      throw Exception('Error al obtener progreso de la semana: $e');
    }
  }

  /// Obtiene estadísticas rápidas del usuario
  static Future<Map<String, dynamic>> getQuickStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Obtener racha actual (días consecutivos con al menos un hábito completado)
      final streakResponse = await _supabase.rpc('get_user_streak', params: {
        'p_user_id': user.id,
      });

      final currentStreak = streakResponse ?? 0;

      // Obtener total de hábitos activos
      final totalActiveHabits = await _supabase
          .from('user_habits')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Obtener actividades pendientes totales
      final pendingActivities = await _supabase
          .from('calendar_events')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_completed', false)
          .gte('event_date', now.toIso8601String());

      // Obtener síntomas del mes actual
      final symptomsThisMonth = await _supabase
          .from('user_symptoms')
          .select('id')
          .eq('user_id', user.id)
          .gte('occurred_at', startOfMonth.toIso8601String());

      return {
        'current_streak': currentStreak,
        'active_habits': totalActiveHabits.length,
        'pending_activities': pendingActivities.length,
        'symptoms_this_month': symptomsThisMonth.length,
        'last_updated': now.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas rápidas: $e');
    }
  }

  /// Obtiene el resumen completo del progreso del usuario
  static Future<Map<String, dynamic>> getProgressSummary() async {
    try {
      final todayProgress = await getTodayProgress();
      final weekProgress = await getWeekProgress();
      final quickStats = await getQuickStats();

      return {
        'today': todayProgress,
        'week': weekProgress,
        'stats': quickStats,
        'summary_generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error al obtener resumen de progreso: $e');
    }
  }
}