import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/calendar_event.dart';
import '../../core/errors/exceptions.dart';

class CalendarService {
  final SupabaseClient _supabase;

  CalendarService(this._supabase);

  /// Obtiene todos los eventos de calendario para un usuario (NUEVO MÉTODO DINÁMICO)
  Future<List<CalendarEvent>> getCalendarEvents(String userId) async {
    print('📅 [CALENDAR] Iniciando obtención de eventos para usuario: $userId');
    
    List<CalendarEvent> dynamicEvents = [];
    List<CalendarEvent> manualEvents = [];
    
    try {
      // Intentar obtener eventos dinámicos generados desde user_habits
      print('📅 [CALENDAR] Obteniendo eventos dinámicos...');
      dynamicEvents = await generateDynamicEvents(
        userId, 
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now().add(const Duration(days: 90))
      );
      print('📅 [CALENDAR] Eventos dinámicos obtenidos: ${dynamicEvents.length}');
    } catch (e) {
      print('⚠️ [CALENDAR] Error obteniendo eventos dinámicos: $e');
      // Continuar con eventos manuales aunque fallen los dinámicos
    }
    
    try {
      // Obtener eventos manuales (no relacionados con hábitos)
      print('📅 [CALENDAR] Obteniendo eventos manuales...');
      manualEvents = await getManualEvents(userId);
      print('📅 [CALENDAR] Eventos manuales obtenidos: ${manualEvents.length}');
    } catch (e) {
      print('⚠️ [CALENDAR] Error obteniendo eventos manuales: $e');
      // Si fallan ambos, retornar lista vacía
    }
    
    // Combinar ambos tipos de eventos
    final allEvents = [...dynamicEvents, ...manualEvents];
    
    // Ordenar por fecha
    allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    print('📅 [CALENDAR] ✅ Total eventos obtenidos: ${allEvents.length}');
    return allEvents;
  }

  /// Genera eventos dinámicamente basándose en user_habits
  Future<List<CalendarEvent>> generateDynamicEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    print('📅 [CALENDAR] Iniciando generación de eventos dinámicos para usuario: $userId');
    print('📅 [CALENDAR] Rango de fechas: ${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}');
    
