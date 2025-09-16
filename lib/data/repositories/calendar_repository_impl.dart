import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final SupabaseClient supabaseClient;
  final CalendarService _calendarService;
  final NotificationService _notificationService;

  CalendarRepositoryImpl({
    required this.supabaseClient,
    CalendarService? calendarService,
    NotificationService? notificationService,
  }) : _calendarService = calendarService ?? CalendarService(supabaseClient),
       _notificationService = notificationService ?? NotificationService();

  @override
  Future<Either<Failure, List<CalendarEvent>>> getCalendarEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await _calendarService.getCalendarEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get calendar events: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, CalendarEvent>> createCalendarEvent(
    CalendarEvent event,
  ) async {
    try {
      final createdEvent = await _calendarService.createCalendarEvent(event);

      // Programar notificaciones si el evento tiene fecha y hora futuras
      final eventDateTime = _getEventDateTime(createdEvent);
      if (eventDateTime.isAfter(DateTime.now())) {
        if (createdEvent.recurrenceType != 'none') {
          await _notificationService.scheduleRecurringNotifications(
            createdEvent,
          );
        } else {
          await _notificationService.scheduleEventNotification(createdEvent);
        }
      }

      return Right(createdEvent);
    } catch (e) {
      return Left(
        ServerFailure('Failed to create calendar event: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, CalendarEvent>> updateCalendarEvent(
    CalendarEvent event,
  ) async {
    try {
      final response = await supabaseClient
          .from('calendar_events')
          .update(event.toJson())
          .eq('id', event.id)
          .select()
          .single();

      final updatedEvent = CalendarEvent.fromJson(response);
      return Right(updatedEvent);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar evento: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCalendarEvent(String eventId) async {
    try {
      await supabaseClient.from('calendar_events').delete().eq('id', eventId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar evento: $e'));
    }
  }

  @override
  Future<Either<Failure, CalendarEvent>> markEventAsCompleted(
    String eventId,
  ) async {
    try {
      final completedEvent = await _calendarService.markEventAsCompleted(
        eventId,
      );

      // Mostrar notificación de completitud
      await _notificationService.showImmediateNotification(
        '✅ Evento Completado',
        '${completedEvent.title} ha sido marcado como completado',
        payload: eventId,
      );

      return Right(completedEvent);
    } catch (e) {
      return Left(
        ServerFailure('Failed to mark event as completed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getEventsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final events = await _calendarService.getEventsForDate(userId, date);
      return Right(events);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get events for date: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getUpcomingEvents(
    String userId,
  ) async {
    try {
      final events = await _calendarService.getUpcomingEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get upcoming events: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getTodayEvents(
    String userId,
  ) async {
    try {
      final events = await _calendarService.getTodayEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure('Failed to get today events: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getCompletedEvents(
    String userId,
  ) async {
    try {
      final events = await _calendarService.getCompletedEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get completed events: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getPendingEvents(
    String userId,
  ) async {
    try {
      final events = await _calendarService.getPendingEvents(userId);
      return Right(events);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get pending events: ${e.toString()}'),
      );
    }
  }

  /// Método auxiliar para obtener la fecha y hora del evento
  DateTime _getEventDateTime(CalendarEvent event) {
    if (event.startTime != null) {
      return event.startTime!;
    }

    return event.startDate;
  }
}
