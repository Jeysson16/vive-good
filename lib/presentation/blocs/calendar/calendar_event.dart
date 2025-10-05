part of 'calendar_bloc.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class LoadCalendarEvents extends CalendarEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? selectedDate;

  const LoadCalendarEvents({
    required this.userId,
    this.startDate,
    this.endDate,
    this.selectedDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate, selectedDate];
}

class CreateCalendarEventEvent extends CalendarEvent {
  final entity.CalendarEvent calendarEvent;

  const CreateCalendarEventEvent({
    required this.calendarEvent,
  });

  @override
  List<Object?> get props => [calendarEvent];
}

class MarkCalendarEventCompleted extends CalendarEvent {
  final String eventId;

  const MarkCalendarEventCompleted({
    required this.eventId,
  });

  @override
  List<Object?> get props => [eventId];
}

class RefreshCalendarEvents extends CalendarEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const RefreshCalendarEvents({
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

class SelectCalendarDate extends CalendarEvent {
  final DateTime selectedDate;

  const SelectCalendarDate({
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [selectedDate];
}