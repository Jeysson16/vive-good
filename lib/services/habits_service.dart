import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio simplificado para manejar operaciones de hábitos del usuario
class HabitsService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene los hábitos activos del usuario actual
  static Future<List<Map<String, dynamic>>> getUserActiveHabits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('user_habits')
          .select('''
            id,
            habit_id,
            custom_name,
            custom_description,
            frequency,
            scheduled_time,
            start_date,
            end_date,
            is_active,
            created_at,
            habits (
              id,
              name,
              description,
              category_id,
              icon_name,
              icon_color
            )
          ''')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener hábitos activos: $e');
    }
  }

  /// Crea un nuevo hábito personalizado para el usuario
  static Future<Map<String, dynamic>?> createCustomHabit({
    required String habitName,
    required String frequency,
    String? description,
    String? scheduledTime,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final habitData = {
        'user_id': user.id,
        'custom_name': habitName,
        'custom_description': description,
        'frequency': frequency,
        'scheduled_time': scheduledTime,
        'start_date': (startDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_habits')
          .insert(habitData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al crear hábito personalizado: $e');
    }
  }

  /// Agrega un hábito existente de la biblioteca al usuario
  static Future<Map<String, dynamic>?> addHabitFromLibrary({
    required String habitId,
    required String frequency,
    String? customName,
    String? scheduledTime,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final habitData = {
        'user_id': user.id,
        'habit_id': habitId,
        'custom_name': customName,
        'frequency': frequency,
        'scheduled_time': scheduledTime,
        'start_date': (startDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_habits')
          .insert(habitData)
          .select('''
            *,
            habits (
              id,
              name,
              description,
              category_id,
              icon_name,
              icon_color
            )
          ''')
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al agregar hábito de la biblioteca: $e');
    }
  }

  /// Obtiene sugerencias de hábitos que el usuario no tiene
  static Future<List<Map<String, dynamic>>> getHabitSuggestions({
    String? categoryId,
    int limit = 10,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase.rpc(
        'get_popular_habit_suggestions',
        params: {
          'p_user_id': user.id,
          'p_category_id': categoryId,
          'p_limit': limit,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      throw Exception('Error al obtener sugerencias de hábitos: $e');
    }
  }

  /// Marca un hábito como completado
  static Future<Map<String, dynamic>?> markHabitAsCompleted({
    required String userHabitId,
    DateTime? completedAt,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final logData = {
        'user_id': user.id,
        'user_habit_id': userHabitId,
        'completed_at': (completedAt ?? DateTime.now()).toIso8601String(),
        'status': 'completed',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_habit_logs')
          .insert(logData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al marcar hábito como completado: $e');
    }
  }

  /// Obtiene los hábitos completados hoy
  static Future<List<Map<String, dynamic>>> getTodayCompletedHabits() async {
    try {
      print('🔍 DEBUG HABITS_SERVICE - Iniciando getTodayCompletedHabits()');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ DEBUG HABITS_SERVICE - Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }

      print('✅ DEBUG HABITS_SERVICE - Usuario autenticado: ${user.id}');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      print('🔍 DEBUG HABITS_SERVICE - Buscando logs entre:');
      print('   Inicio del día: ${startOfDay.toIso8601String()}');
      print('   Fin del día: ${endOfDay.toIso8601String()}');

      final response = await _supabase
          .from('user_habit_logs')
          .select('''
            id,
            user_habit_id,
            completed_at,
            status,
            notes,
            user_habits!inner (
              id,
              user_id,
              custom_name,
              habits (
                id,
                name,
                icon_name,
                icon_color
              )
            )
          ''')
          .eq('user_habits.user_id', user.id)
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String())
          .lte('completed_at', endOfDay.toIso8601String())
          .order('completed_at', ascending: false);

      print('✅ DEBUG HABITS_SERVICE - Respuesta recibida: ${response.length} registros');
      print('📋 DEBUG HABITS_SERVICE - Datos completos: $response');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ DEBUG HABITS_SERVICE - Error: $e');
      throw Exception('Error al obtener hábitos completados hoy: $e');
    }
  }

  /// Obtiene estadísticas rápidas de hábitos del usuario
  static Future<Map<String, dynamic>> getHabitsStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener hábitos activos
      final activeHabits = await getUserActiveHabits();

      // Obtener hábitos completados hoy
      final completedToday = await getTodayCompletedHabits();

      // Obtener racha actual
      final streakResponse = await _supabase.rpc('get_user_streak', params: {
        'p_user_id': user.id,
      });

      final currentStreak = streakResponse ?? 0;

      // Calcular porcentaje de completitud del día
      final totalActiveHabits = activeHabits.length;
      final completedTodayCount = completedToday.length;
      final todayCompletionPercentage = totalActiveHabits > 0 
          ? (completedTodayCount / totalActiveHabits * 100).round()
          : 0;

      return {
        'total_active_habits': totalActiveHabits,
        'completed_today': completedTodayCount,
        'today_completion_percentage': todayCompletionPercentage,
        'current_streak': currentStreak,
        'pending_today': totalActiveHabits - completedTodayCount,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de hábitos: $e');
    }
  }

  /// Desactiva un hábito del usuario
  static Future<void> deactivateHabit(String userHabitId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('user_habits')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userHabitId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error al desactivar hábito: $e');
    }
  }

  /// Obtiene las categorías de hábitos disponibles
  static Future<List<Map<String, dynamic>>> getHabitCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name, color, icon')
          .eq('is_active', true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener categorías de hábitos: $e');
    }
  }
}