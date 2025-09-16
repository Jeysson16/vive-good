import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CalendarRemoteDataSource {
  Future<List<Map<String, dynamic>>> getCalendarEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<Map<String, dynamic>> createCalendarEvent(Map<String, dynamic> eventData);
  
  Future<Map<String, dynamic>> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> eventData,
  );
  
  Future<void> deleteCalendarEvent(String eventId);
  
  Future<List<Map<String, dynamic>>> getEventsByHabit({
    required String userId,
    required String habitId,
  });
  
  Future<List<Map<String, dynamic>>> getUpcomingReminders({
    required String userId,
    int? limitMinutes,
  });
  
  Future<void> markEventAsCompleted(String eventId);
  
  Future<List<Map<String, dynamic>>> getRecurringEvents({
    required String userId,
    required DateTime date,
  });
  
  Future<Map<String, dynamic>> getCalendarEventById(String eventId);
  
  Future<List<Map<String, dynamic>>> getHabitSchedules({
    required String userId,
    required String habitId,
  });
  
  Future<Map<String, dynamic>> createHabitSchedule(Map<String, dynamic> scheduleData);
  
  Future<void> deleteHabitSchedule(String scheduleId);
  
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    bool? isRead,
  });
  
  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> notificationData);
  
  Future<void> markNotificationAsRead(String notificationId);
}

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final SupabaseClient _supabaseClient;

  CalendarRemoteDataSourceImpl({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getCalendarEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabaseClient
          .from('calendar_events')
          .select('*')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('start_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener eventos del calendario: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createCalendarEvent(
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await _supabaseClient
          .from('calendar_events')
          .insert(eventData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al crear evento del calendario: $e');
    }
  }

  Future<void> createMultipleCalendarEvents(List<Map<String, dynamic>> eventsData) async {
    try {
      await _supabaseClient
          .from('calendar_events')
          .insert(eventsData);
    } catch (e) {
      throw Exception('Failed to create multiple calendar events: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await _supabaseClient
          .from('calendar_events')
          .update(eventData)
          .eq('id', eventId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al actualizar evento del calendario: $e');
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await _supabaseClient
          .from('calendar_events')
          .delete()
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Error al eliminar evento del calendario: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventsByHabit({
    required String userId,
    required String habitId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('calendar_events')
          .select('*')
          .eq('user_id', userId)
          .eq('habit_id', habitId)
          .order('start_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener eventos por hábito: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUpcomingReminders({
    required String userId,
    int? limitMinutes,
  }) async {
    try {
      final now = DateTime.now();
      final limitTime = limitMinutes != null
          ? now.add(Duration(minutes: limitMinutes))
          : now.add(const Duration(hours: 24));

      final response = await _supabaseClient
          .from('calendar_events')
          .select('*')
          .eq('user_id', userId)
          .eq('notification_enabled', true)
          .gte('start_date', now.toIso8601String().split('T')[0])
          .lte('start_date', limitTime.toIso8601String().split('T')[0])
          .order('start_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener recordatorios próximos: $e');
    }
  }

  @override
  Future<void> markEventAsCompleted(String eventId) async {
    try {
      await _supabaseClient
          .from('calendar_events')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Error al marcar evento como completado: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecurringEvents({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      final response = await _supabaseClient
          .from('calendar_events')
          .select('*')
          .eq('user_id', userId)
          .neq('recurrence_type', 'none')
          .lte('start_date', dateString)
          .or('recurrence_end_date.is.null,recurrence_end_date.gte.$dateString')
          .order('start_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener eventos recurrentes: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getCalendarEventById(String eventId) async {
    try {
      final response = await _supabaseClient
          .from('calendar_events')
          .select('*')
          .eq('id', eventId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al obtener evento por ID: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getHabitSchedules({
    required String userId,
    required String habitId,
  }) async {
    try {
      final response = await _supabaseClient
          .from('habit_schedules')
          .select('*')
          .eq('user_id', userId)
          .eq('habit_id', habitId)
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener horarios de hábito: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> createHabitSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final response = await _supabaseClient
          .from('habit_schedules')
          .insert(scheduleData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al crear horario de hábito: $e');
    }
  }
  
  @override
  Future<void> deleteHabitSchedule(String scheduleId) async {
    try {
      await _supabaseClient
          .from('habit_schedules')
          .delete()
          .eq('id', scheduleId);
    } catch (e) {
      throw Exception('Error al eliminar horario de hábito: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    bool? isRead,
  }) async {
    try {
      var query = _supabaseClient
          .from('notifications')
          .select('*')
          .eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener notificaciones del usuario: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> notificationData) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al crear notificación: $e');
    }
  }
  
  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }
}