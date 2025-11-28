import 'package:equatable/equatable.dart';

class NotificationSchedule extends Equatable {
  final String id;
  final String habitNotificationId;
  final String dayOfWeek; // 'monday', 'tuesday', etc. o 'daily'
  final String scheduledTime; // HH:mm format
  final bool isActive;
  final int snoozeCount;
  final DateTime? lastTriggered;
  final int platformNotificationId; // ID usado por flutter_local_notifications

  const NotificationSchedule({
    required this.id,
    required this.habitNotificationId,
    required this.dayOfWeek,
    required this.scheduledTime,
    this.isActive = true,
    this.snoozeCount = 0,
    this.lastTriggered,
    required this.platformNotificationId,
  });

  @override
  List<Object?> get props => [
        id,
        habitNotificationId,
        dayOfWeek,
        scheduledTime,
        isActive,
        snoozeCount,
        lastTriggered,
        platformNotificationId,
      ];

  NotificationSchedule copyWith({
    String? id,
    String? habitNotificationId,
    String? dayOfWeek,
    String? scheduledTime,
    bool? isActive,
    int? snoozeCount,
    DateTime? lastTriggered,
    int? platformNotificationId,
  }) {
    return NotificationSchedule(
      id: id ?? this.id,
      habitNotificationId: habitNotificationId ?? this.habitNotificationId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      platformNotificationId: platformNotificationId ?? this.platformNotificationId,
    );
  }

  /// Convierte el tiempo programado en un objeto DateTime para el próximo día de la semana especificado
  DateTime get scheduledDateTime {
    final now = DateTime.now();
    final timeParts = scheduledTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // Si es 'daily' o un número, programar para hoy o el próximo día
    if (dayOfWeek == 'daily' || int.tryParse(dayOfWeek) != null) {
      final targetDay = int.tryParse(dayOfWeek);
      if (targetDay != null) {
        // dayOfWeek es un número (1=Lunes, 7=Domingo)
        return _getNextDateForDayOfWeek(now, targetDay, hour, minute);
      } else {
        // Es 'daily', programar para hoy si no ha pasado la hora, sino mañana
        final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
        if (todayAtTime.isAfter(now)) {
          return todayAtTime;
        } else {
          return todayAtTime.add(const Duration(days: 1));
        }
      }
    }
    
    // Si es un nombre de día, convertir a número
    final dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    
    final targetDay = dayMap[dayOfWeek.toLowerCase()];
    if (targetDay != null) {
      return _getNextDateForDayOfWeek(now, targetDay, hour, minute);
    }
    
    // Fallback: programar para hoy
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
  
  /// Calcula la próxima fecha para un día de la semana específico
  DateTime _getNextDateForDayOfWeek(DateTime now, int targetDayOfWeek, int hour, int minute) {
    final currentDayOfWeek = now.weekday;
    int daysUntilTarget = (targetDayOfWeek - currentDayOfWeek) % 7;
    
    // Si es el mismo día, verificar si ya pasó la hora
    if (daysUntilTarget == 0) {
      final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayAtTime.isAfter(now)) {
        return todayAtTime;
      } else {
        // Ya pasó la hora hoy, programar para la próxima semana
        daysUntilTarget = 7;
      }
    }
    
    final targetDate = now.add(Duration(days: daysUntilTarget));
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }

  /// Verifica si el horario es para hoy según el día de la semana
  bool get isScheduledForToday {
    if (dayOfWeek == 'daily') return true;
    
    final today = DateTime.now().weekday;
    final dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    
    return dayMap[dayOfWeek] == today;
  }

  @override
  String toString() {
    return 'NotificationSchedule(id: $id, dayOfWeek: $dayOfWeek, scheduledTime: $scheduledTime, isActive: $isActive)';
  }
}