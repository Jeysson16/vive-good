import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/calendar_event.dart' as entity;
import '../../../domain/usecases/calendar/get_calendar_events.dart';
import '../../../domain/usecases/calendar/create_calendar_event.dart';
import '../../../domain/usecases/calendar/mark_event_completed.dart';
import '../../../data/services/habit_calendar_sync_service.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetCalendarEvents getCalendarEvents;
  final CreateCalendarEvent createCalendarEvent;
  final MarkEventCompleted markEventCompleted;
  final HabitCalendarSyncService habitCalendarSyncService;

  CalendarBloc({
    required this.getCalendarEvents,
    required this.createCalendarEvent,
    required this.markEventCompleted,
    required this.habitCalendarSyncService,
  }) : super(CalendarInitial()) {
    on<LoadCalendarEvents>(_onLoadCalendarEvents);
    on<CreateCalendarEventEvent>(_onCreateCalendarEvent);
    on<MarkCalendarEventCompleted>(_onMarkEventCompleted);
    on<RefreshCalendarEvents>(_onRefreshCalendarEvents);
    on<SelectCalendarDate>(_onSelectCalendarDate);
  }

  Future<void> _onLoadCalendarEvents(
    LoadCalendarEvents event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());

    // Primero sincronizar hábitos con eventos de calendario
    try {
      await habitCalendarSyncService.syncUserHabitsToCalendar(event.userId);
    } catch (e) {
      // Log error pero continuar con la carga de eventos
      print('Error syncing habits to calendar: $e');
    }

    final result = await getCalendarEvents(
      GetCalendarEventsParams(
        userId: event.userId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(CalendarError(message: failure.message)),
      (events) => emit(CalendarLoaded(
        events: events,
        selectedDate: event.selectedDate ?? DateTime.now(),
      )),
    );
  }

  Future<void> _onCreateCalendarEvent(
    CreateCalendarEventEvent event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      emit(CalendarLoading());

      final result = await createCalendarEvent(
        CreateCalendarEventParams(event: event.calendarEvent),
      );

      result.fold(
        (failure) => emit(CalendarError(message: failure.message)),
        (createdEvent) {
          final updatedEvents = List<entity.CalendarEvent>.from(currentState.events)
            ..add(createdEvent);
          emit(CalendarLoaded(
            events: updatedEvents,
            selectedDate: currentState.selectedDate,
          ));
        },
      );
    }
  }

  Future<void> _onMarkEventCompleted(
    MarkCalendarEventCompleted event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      
      final result = await markEventCompleted(
        MarkEventCompletedParams(eventId: event.eventId),
      );

      result.fold(
        (failure) => emit(CalendarError(message: failure.message)),
        (updatedEvent) {
          final updatedEvents = currentState.events.map((e) {
            return e.id == event.eventId ? updatedEvent : e;
          }).toList();
          
          emit(CalendarLoaded(
            events: updatedEvents,
            selectedDate: currentState.selectedDate,
          ));
        },
      );
    }
  }

  Future<void> _onRefreshCalendarEvents(
    RefreshCalendarEvents event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      
      final result = await getCalendarEvents(
        GetCalendarEventsParams(
          userId: event.userId,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );

      result.fold(
        (failure) => emit(CalendarError(message: failure.message)),
        (events) => emit(CalendarLoaded(
          events: events,
          selectedDate: currentState.selectedDate,
        )),
      );
    }
  }

  void _onSelectCalendarDate(
    SelectCalendarDate event,
    Emitter<CalendarState> emit,
  ) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      emit(CalendarLoaded(
        events: currentState.events,
        selectedDate: event.selectedDate,
      ));
    }
  }

  List<entity.CalendarEvent> getEventsForDate(DateTime date) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      return currentState.events.where((event) {
        return event.startDate.year == date.year &&
               event.startDate.month == date.month &&
               event.startDate.day == date.day;
      }).toList();
    }
    return [];
  }

  List<entity.CalendarEvent> getUpcomingEvents({int limit = 5}) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      final now = DateTime.now();
      
      return currentState.events
          .where((event) => 
              event.startDate.isAfter(now) || 
              (event.startDate.year == now.year &&
               event.startDate.month == now.month &&
               event.startDate.day == now.day))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate))
        ..take(limit);
    }
    return [];
  }

  List<entity.CalendarEvent> getTodayEvents() {
    final today = DateTime.now();
    return getEventsForDate(today);
  }
}