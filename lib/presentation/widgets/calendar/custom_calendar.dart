import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../domain/entities/calendar_event.dart';

class CustomCalendar extends StatefulWidget {
  final List<CalendarEvent> events;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime)? onDaySelected;
  final Function(DateTime)? onPageChanged;

  const CustomCalendar({
    super.key,
    required this.events,
    this.selectedDay,
    this.onDaySelected,
    this.onPageChanged,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = widget.selectedDay ?? DateTime.now();
  }

  @override
  void didUpdateWidget(CustomCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != oldWidget.selectedDay) {
      _selectedDay = widget.selectedDay;
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return widget.events.where((event) {
      return isSameDay(event.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mes',
          CalendarFormat.twoWeeks: '2 Semanas',
          CalendarFormat.week: 'Semana',
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onDaySelected?.call(selectedDay, focusedDay);
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          widget.onPageChanged?.call(focusedDay);
        },
        calendarStyle: CalendarStyle(
          // Today styling
          todayDecoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Selected day styling
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Weekend styling
          weekendTextStyle: TextStyle(
            color: Colors.red[400],
          ),
          // Outside days styling
          outsideDaysVisible: false,
          // Default text styling
          defaultTextStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          // Marker styling
          markersMaxCount: 3,
          markerDecoration: const BoxDecoration(
            color: Color(0xFF2196F3),
            shape: BoxShape.circle,
          ),
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
          markerSize: 6,
          // Cell styling
          cellMargin: const EdgeInsets.all(4),
          cellPadding: const EdgeInsets.all(0),
          // Range styling (if needed in future)
          rangeHighlightColor: const Color(0xFF4CAF50).withOpacity(0.2),
          rangeStartDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          // Header text styling
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          formatButtonTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4CAF50),
          ),
          formatButtonDecoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF4CAF50),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          // Arrow styling
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF4CAF50),
            size: 28,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: Color(0xFF4CAF50),
            size: 28,
          ),
          // Header padding
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
          titleCentered: true,
          formatButtonVisible: true,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          // Days of week styling
          weekdayStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          weekendStyle: TextStyle(
            color: Colors.red[400],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        // Custom builders
        calendarBuilders: CalendarBuilders(
          // Custom marker builder
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            
            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  Color markerColor;
                  if (event.isCompleted) {
                    markerColor = Colors.green;
                  } else if (event.habitId != null) {
                    markerColor = const Color(0xFF4CAF50);
                  } else {
                    markerColor = const Color(0xFF2196F3);
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
          // Custom day builder for special styling
          defaultBuilder: (context, day, focusedDay) {
            final events = _getEventsForDay(day);
            final hasCompletedEvents = events.any((e) => e.isCompleted);
            final hasPendingEvents = events.any((e) => !e.isCompleted);
            
            Color? backgroundColor;
            if (hasCompletedEvents && !hasPendingEvents) {
              backgroundColor = Colors.green.withOpacity(0.1);
            } else if (hasPendingEvents) {
              backgroundColor = Colors.orange.withOpacity(0.1);
            }
            
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}