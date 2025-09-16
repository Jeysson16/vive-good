import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/calendar_event.dart';
import '../../core/errors/exceptions.dart';

class CalendarService {
  final SupabaseClient _supabase;

  CalendarService(this._supabase);

  /// Obtiene todos los eventos de calendario para un usuario
  Future<List<CalendarEvent>> getCalendarEvents(String userId) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: true);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos de calendario: $e');
    }
  }

  /// Obtiene eventos para una fecha específica
  Future<List<CalendarEvent>> getEventsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .gte('start_date', startOfDay.toIso8601String())
          .lt('start_date', endOfDay.toIso8601String())
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos para la fecha: $e');
    }
  }

  /// Obtiene eventos próximos (siguientes 7 días)
  Future<List<CalendarEvent>> getUpcomingEvents(
    String userId, {
    int days = 7,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));

      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .gte('start_date', now.toIso8601String())
          .lte('start_date', endDate.toIso8601String())
          .order('start_date', ascending: true)
          .limit(20);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos próximos: $e');
    }
  }

  /// Obtiene eventos de hoy
  Future<List<CalendarEvent>> getTodayEvents(String userId) async {
    try {
      final today = DateTime.now();
      return await getEventsForDate(userId, today);
    } catch (e) {
      throw ServerException('Error al obtener eventos de hoy: $e');
    }
  }

  /// Obtiene eventos completados
  Future<List<CalendarEvent>> getCompletedEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .not('completed_at', 'is', null);

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }

      final response = await query.order('completed_at', ascending: false);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos completados: $e');
    }
  }

  /// Obtiene eventos pendientes
  Future<List<CalendarEvent>> getPendingEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .isFilter('completed_at', null);

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }

      final response = await query.order('start_date', ascending: true);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos pendientes: $e');
    }
  }

  /// Crea un nuevo evento de calendario
  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .insert(event.toJson())
          .select()
          .single();

      return CalendarEvent.fromJson(response);
    } catch (e) {
      throw ServerException('Error al crear evento de calendario: $e');
    }
  }

  /// Actualiza un evento de calendario existente
  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .update(event.toJson())
          .eq('id', event.id)
          .select()
          .single();

      return CalendarEvent.fromJson(response);
    } catch (e) {
      throw ServerException('Error al actualizar evento de calendario: $e');
    }
  }

  /// Elimina un evento de calendario
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId);
    } catch (e) {
      throw ServerException('Error al eliminar evento de calendario: $e');
    }
  }

  /// Marca un evento como completado
  Future<CalendarEvent> markEventAsCompleted(String eventId) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('calendar_events')
          .update({
            'completed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', eventId)
          .select()
          .single();

      return CalendarEvent.fromJson(response);
    } catch (e) {
      throw ServerException('Error al marcar evento como completado: $e');
    }
  }

  /// Desmarca un evento como completado
  Future<CalendarEvent> unmarkEventAsCompleted(String eventId) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('calendar_events')
          .update({
            'completed_at': null,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', eventId)
          .select()
          .single();

      return CalendarEvent.fromJson(response);
    } catch (e) {
      throw ServerException('Error al desmarcar evento como completado: $e');
    }
  }

  /// Obtiene eventos por tipo
  Future<List<CalendarEvent>> getEventsByType(
    String userId,
    String eventType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .eq('event_type', eventType);

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }

      final response = await query.order('start_date', ascending: true);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos por tipo: $e');
    }
  }

  /// Obtiene eventos recurrentes
  Future<List<CalendarEvent>> getRecurringEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .neq('recurrence_type', 'none');

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }

      final response = await query.order('start_date', ascending: true);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos recurrentes: $e');
    }
  }

  /// Busca eventos por título o descripción
  Future<List<CalendarEvent>> searchEvents(
    String userId,
    String searchTerm,
  ) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .order('start_date', ascending: true);

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al buscar eventos: $e');
    }
  }

  /// Obtiene estadísticas de eventos
  Future<Map<String, dynamic>> getEventStatistics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('calendar_events')
          .select('event_type, completed_at')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }

      final response = await query;
      final events = response as List;

      final stats = {
        'total': events.length,
        'completed': events.where((e) => e['completed_at'] != null).length,
        'pending': events.where((e) => e['completed_at'] == null).length,
        'byType': <String, int>{},
        'completionRate': 0.0,
      };

      // Contar por tipo
      for (final event in events) {
        final type = event['event_type'] as String;
        final byType = stats['byType'] as Map<String, int>;
        byType[type] = (byType[type] ?? 0) + 1;
      }

      // Calcular tasa de completitud
      final total = stats['total'] as int;
      if (total > 0) {
        stats['completionRate'] = 
            (stats['completed'] as int) / total;
      }

      return stats;
    } catch (e) {
      throw ServerException('Error al obtener estadísticas de eventos: $e');
    }
  }

  /// Crea eventos recurrentes basados en un evento padre
  Future<List<CalendarEvent>> createRecurringEvents(
    CalendarEvent parentEvent,
    DateTime endDate,
  ) async {
    try {
      final events = <CalendarEvent>[];
      var currentDate = parentEvent.startDate;
      
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        if (currentDate.isAfter(parentEvent.startDate)) {
          final recurringEvent = parentEvent.copyWith(
            id: null, // Se generará un nuevo ID
            startDate: currentDate,
            endDate: parentEvent.endDate != null 
                ? DateTime(
                    currentDate.year,
                    currentDate.month,
                    currentDate.day,
                    parentEvent.endDate!.hour,
                    parentEvent.endDate!.minute,
                  )
                : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final createdEvent = await createCalendarEvent(recurringEvent);
          events.add(createdEvent);
        }
        
        // Calcular siguiente fecha según tipo de recurrencia
        switch (parentEvent.recurrenceType) {
          case 'daily':
            currentDate = currentDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            currentDate = currentDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            currentDate = DateTime(
              currentDate.month == 12 ? currentDate.year + 1 : currentDate.year,
              currentDate.month == 12 ? 1 : currentDate.month + 1,
              currentDate.day,
              currentDate.hour,
              currentDate.minute,
            );
            break;
          case 'yearly':
            currentDate = DateTime(
              currentDate.year + 1,
              currentDate.month,
              currentDate.day,
              currentDate.hour,
              currentDate.minute,
            );
            break;
          default:
            break;
        }
      }
      
      return events;
    } catch (e) {
      throw ServerException('Error al crear eventos recurrentes: $e');
    }
  }
}