    try {
      // Obtener hábitos activos del usuario con timeout y manejo de errores
      print('📅 [CALENDAR] Consultando hábitos activos...');
      final habitsResponse = await _supabase
          .rpc('get_active_user_habits_for_calendar', params: {'p_user_id': userId})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ [CALENDAR] TIMEOUT: get_active_user_habits_for_calendar tardó más de 10 segundos');
              throw TimeoutException('Timeout obteniendo hábitos activos', const Duration(seconds: 10));
            },
          );

      if (habitsResponse == null) {
        print('⚠️ [CALENDAR] No se recibió respuesta de hábitos activos');
        return [];
      }

      final habits = habitsResponse as List;
      print('📅 [CALENDAR] Hábitos encontrados: ${habits.length}');
      
      if (habits.isEmpty) {
        print('ℹ️ [CALENDAR] No hay hábitos activos para generar eventos');
        return [];
      }

      final List<CalendarEvent> generatedEvents = [];

      // Obtener eventos de completado para evitar duplicados
      print('📅 [CALENDAR] Consultando eventos completados...');
      final completedEventsResponse = await _supabase
          .rpc('get_habit_completion_events', params: {
            'p_user_id': userId,
            'p_start_date': startDate.toIso8601String().split('T')[0],
            'p_end_date': endDate.toIso8601String().split('T')[0],
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ [CALENDAR] TIMEOUT: get_habit_completion_events tardó más de 10 segundos');
              throw TimeoutException('Timeout obteniendo eventos completados', const Duration(seconds: 10));
            },
          );

      final completedEvents = (completedEventsResponse as List?) ?? [];
      print('📅 [CALENDAR] Eventos completados encontrados: ${completedEvents.length}');
      
      final completedDates = <String, Set<String>>{};
      
      // Mapear eventos completados por hábito y fecha
      for (final completed in completedEvents) {
        final habitId = completed['habit_id'] as String;
        final eventDate = completed['event_date'] as String;
        completedDates.putIfAbsent(habitId, () => <String>{}).add(eventDate);
      }

      // Generar eventos para cada hábito
      print('📅 [CALENDAR] Procesando ${habits.length} hábitos...');
      for (int i = 0; i < habits.length; i++) {
        final habit = habits[i];
        print('📅 [CALENDAR] Procesando hábito ${i + 1}/${habits.length}: ${habit['habit_name']}');
        
        final habitId = habit['habit_id'] as String;
        final userHabitId = habit['user_habit_id'] as String;
        final habitName = habit['habit_name'] as String;
        final habitDescription = habit['habit_description'] as String? ?? '';
        final scheduledTime = habit['scheduled_time'] as String?;
        final frequency = habit['frequency'] as String;
        final habitStartDate = DateTime.parse(habit['start_date'] as String);
        final habitEndDate = habit['end_date'] != null 
            ? DateTime.parse(habit['end_date'] as String)
            : null;

        if (scheduledTime == null) {
          print('📅 [CALENDAR] Saltando hábito ${habitName} - sin hora programada');
          continue;
        }

        print('📅 [CALENDAR] Generando eventos para ${habitName} (${frequency})');

        // Generar eventos basándose en la frecuencia
        final eventDates = _generateEventDates(
          frequency,
          habitStartDate,
          habitEndDate ?? endDate,
          startDate,
          endDate,
        );

        print('📅 [CALENDAR] Fechas generadas para ${habitName}: ${eventDates.length}');
        
        for (final eventDate in eventDates) {
          final eventDateStr = eventDate.toIso8601String().split('T')[0];
          
          // Verificar si ya está completado
          final isCompleted = completedDates[habitId]?.contains(eventDateStr) ?? false;
          
          // Crear el evento
          final event = CalendarEvent(
            id: '${userHabitId}_${eventDateStr}', // ID único basado en hábito y fecha
            userId: userId,
            habitId: habitId,
            title: habitName,
            description: habitDescription,
            startDate: _combineDateTime(eventDate, scheduledTime),
            endDate: _combineDateTime(eventDate, scheduledTime).add(const Duration(hours: 1)),
            startTime: _combineDateTime(eventDate, scheduledTime),
            endTime: _combineDateTime(eventDate, scheduledTime).add(const Duration(hours: 1)),
            eventType: 'habit',
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null, // Marcar como completado si aplica
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          generatedEvents.add(event);
        }
      }

      print('📅 [CALENDAR] ✅ Generación completada. Total eventos: ${generatedEvents.length}');
      return generatedEvents;
    } on TimeoutException catch (e) {
      print('⏰ [CALENDAR] ERROR: Timeout en generación de eventos dinámicos: $e');
      // Retornar lista vacía en lugar de lanzar excepción para evitar carga infinita
      return [];
    } catch (e) {
      print('❌ [CALENDAR] ERROR: Error al generar eventos dinámicos: $e');
      // Retornar lista vacía en lugar de lanzar excepción para evitar carga infinita
      return [];
    }
  }

  /// Obtiene eventos manuales (no relacionados con hábitos)
  Future<List<CalendarEvent>> getManualEvents(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_manual_calendar_events', params: {'p_user_id': userId});

      if (response == null) return [];

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener eventos manuales: $e');
    }
  }

  /// Genera fechas de eventos basándose en la frecuencia
  List<DateTime> _generateEventDates(
    String frequency,
    DateTime habitStartDate,
    DateTime habitEndDate,
    DateTime rangeStartDate,
    DateTime rangeEndDate,
  ) {
    final List<DateTime> dates = [];
    final effectiveStartDate = habitStartDate.isAfter(rangeStartDate) 
        ? habitStartDate 
        : rangeStartDate;
    final effectiveEndDate = habitEndDate.isBefore(rangeEndDate) 
        ? habitEndDate 
        : rangeEndDate;

    DateTime currentDate = effectiveStartDate;

    switch (frequency.toLowerCase()) {
      case 'diario':
      case 'daily':
        while (currentDate.isBefore(effectiveEndDate) || 
               currentDate.isAtSameMomentAs(effectiveEndDate)) {
          dates.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 1));
        }
        break;

      case 'semanal':
      case 'weekly':
        while (currentDate.isBefore(effectiveEndDate) || 
               currentDate.isAtSameMomentAs(effectiveEndDate)) {
          dates.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 7));
        }
        break;

      case 'mensual':
      case 'monthly':
        while (currentDate.isBefore(effectiveEndDate) || 
               currentDate.isAtSameMomentAs(effectiveEndDate)) {
          dates.add(currentDate);
          // Agregar un mes
          final nextMonth = currentDate.month == 12 ? 1 : currentDate.month + 1;
          final nextYear = currentDate.month == 12 ? currentDate.year + 1 : currentDate.year;
          currentDate = DateTime(nextYear, nextMonth, currentDate.day);
        }
        break;

      default:
        // Para frecuencias no reconocidas, tratar como diario
        while (currentDate.isBefore(effectiveEndDate) || 
               currentDate.isAtSameMomentAs(effectiveEndDate)) {
          dates.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 1));
        }
    }

    return dates;
  }

  /// Combina una fecha con una hora
  DateTime _combineDateTime(DateTime date, String timeStr) {
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Parsea una cadena de tiempo a TimeOfDay
  TimeOfDay? _parseTime(String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
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

      // Usar el nuevo método dinámico
      final allEvents = await getCalendarEvents(userId);
      
      // Filtrar eventos para la fecha específica
      return allEvents.where((event) {
        return event.startDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
               event.startDate.isBefore(endOfDay);
      }).toList();
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

      // Usar el nuevo método dinámico
      final dynamicEvents = await generateDynamicEvents(userId, now, endDate);
      final manualEvents = await getManualEvents(userId);
      
      final allEvents = [...dynamicEvents, ...manualEvents];
      
      // Filtrar y limitar
      final upcomingEvents = allEvents
          .where((event) => event.startDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      return upcomingEvents.take(20).toList();
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
      final allEvents = await getCalendarEvents(userId);
      
      var filteredEvents = allEvents.where((event) => event.isCompleted);

      if (startDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isAfter(startDate.subtract(const Duration(seconds: 1))));
      }

      if (endDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isBefore(endDate.add(const Duration(days: 1))));
      }

      return filteredEvents.toList()
        ..sort((a, b) => (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));
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
      final allEvents = await getCalendarEvents(userId);
      
      var filteredEvents = allEvents.where((event) => !event.isCompleted);

      if (startDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isAfter(startDate.subtract(const Duration(seconds: 1))));
      }

      if (endDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isBefore(endDate.add(const Duration(days: 1))));
      }

      return filteredEvents.toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
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
      await _supabase.from('calendar_events').delete().eq('id', eventId);
    } catch (e) {
      throw ServerException('Error al eliminar evento de calendario: $e');
    }
  }

  /// Marca un evento como completado
  Future<CalendarEvent> markEventAsCompleted(String eventId) async {
    try {
      final now = DateTime.now();
      
      // Si es un evento dinámico (ID contiene '_'), crear un registro de completado
      if (eventId.contains('_')) {
        final parts = eventId.split('_');
        final userHabitId = parts[0];
        final eventDate = parts[1];
        
        // Obtener información del hábito
        final habitResponse = await _supabase
            .from('user_habits')
            .select('habit_id, user_id')
            .eq('id', userHabitId)
            .single();

        // Crear evento de completado
        final completionEvent = {
          'user_id': habitResponse['user_id'],
          'habit_id': habitResponse['habit_id'],
          'title': 'Hábito completado',
          'start_date': '${eventDate}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
          'event_type': 'habit_completion',
          'completed_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final response = await _supabase
            .from('calendar_events')
            .insert(completionEvent)
            .select()
            .single();

        return CalendarEvent.fromJson(response);
      } else {
        // Evento manual normal
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
      }
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
          .update({'completed_at': null, 'updated_at': now.toIso8601String()})
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
      final allEvents = await getCalendarEvents(userId);
      
      var filteredEvents = allEvents.where((event) => event.eventType == eventType);

      if (startDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isAfter(startDate.subtract(const Duration(seconds: 1))));
      }

      if (endDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isBefore(endDate.add(const Duration(days: 1))));
      }

      return filteredEvents.toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
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
      final allEvents = await getCalendarEvents(userId);
      
      var filteredEvents = allEvents.where((event) => 
          event.recurrenceType != null && event.recurrenceType != 'none');

      if (startDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isAfter(startDate.subtract(const Duration(seconds: 1))));
      }

      if (endDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isBefore(endDate.add(const Duration(days: 1))));
      }

      return filteredEvents.toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
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
      final allEvents = await getCalendarEvents(userId);
      
      final filteredEvents = allEvents.where((event) => 
          event.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          (event.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false)
      ).toList();

      filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return filteredEvents;
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
      final allEvents = await getCalendarEvents(userId);
      
      var filteredEvents = allEvents;

      if (startDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
      }

      if (endDate != null) {
        filteredEvents = filteredEvents.where((event) => 
            event.startDate.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }

      final stats = {
        'total': filteredEvents.length,
        'completed': filteredEvents.where((e) => e.isCompleted).length,
        'pending': filteredEvents.where((e) => !e.isCompleted).length,
        'byType': <String, int>{},
        'completionRate': 0.0,
      };

      // Contar por tipo
      for (final event in filteredEvents) {
        final type = event.eventType;
        final byType = stats['byType'] as Map<String, int>;
        byType[type] = (byType[type] ?? 0) + 1;
      }

      // Calcular tasa de completitud
      final total = stats['total'] as int;
      if (total > 0) {
        stats['completionRate'] = (stats['completed'] as int) / total;
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

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
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
