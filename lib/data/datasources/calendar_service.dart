import '../datasources/calendar_remote_datasource.dart';
import '../datasources/notification_service.dart';
import '../../domain/entities/calendar_event.dart';
import '../models/calendar_event_model.dart';

abstract class CalendarService {
  Future<void> initialize();
  Future<List<CalendarEvent>> getCalendarEvents(String userId, {DateTime? startDate, DateTime? endDate});
  Future<CalendarEvent> createCalendarEventWithNotification(Map<String, dynamic> eventData);
  Future<void> updateCalendarEvent(String eventId, Map<String, dynamic> updates);
  Future<void> deleteCalendarEvent(String eventId);
  Future<void> markEventAsCompleted(String eventId);
  Future<void> scheduleEventNotifications(CalendarEvent event);
  Future<void> cancelEventNotifications(String eventId);
}

class CalendarServiceImpl implements CalendarService {
  final CalendarRemoteDataSource _calendarDataSource;
  final NotificationService _notificationService;

  CalendarServiceImpl({
    required CalendarRemoteDataSource calendarDataSource,
    required NotificationService notificationService,
  }) : _calendarDataSource = calendarDataSource,
       _notificationService = notificationService;

  @override
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final eventsData = await _calendarDataSource.getCalendarEvents(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      
      return eventsData.map((eventData) {
        final eventModel = CalendarEventModel.fromJson(eventData);
        return CalendarEvent(
          id: eventModel.id,
          userId: eventModel.userId,
          habitId: eventModel.habitId,
          title: eventModel.title,
          description: eventModel.description,
          eventType: eventModel.eventType,
          startDate: eventModel.startDate,
          startTime: eventModel.startTime,
          endTime: eventModel.endTime,
          recurrenceType: eventModel.recurrenceType,
          notificationEnabled: eventModel.notificationEnabled,
          notificationMinutes: eventModel.notificationMinutes,
          isCompleted: eventModel.isCompleted,
          createdAt: eventModel.createdAt,
          updatedAt: eventModel.updatedAt,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get calendar events: $e');
    }
  }

  @override
  Future<CalendarEvent> createCalendarEventWithNotification(Map<String, dynamic> eventData) async {
    try {
      final createdEventData = await _calendarDataSource.createCalendarEvent(eventData);
      final eventModel = CalendarEventModel.fromJson(createdEventData);
      final event = CalendarEvent(
        id: eventModel.id,
        userId: eventModel.userId,
        habitId: eventModel.habitId,
        title: eventModel.title,
        description: eventModel.description,
        eventType: eventModel.eventType,
        startDate: eventModel.startDate,
        startTime: eventModel.startTime,
        endTime: eventModel.endTime,
        recurrenceType: eventModel.recurrenceType,
        notificationEnabled: eventModel.notificationEnabled,
        notificationMinutes: eventModel.notificationMinutes,
        isCompleted: eventModel.isCompleted,
        createdAt: eventModel.createdAt,
        updatedAt: eventModel.updatedAt,
      );
      
      // Schedule notification if enabled
      if (event.notificationEnabled && event.notificationMinutes != null) {
        await scheduleEventNotifications(event);
      }
      
      return event;
    } catch (e) {
      throw Exception('Failed to create calendar event with notification: $e');
    }
  }

  @override
  Future<void> updateCalendarEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _calendarDataSource.updateCalendarEvent(eventId, updates);
      
      // If notification settings changed, reschedule notifications
      if (updates.containsKey('notification_enabled') || 
          updates.containsKey('notification_minutes') ||
          updates.containsKey('start_date') ||
          updates.containsKey('start_time')) {
        
        // Cancel existing notifications
        await cancelEventNotifications(eventId);
        
        // Reschedule if notification is still enabled
        if (updates['notification_enabled'] == true) {
          final updatedEventData = await _calendarDataSource.getCalendarEventById(eventId);
          if (updatedEventData != null) {
            final updatedEvent = CalendarEventModel.fromJson(updatedEventData);
            final event = CalendarEvent(
              id: updatedEvent.id,
              userId: updatedEvent.userId,
              habitId: updatedEvent.habitId,
              title: updatedEvent.title,
              description: updatedEvent.description,
              eventType: updatedEvent.eventType,
              startDate: updatedEvent.startDate,
              startTime: updatedEvent.startTime,
              endTime: updatedEvent.endTime,
              recurrenceType: updatedEvent.recurrenceType,
              notificationEnabled: updatedEvent.notificationEnabled,
              notificationMinutes: updatedEvent.notificationMinutes,
              isCompleted: updatedEvent.isCompleted,
              createdAt: updatedEvent.createdAt,
              updatedAt: updatedEvent.updatedAt,
            );
            await scheduleEventNotifications(event);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update calendar event: $e');
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await cancelEventNotifications(eventId);
      await _calendarDataSource.deleteCalendarEvent(eventId);
    } catch (e) {
      throw Exception('Failed to delete calendar event: $e');
    }
  }

  @override
  Future<void> markEventAsCompleted(String eventId) async {
    try {
      await _calendarDataSource.updateCalendarEvent(eventId, {
        'is_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Cancel notification for completed event
      await cancelEventNotifications(eventId);
    } catch (e) {
      throw Exception('Failed to mark event as completed: $e');
    }
  }

  @override
  Future<void> scheduleEventNotifications(CalendarEvent event) async {
    if (!event.notificationEnabled || event.notificationMinutes == null) {
      return;
    }

    try {
      // Parse time from TimeOfDay
      int hour = 9;
      int minute = 0;
      if (event.startTime != null) {
        hour = event.startTime!.hour;
        minute = event.startTime!.minute;
      }
      
      final eventDateTime = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        hour,
        minute,
      );
      
      final notificationTime = eventDateTime.subtract(
        Duration(minutes: event.notificationMinutes!),
      );
      
      // Only schedule if the notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        final notificationId = '${event.id}_${event.startDate.millisecondsSinceEpoch}'.hashCode;
        
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: '¡Es hora de tu hábito!',
          body: '${event.title} en ${event.notificationMinutes} minutos',
          scheduledDate: notificationTime,
        );
      }
    } catch (e) {
      print('Error scheduling notification for event ${event.id}: $e');
    }
  }

  @override
  Future<void> cancelEventNotifications(String eventId) async {
    try {
      // Generate the same notification ID used when scheduling
      final notificationId = eventId.hashCode;
      await _notificationService.cancelNotification(notificationId);
    } catch (e) {
      print('Error canceling notification for event $eventId: $e');
    }
  }

  Future<void> scheduleRecurringNotifications(CalendarEvent event, {int daysAhead = 30}) async {
    if (!event.notificationEnabled || 
        event.notificationMinutes == null || 
        !event.isRecurring) {
      return;
    }

    try {
      final startDate = event.startDate;
      final endDate = startDate.add(Duration(days: daysAhead));
      
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        bool shouldSchedule = false;
        
        switch (event.recurrenceType?.toLowerCase()) {
          case 'diario':
            shouldSchedule = true;
            break;
          case 'semanal':
            shouldSchedule = currentDate.weekday >= 1 && currentDate.weekday <= 5;
            break;
          case 'mensual':
            shouldSchedule = currentDate.day == startDate.day;
            break;
        }
        
        if (shouldSchedule) {
          // Parse time from TimeOfDay
          int hour = 9;
          int minute = 0;
          if (event.startTime != null) {
            hour = event.startTime!.hour;
            minute = event.startTime!.minute;
          }
          
          final eventDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );
          
          final notificationTime = eventDateTime.subtract(
            Duration(minutes: event.notificationMinutes!),
          );
          
          if (notificationTime.isAfter(DateTime.now())) {
            final notificationId = '${event.id}_${currentDate.millisecondsSinceEpoch}'.hashCode;
            
            await _notificationService.scheduleNotification(
              id: notificationId,
              title: '¡Es hora de tu hábito!',
              body: '${event.title} en ${event.notificationMinutes} minutos',
              scheduledDate: notificationTime,
            );
          }
        }
        
        // Move to next occurrence
        switch (event.recurrenceType?.toLowerCase()) {
          case 'diario':
            currentDate = currentDate.add(const Duration(days: 1));
            break;
          case 'semanal':
            currentDate = currentDate.add(const Duration(days: 1));
            break;
          case 'mensual':
            currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
            break;
          default:
            currentDate = currentDate.add(const Duration(days: 1));
        }
      }
    } catch (e) {
      print('Error scheduling recurring notifications for event ${event.id}: $e');
    }
  }
}