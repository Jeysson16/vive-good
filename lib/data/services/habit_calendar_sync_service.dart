import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import 'calendar_service.dart';

/// Servicio para sincronizar hábitos existentes con eventos de calendario
class HabitCalendarSyncService {
  final SupabaseClient _supabase;
  final CalendarService _calendarService;

  HabitCalendarSyncService(this._supabase, this._calendarService);

  /// Sincroniza todos los hábitos activos de un usuario con eventos de calendario
  Future<void> syncUserHabitsToCalendar(String userId) async {
    try {
      print('🔄 [SYNC] Iniciando sincronización de hábitos para usuario: $userId');
      
      // Obtener hábitos sin eventos de calendario
      final habitsWithoutEvents = await _getHabitsWithoutCalendarEvents(userId);
      
      if (habitsWithoutEvents.isEmpty) {
        print('✅ [SYNC] No hay hábitos sin eventos de calendario');
        return;
      }

      print('📋 [SYNC] Encontrados ${habitsWithoutEvents.length} hábitos sin eventos');

      // Sincronizar cada hábito
      for (final habitData in habitsWithoutEvents) {
        try {
          await _syncSingleHabitToCalendar(habitData);
          print('✅ [SYNC] Hábito sincronizado: ${habitData['habit_name']}');
        } catch (e) {
          print('❌ [SYNC] Error sincronizando hábito ${habitData['habit_name']}: $e');
          // Continuar con el siguiente hábito
        }
      }

      print('🎉 [SYNC] Sincronización completada');
    } catch (e) {
      print('❌ [SYNC] Error en sincronización general: $e');
      throw ServerException('Error al sincronizar hábitos con calendario: $e');
    }
  }

  /// Obtiene hábitos activos que no tienen eventos de calendario
  Future<List<Map<String, dynamic>>> _getHabitsWithoutCalendarEvents(String userId) async {
    try {
      final response = await _supabase.rpc('get_habits_without_calendar_events', 
        params: {'p_user_id': userId}
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      // Si la función RPC no existe, usar consulta directa
      return await _getHabitsWithoutCalendarEventsDirect(userId);
    }
  }

  /// Consulta directa para obtener hábitos sin eventos (fallback)
  Future<List<Map<String, dynamic>>> _getHabitsWithoutCalendarEventsDirect(String userId) async {
    final response = await _supabase
        .from('user_habits')
        .select('''
          id,
          user_id,
          habit_id,
          start_date,
          end_date,
          frequency,
          scheduled_time,
          is_active,
          custom_name,
          custom_description,
          habits!inner(
            id,
            name,
            description,
            category_id,
            icon_name,
            icon_color
          )
        ''')
        .eq('user_id', userId)
        .eq('is_active', true);

    final userHabits = List<Map<String, dynamic>>.from(response);
    final habitsWithoutEvents = <Map<String, dynamic>>[];

    // Verificar cuáles no tienen eventos de calendario
    for (final userHabit in userHabits) {
      final hasEvents = await _hasCalendarEvents(userId, userHabit['habit_id']);
      if (!hasEvents) {
        habitsWithoutEvents.add({
          'user_habit_id': userHabit['id'],
          'user_id': userHabit['user_id'],
          'habit_id': userHabit['habit_id'],
          'habit_name': userHabit['custom_name'] ?? userHabit['habits']['name'],
          'habit_description': userHabit['custom_description'] ?? userHabit['habits']['description'],
          'start_date': userHabit['start_date'],
          'end_date': userHabit['end_date'],
          'frequency': userHabit['frequency'],
          'scheduled_time': userHabit['scheduled_time'],
          'category_id': userHabit['habits']['category_id'],
          'icon_name': userHabit['habits']['icon_name'],
          'icon_color': userHabit['habits']['icon_color'],
        });
      }
    }

    return habitsWithoutEvents;
  }

  /// Verifica si un hábito tiene eventos de calendario
  Future<bool> _hasCalendarEvents(String userId, String habitId) async {
    final response = await _supabase
        .from('calendar_events')
        .select('id')
        .eq('user_id', userId)
        .eq('habit_id', habitId)
        .limit(1);

    return response.isNotEmpty;
  }

  /// Sincroniza un hábito individual con eventos de calendario
  Future<void> _syncSingleHabitToCalendar(Map<String, dynamic> habitData) async {
    final userId = habitData['user_id'] as String;
    final habitId = habitData['habit_id'] as String;
    final habitName = habitData['habit_name'] as String;
    final habitDescription = habitData['habit_description'] as String? ?? '';
    final frequency = habitData['frequency'] as String;
    final scheduledTime = habitData['scheduled_time'] as String?;
    final startDateStr = habitData['start_date'] as String;
    final endDateStr = habitData['end_date'] as String?;

    // Parsear fechas
    final startDate = DateTime.parse(startDateStr);
    final endDate = endDateStr != null 
        ? DateTime.parse(endDateStr)
        : startDate.add(const Duration(days: 30)); // Default 30 días

    // Parsear hora programada
    final scheduledTimeOfDay = _parseScheduledTime(scheduledTime);

    // Generar eventos basados en la frecuencia
    final events = _generateCalendarEvents(
      userId: userId,
      habitId: habitId,
      habitName: habitName,
      habitDescription: habitDescription,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      scheduledTime: scheduledTimeOfDay,
    );

    // Crear eventos en lotes para optimizar
    await _createEventsInBatches(events);
  }

  /// Parsea la hora programada desde string
  Map<String, int>? _parseScheduledTime(String? scheduledTime) {
    if (scheduledTime == null || scheduledTime.isEmpty) {
      return {'hour': 9, 'minute': 0}; // Default 9:00 AM
    }

    try {
      final parts = scheduledTime.split(':');
      if (parts.length >= 2) {
        return {
          'hour': int.parse(parts[0]),
          'minute': int.parse(parts[1]),
        };
      }
    } catch (e) {
      print('⚠️ [SYNC] Error parseando hora programada: $scheduledTime');
    }

    return {'hour': 9, 'minute': 0}; // Default fallback
  }

  /// Genera eventos de calendario basados en la frecuencia del hábito
  List<Map<String, dynamic>> _generateCalendarEvents({
    required String userId,
    required String habitId,
    required String habitName,
    required String habitDescription,
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, int>? scheduledTime,
  }) {
    final events = <Map<String, dynamic>>[];
    final hour = scheduledTime?['hour'] ?? 9;
    final minute = scheduledTime?['minute'] ?? 0;

    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final finalDate = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(finalDate) || currentDate.isAtSameMomentAs(finalDate)) {
      bool shouldCreateEvent = false;

      switch (frequency.toLowerCase()) {
        case 'diario':
        case 'daily':
          shouldCreateEvent = true;
          break;
        case 'semanal':
        case 'weekly':
          // Crear evento en días laborables (lunes a viernes)
          shouldCreateEvent = currentDate.weekday >= 1 && currentDate.weekday <= 5;
          break;
        case 'mensual':
        case 'monthly':
          // Crear evento el mismo día de cada mes
          shouldCreateEvent = currentDate.day == startDate.day;
          break;
        case 'personalizado':
        case 'custom':
          // Para frecuencia personalizada, crear diariamente por defecto
          shouldCreateEvent = true;
          break;
        default:
          shouldCreateEvent = true;
      }

      if (shouldCreateEvent) {
        final startDateTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        );

        final endDateTime = startDateTime.add(const Duration(hours: 1)); // Duración default 1 hora

        final eventData = {
          'user_id': userId,
          'habit_id': habitId,
          'title': habitName,
          'description': habitDescription.isNotEmpty ? habitDescription : null,
          'start_date': currentDate.toIso8601String().split('T')[0],
          'start_time': startDateTime.toIso8601String(),
          'end_time': endDateTime.toIso8601String(),
          'event_type': 'habit',
          'recurrence_type': _mapFrequencyToRecurrenceType(frequency),
          'notification_enabled': true,
          'notification_minutes': 15,
          'is_completed': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        events.add(eventData);
      }

      // Avanzar a la siguiente fecha según la frecuencia
      switch (frequency.toLowerCase()) {
        case 'diario':
        case 'daily':
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'semanal':
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'mensual':
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
          );
          break;
        default:
          currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return events;
  }

  /// Mapea frecuencia a tipo de recurrencia
  String _mapFrequencyToRecurrenceType(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'diario':
      case 'daily':
        return 'daily';
      case 'semanal':
      case 'weekly':
        return 'weekly';
      case 'mensual':
      case 'monthly':
        return 'monthly';
      case 'anual':
      case 'yearly':
        return 'yearly';
      default:
        return 'none';
    }
  }

