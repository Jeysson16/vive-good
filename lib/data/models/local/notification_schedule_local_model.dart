import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/notification_schedule.dart';

part 'notification_schedule_local_model.g.dart';

@HiveType(typeId: 11)
class NotificationScheduleLocalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitNotificationId;

  @HiveField(2)
  final String dayOfWeek; // 'monday', 'tuesday', etc. o 'daily'

  @HiveField(3)
  final String scheduledTime; // HH:mm format

  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final int snoozeCount;

  @HiveField(6)
  final DateTime? lastTriggered;

  @HiveField(7)
  final int platformNotificationId; // ID usado por flutter_local_notifications

  NotificationScheduleLocalModel({
    required this.id,
    required this.habitNotificationId,
    required this.dayOfWeek,
    required this.scheduledTime,
    this.isActive = true,
    this.snoozeCount = 0,
    this.lastTriggered,
    required this.platformNotificationId,
  });

  // Convertir desde entidad de dominio
  factory NotificationScheduleLocalModel.fromEntity(NotificationSchedule schedule) {
    return NotificationScheduleLocalModel(
      id: schedule.id,
      habitNotificationId: schedule.habitNotificationId,
      dayOfWeek: schedule.dayOfWeek,
      scheduledTime: schedule.scheduledTime,
      isActive: schedule.isActive,
      snoozeCount: schedule.snoozeCount,
      lastTriggered: schedule.lastTriggered,
      platformNotificationId: schedule.platformNotificationId,
    );
  }

  // Convertir desde Map (para base de datos)
  factory NotificationScheduleLocalModel.fromMap(Map<String, dynamic> map) {
    return NotificationScheduleLocalModel(
      id: map['id'] as String,
      habitNotificationId: map['habit_notification_id'] as String,
      dayOfWeek: map['day_of_week'] as String,
      scheduledTime: map['scheduled_time'] as String,
      isActive: (map['is_active'] as int) == 1,
      snoozeCount: map['snooze_count'] as int,
      lastTriggered: map['last_triggered'] != null 
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      platformNotificationId: map['platform_notification_id'] as int,
    );
  }

  // Convertir a entidad de dominio
  NotificationSchedule toEntity() {
    return NotificationSchedule(
      id: id,
      habitNotificationId: habitNotificationId,
      dayOfWeek: dayOfWeek,
      scheduledTime: scheduledTime,
      isActive: isActive,
      snoozeCount: snoozeCount,
      lastTriggered: lastTriggered,
      platformNotificationId: platformNotificationId,
    );
  }

  // Convertir a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_notification_id': habitNotificationId,
      'day_of_week': dayOfWeek,
      'scheduled_time': scheduledTime,
      'is_active': isActive ? 1 : 0,
      'snooze_count': snoozeCount,
      'last_triggered': lastTriggered?.toIso8601String(),
      'platform_notification_id': platformNotificationId,
    };
  }

  // Actualizar contador de snooze
  NotificationScheduleLocalModel incrementSnoozeCount() {
    return NotificationScheduleLocalModel(
      id: id,
      habitNotificationId: habitNotificationId,
      dayOfWeek: dayOfWeek,
      scheduledTime: scheduledTime,
      isActive: isActive,
      snoozeCount: snoozeCount + 1,
      lastTriggered: lastTriggered,
      platformNotificationId: platformNotificationId,
    );
  }

  // Resetear contador de snooze
  NotificationScheduleLocalModel resetSnoozeCount() {
    return NotificationScheduleLocalModel(
      id: id,
      habitNotificationId: habitNotificationId,
      dayOfWeek: dayOfWeek,
      scheduledTime: scheduledTime,
      isActive: isActive,
      snoozeCount: 0,
      lastTriggered: DateTime.now(),
      platformNotificationId: platformNotificationId,
    );
  }

  // Activar/desactivar horario
  NotificationScheduleLocalModel toggleActive() {
    return NotificationScheduleLocalModel(
      id: id,
      habitNotificationId: habitNotificationId,
      dayOfWeek: dayOfWeek,
      scheduledTime: scheduledTime,
      isActive: !isActive,
      snoozeCount: snoozeCount,
      lastTriggered: lastTriggered,
      platformNotificationId: platformNotificationId,
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'habit_notification_id': habitNotificationId,
      'day_of_week': dayOfWeek,
      'scheduled_time': scheduledTime,
      'is_active': isActive,
      'snooze_count': snoozeCount,
      'last_triggered': lastTriggered?.toIso8601String(),
      'platform_notification_id': platformNotificationId,
    };
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
    return 'NotificationScheduleLocalModel(id: $id, dayOfWeek: $dayOfWeek, scheduledTime: $scheduledTime, isActive: $isActive)';
  }
}