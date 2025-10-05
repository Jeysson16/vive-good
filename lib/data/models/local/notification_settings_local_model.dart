import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/notification_settings.dart';

part 'notification_settings_local_model.g.dart';

@HiveType(typeId: 13)
class NotificationSettingsLocalModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final bool globalNotificationsEnabled;

  @HiveField(2)
  final bool permissionsGranted;

  @HiveField(3)
  final String? quietHoursStart; // HH:mm

  @HiveField(4)
  final String? quietHoursEnd; // HH:mm

  @HiveField(5)
  final int defaultSnoozeMinutes;

  @HiveField(6)
  final int maxSnoozeCount;

  @HiveField(7)
  final String defaultNotificationSound;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final bool needsSync;

  @HiveField(10)
  final DateTime? lastSyncAt;

  NotificationSettingsLocalModel({
    required this.userId,
    this.globalNotificationsEnabled = true,
    this.permissionsGranted = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.defaultSnoozeMinutes = 15,
    this.maxSnoozeCount = 3,
    this.defaultNotificationSound = 'default',
    required this.updatedAt,
    this.needsSync = false,
    this.lastSyncAt,
  });

  // Convertir desde entidad de dominio
  factory NotificationSettingsLocalModel.fromEntity(NotificationSettings settings) {
    return NotificationSettingsLocalModel(
      userId: settings.userId,
      globalNotificationsEnabled: settings.globalNotificationsEnabled,
      permissionsGranted: settings.permissionsGranted,
      quietHoursStart: settings.quietHoursStart,
      quietHoursEnd: settings.quietHoursEnd,
      defaultSnoozeMinutes: settings.defaultSnoozeMinutes,
      maxSnoozeCount: settings.maxSnoozeCount,
      defaultNotificationSound: settings.defaultNotificationSound,
      updatedAt: settings.updatedAt,
    );
  }

  // Convertir desde Map (para base de datos)
  factory NotificationSettingsLocalModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsLocalModel(
      userId: map['user_id'] as String,
      globalNotificationsEnabled: (map['global_notifications_enabled'] as int) == 1,
      permissionsGranted: (map['permissions_granted'] as int) == 1,
      quietHoursStart: map['quiet_hours_start'] as String?,
      quietHoursEnd: map['quiet_hours_end'] as String?,
      defaultSnoozeMinutes: map['default_snooze_minutes'] as int,
      maxSnoozeCount: map['max_snooze_count'] as int,
      defaultNotificationSound: map['default_notification_sound'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      needsSync: (map['needs_sync'] as int?) == 1,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
    );
  }

  // Convertir a entidad de dominio
  NotificationSettings toEntity() {
    return NotificationSettings(
      userId: userId,
      globalNotificationsEnabled: globalNotificationsEnabled,
      permissionsGranted: permissionsGranted,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound,
      updatedAt: updatedAt,
    );
  }

  // Convertir a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'global_notifications_enabled': globalNotificationsEnabled ? 1 : 0,
      'permissions_granted': permissionsGranted ? 1 : 0,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'default_snooze_minutes': defaultSnoozeMinutes,
      'max_snooze_count': maxSnoozeCount,
      'default_notification_sound': defaultNotificationSound,
      'updated_at': updatedAt.toIso8601String(),
      'needs_sync': needsSync ? 1 : 0,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  // Actualizar permisos
  NotificationSettingsLocalModel updatePermissions(bool granted) {
    return NotificationSettingsLocalModel(
      userId: userId,
      globalNotificationsEnabled: globalNotificationsEnabled,
      permissionsGranted: granted,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound,
      updatedAt: DateTime.now(),
      needsSync: true,
      lastSyncAt: lastSyncAt,
    );
  }

  // Activar/desactivar notificaciones globalmente
  NotificationSettingsLocalModel toggleGlobalNotifications() {
    return NotificationSettingsLocalModel(
      userId: userId,
      globalNotificationsEnabled: !globalNotificationsEnabled,
      permissionsGranted: permissionsGranted,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound,
      updatedAt: DateTime.now(),
      needsSync: true,
      lastSyncAt: lastSyncAt,
    );
  }

  // Actualizar horarios de silencio
  NotificationSettingsLocalModel updateQuietHours(String? start, String? end) {
    return NotificationSettingsLocalModel(
      userId: userId,
      globalNotificationsEnabled: globalNotificationsEnabled,
      permissionsGranted: permissionsGranted,
      quietHoursStart: start,
      quietHoursEnd: end,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound,
      updatedAt: DateTime.now(),
      needsSync: true,
      lastSyncAt: lastSyncAt,
    );
  }

  // Actualizar configuración de snooze
  NotificationSettingsLocalModel updateSnoozeSettings(int minutes, int maxCount) {
    return NotificationSettingsLocalModel(
      userId: userId,
      globalNotificationsEnabled: globalNotificationsEnabled,
      permissionsGranted: permissionsGranted,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      defaultSnoozeMinutes: minutes,
      maxSnoozeCount: maxCount,
      defaultNotificationSound: defaultNotificationSound,
      updatedAt: DateTime.now(),
      needsSync: true,
      lastSyncAt: lastSyncAt,
    );
  }

  // Marcar como sincronizado
  NotificationSettingsLocalModel markAsSynced() {
    return NotificationSettingsLocalModel(
      userId: userId,
      globalNotificationsEnabled: globalNotificationsEnabled,
      permissionsGranted: permissionsGranted,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound,
      updatedAt: updatedAt,
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'user_id': userId,
      'global_notifications_enabled': globalNotificationsEnabled,
      'permissions_granted': permissionsGranted,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'default_snooze_minutes': defaultSnoozeMinutes,
      'max_snooze_count': maxSnoozeCount,
      'default_notification_sound': defaultNotificationSound,
      'updated_at': updatedAt.toIso8601String(),
    };
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
    return 'NotificationSettingsLocalModel(userId: $userId, globalEnabled: $globalNotificationsEnabled, permissionsGranted: $permissionsGranted)';
  }
}