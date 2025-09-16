part of 'calendar_bloc.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<entity.CalendarEvent> events;
  final DateTime selectedDate;

  const CalendarLoaded({
    required this.events,
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [events, selectedDate];

  CalendarLoaded copyWith({
    List<entity.CalendarEvent>? events,
    DateTime? selectedDate,
  }) {
    return CalendarLoaded(
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  List<entity.CalendarEvent> getEventsForDate(DateTime date) {
    return events.where((event) {
      return event.startDate.year == date.year &&
             event.startDate.month == date.month &&
             event.startDate.day == date.day;
    }).toList();
  }

  List<entity.CalendarEvent> getUpcomingEvents({int limit = 5}) {
    final now = DateTime.now();
    final filteredEvents = events
        .where((event) => event.startDate.isAfter(now))
        .toList();
    filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    return filteredEvents.take(limit).toList();
  }

  List<entity.CalendarEvent> getTodayEvents() {
    final today = DateTime.now();
    return getEventsForDate(today);
  }

  List<entity.CalendarEvent> getCompletedEvents() {
    return events.where((event) => event.isCompleted).toList();
  }

  List<entity.CalendarEvent> getPendingEvents() {
    return events.where((event) => !event.isCompleted).toList();
  }

  List<entity.CalendarEvent> getEventsForMonth(DateTime date) {
    return events.where((event) {
      return event.startDate.year == date.year &&
             event.startDate.month == date.month;
    }).toList();
  }

  int get totalEvents => events.length;
  int get completedEventsCount => getCompletedEvents().length;
  int get pendingEventsCount => getPendingEvents().length;
  
  double get completionRate {
    if (totalEvents == 0) return 0.0;
    return completedEventsCount / totalEvents;
  }
}

class CalendarError extends CalendarState {
  final String message;

  const CalendarError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}