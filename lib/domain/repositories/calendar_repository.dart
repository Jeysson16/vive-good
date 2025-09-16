import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/calendar_event.dart';

abstract class CalendarRepository {
  /// Get calendar events for a user
  Future<Either<Failure, List<CalendarEvent>>> getCalendarEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Create a new calendar event
  Future<Either<Failure, CalendarEvent>> createCalendarEvent(CalendarEvent event);

  /// Update an existing calendar event
  Future<Either<Failure, CalendarEvent>> updateCalendarEvent(CalendarEvent event);

  /// Delete a calendar event
  Future<Either<Failure, void>> deleteCalendarEvent(String eventId);

  /// Mark an event as completed
  Future<Either<Failure, CalendarEvent>> markEventAsCompleted(String eventId);

  /// Get events for a specific date
  Future<Either<Failure, List<CalendarEvent>>> getEventsForDate(String userId, DateTime date);

  /// Get upcoming events for a user
  Future<Either<Failure, List<CalendarEvent>>> getUpcomingEvents(String userId);

  /// Get today's events for a user
  Future<Either<Failure, List<CalendarEvent>>> getTodayEvents(String userId);

  /// Get completed events for a user
  Future<Either<Failure, List<CalendarEvent>>> getCompletedEvents(String userId);

  /// Get pending events for a user
  Future<Either<Failure, List<CalendarEvent>>> getPendingEvents(String userId);
}