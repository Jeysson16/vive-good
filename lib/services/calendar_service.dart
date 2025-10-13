import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar operaciones CRUD de eventos del calendario con Supabase
class CalendarService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'calendar_events';

  /// Obtiene las actividades pendientes del usuario actual
  static Future<List<Map<String, dynamic>>> getPendingActivities({
    int? limit,
    DateTime? fromDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final now = DateTime.now();
      final startDate = fromDate ?? now;

      var query = _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user.id)
          .eq('is_completed', false)
          .gte('event_date', startDate.toIso8601String())
          .order('event_date', ascending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener actividades pendientes: $e');
    }
  }

  /// Obtiene las actividades del día actual
  static Future<List<Map<String, dynamic>>> getTodayActivities() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user.id)
          .gte('event_date', startOfDay.toIso8601String())
          .lte('event_date', endOfDay.toIso8601String())
          .order('event_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener actividades de hoy: $e');
    }
  }

  /// Crea una nueva actividad/evento
  static Future<Map<String, dynamic>?> createActivity({
    required String title,
    required DateTime eventDate,
    String? description,
    String? eventType,
    String? location,
    bool isCompleted = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final activityData = {
        'user_id': user.id,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String(),
        'event_type': eventType ?? 'general',
        'location': location,
        'is_completed': isCompleted,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_tableName)
          .insert(activityData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al crear actividad: $e');
    }
  }

  /// Marca una actividad como completada
  static Future<Map<String, dynamic>?> markActivityAsCompleted(String activityId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from(_tableName)
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', activityId)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al marcar actividad como completada: $e');
    }
  }

  /// Actualiza una actividad existente
  static Future<Map<String, dynamic>?> updateActivity({
    required String activityId,
    String? title,
    String? description,
    DateTime? eventDate,
    String? eventType,
    String? location,
    bool? isCompleted,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (eventDate != null) updateData['event_date'] = eventDate.toIso8601String();
      if (eventType != null) updateData['event_type'] = eventType;
      if (location != null) updateData['location'] = location;
      if (isCompleted != null) {
        updateData['is_completed'] = isCompleted;
        if (isCompleted) {
          updateData['completed_at'] = DateTime.now().toIso8601String();
        }
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', activityId)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al actualizar actividad: $e');
    }
  }

  /// Elimina una actividad
  static Future<void> deleteActivity(String activityId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', activityId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error al eliminar actividad: $e');
    }
  }

  /// Obtiene estadísticas de actividades
  static Future<Map<String, dynamic>> getActivitiesStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      var query = _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user.id);

      if (fromDate != null) {
        query = query.gte('event_date', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('event_date', toDate.toIso8601String());
      }

      final response = await query;
      final activities = List<Map<String, dynamic>>.from(response);

      final stats = <String, dynamic>{
        'total_activities': activities.length,
        'completed_activities': activities.where((a) => a['is_completed'] == true).length,
        'pending_activities': activities.where((a) => a['is_completed'] == false).length,
        'completion_rate': 0.0,
        'activities_by_type': <String, int>{},
      };

      if (activities.isNotEmpty) {
        stats['completion_rate'] = 
            (stats['completed_activities'] as int) / activities.length * 100;

        // Contar por tipo
        final typeCounts = <String, int>{};
        for (final activity in activities) {
          final type = activity['event_type'] as String? ?? 'general';
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
        stats['activities_by_type'] = typeCounts;
      }

      return stats;
    } catch (e) {
      throw Exception('Error al obtener estadísticas de actividades: $e');
    }
  }

  /// Obtiene las próximas actividades (siguientes 7 días)
  static Future<List<Map<String, dynamic>>> getUpcomingActivities({int? limit}) async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return getPendingActivities(
      fromDate: now,
      limit: limit,
    );
  }
}