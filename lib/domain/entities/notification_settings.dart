import 'package:equatable/equatable.dart';

class NotificationSettings extends Equatable {
  final String userId;
  final bool globalNotificationsEnabled;
  final bool permissionsGranted;
  final String? quietHoursStart; // HH:mm format
  final String? quietHoursEnd; // HH:mm format
  final int defaultSnoozeMinutes;
  final int maxSnoozeCount;
  final String defaultNotificationSound;
  final DateTime updatedAt;

  const NotificationSettings({
    required this.userId,
    this.globalNotificationsEnabled = true,
    this.permissionsGranted = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.defaultSnoozeMinutes = 15,
    this.maxSnoozeCount = 3,
    this.defaultNotificationSound = 'default',
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        globalNotificationsEnabled,
        permissionsGranted,
        quietHoursStart,
        quietHoursEnd,
        defaultSnoozeMinutes,
        maxSnoozeCount,
        defaultNotificationSound,
        updatedAt,
      ];

  NotificationSettings copyWith({
    String? userId,
    bool? globalNotificationsEnabled,
    bool? permissionsGranted,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? defaultSnoozeMinutes,
    int? maxSnoozeCount,
    String? defaultNotificationSound,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      globalNotificationsEnabled: globalNotificationsEnabled ?? this.globalNotificationsEnabled,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound ?? this.defaultNotificationSound,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si estamos en horario de silencio
  bool get isInQuietHours {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final startParts = quietHoursStart!.split(':');
    final endParts = quietHoursEnd!.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);
    
    // Si el horario de fin es menor que el de inicio, significa que cruza medianoche
    if (endTime.isBefore(startTime)) {
      // Horario nocturno (ej: 22:00 - 07:00)
      return now.isAfter(startTime) || now.isBefore(endTime);
    } else {
      // Horario diurno (ej: 12:00 - 14:00)
      return now.isAfter(startTime) && now.isBefore(endTime);
    }
  }

  /// Lista de opciones de snooze disponibles
  List<int> get availableSnoozeOptions => [5, 15, 30, 60];

  @override
  String toString() {
    return 'NotificationSettings(userId: $userId, globalEnabled: $globalNotificationsEnabled, permissionsGranted: $permissionsGranted)';
  }
}