  /// Crea eventos en lotes para optimizar el rendimiento
  Future<void> _createEventsInBatches(List<Map<String, dynamic>> events) async {
    const batchSize = 50; // Procesar en lotes de 50 eventos
    
    for (int i = 0; i < events.length; i += batchSize) {
      final batch = events.skip(i).take(batchSize).toList();
      
      try {
        await _supabase.from('calendar_events').insert(batch);
        print('✅ [SYNC] Lote de ${batch.length} eventos creado exitosamente');
      } catch (e) {
        print('❌ [SYNC] Error creando lote de eventos: $e');
        // Intentar crear eventos individualmente como fallback
        await _createEventsIndividually(batch);
      }
    }
  }

  /// Crea eventos individualmente como fallback
  Future<void> _createEventsIndividually(List<Map<String, dynamic>> events) async {
    for (final eventData in events) {
      try {
        await _supabase.from('calendar_events').insert(eventData);
      } catch (e) {
        print('❌ [SYNC] Error creando evento individual: $e');
        // Continuar con el siguiente evento
      }
    }
  }

  /// Verifica si un usuario necesita sincronización
  Future<bool> needsSync(String userId) async {
    try {
      final habitsWithoutEvents = await _getHabitsWithoutCalendarEvents(userId);
      return habitsWithoutEvents.isNotEmpty;
    } catch (e) {
      print('❌ [SYNC] Error verificando necesidad de sincronización: $e');
      return false;
    }
  }

  /// Limpia eventos de calendario huérfanos (sin hábito asociado)
  Future<void> cleanupOrphanedEvents(String userId) async {
    try {
      await _supabase.rpc('cleanup_orphaned_calendar_events', 
        params: {'p_user_id': userId}
      );
      print('🧹 [SYNC] Eventos huérfanos limpiados');
    } catch (e) {
      print('⚠️ [SYNC] Error limpiando eventos huérfanos: $e');
    }
  }
}