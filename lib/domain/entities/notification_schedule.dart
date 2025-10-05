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

  /// Convierte el tiempo programado en un objeto DateTime para hoy
  DateTime get scheduledDateTime {
    final now = DateTime.now();
    final timeParts = scheduledTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    return DateTime(now.year, now.month, now.day, hour, minute);
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