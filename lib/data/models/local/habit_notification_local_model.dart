import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/habit_notification.dart';
import 'notification_schedule_local_model.dart';

part 'habit_notification_local_model.g.dart';

@HiveType(typeId: 10)
class HabitNotificationLocalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userHabitId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? message;

  @HiveField(4)
  final bool isEnabled;

  @HiveField(5)
  final String? notificationSound;

  @HiveField(6)
  final List<NotificationScheduleLocalModel> schedules;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final bool isSynced;

  @HiveField(10)
  final bool needsSync;

  @HiveField(11)
  final DateTime? lastSyncAt;

  HabitNotificationLocalModel({
    required this.id,
    required this.userHabitId,
    required this.title,
    this.message,
    this.isEnabled = true,
    this.notificationSound,
    this.schedules = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.needsSync = false,
    this.lastSyncAt,
  });

  // Convertir desde entidad de dominio
  factory HabitNotificationLocalModel.fromEntity(HabitNotification notification) {
    return HabitNotificationLocalModel(
      id: notification.id,
      userHabitId: notification.userHabitId,
      title: notification.title,
      message: notification.message,
      isEnabled: notification.isEnabled,
      notificationSound: notification.notificationSound,
      schedules: notification.schedules
          .map((schedule) => NotificationScheduleLocalModel.fromEntity(schedule))
          .toList(),
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
      isSynced: notification.isSynced,
    );
  }

  // Convertir desde Map (para base de datos)
  factory HabitNotificationLocalModel.fromMap(Map<String, dynamic> map) {
    return HabitNotificationLocalModel(
      id: map['id'] as String,
      userHabitId: map['related_id'] as String, // related_id contiene el user_habit_id
      title: map['title'] as String,
      message: map['body'] as String?, // body en lugar de message
      isEnabled: (map['is_read'] as int?) != 1, // invertir lógica: no leído = habilitado
      notificationSound: null, // no hay campo notification_sound en la nueva tabla
      schedules: [], // Los schedules se cargan por separado
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
      needsSync: (map['needs_sync'] as int?) == 1,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
    );
  }

  // Convertir a entidad de dominio
  HabitNotification toEntity() {
    return HabitNotification(
      id: id,
      userHabitId: userHabitId,
      title: title,
      message: message,
      isEnabled: isEnabled,
      notificationSound: notificationSound,
      schedules: schedules.map((schedule) => schedule.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
    );
  }

  // Convertir a Map (para base de datos)
  // Nota: user_id se establece en el repositorio usando el usuario autenticado
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': message,
      'type': 'habit_reminder',
      'related_id': userHabitId,
      'data': null,
      'is_read': isEnabled ? 0 : 1, // invertir lógica
      'read_at': null,
      'scheduled_for': null,
      'sent_at': null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'needs_sync': needsSync ? 1 : 0,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  // Marcar como que necesita sincronización
  HabitNotificationLocalModel markAsNeedsSync() {
    return HabitNotificationLocalModel(
      id: id,
      userHabitId: userHabitId,
      title: title,
      message: message,
      isEnabled: isEnabled,
      notificationSound: notificationSound,
      schedules: schedules,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced,
      needsSync: true,
      lastSyncAt: lastSyncAt,
    );
  }

  // Marcar como sincronizado
  HabitNotificationLocalModel markAsSynced() {
    return HabitNotificationLocalModel(
      id: id,
      userHabitId: userHabitId,
      title: title,
      message: message,
      isEnabled: isEnabled,
      notificationSound: notificationSound,
      schedules: schedules,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: true,
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'user_habit_id': userHabitId,
      'title': title,
      'message': message,
      'is_enabled': isEnabled,
      'notification_sound': notificationSound,
      'schedules': schedules.map((schedule) => schedule.toSyncMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'HabitNotificationLocalModel(id: $id, userHabitId: $userHabitId, title: $title, isEnabled: $isEnabled)';
  }
}