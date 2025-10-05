import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/notification_log.dart';

part 'notification_log_local_model.g.dart';

@HiveType(typeId: 12)
class NotificationLogLocalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String notificationScheduleId;

  @HiveField(2)
  final DateTime scheduledFor;

  @HiveField(3)
  final DateTime? sentAt;

  @HiveField(4)
  final String status; // 'scheduled', 'sent', 'failed', 'cancelled'

  @HiveField(5)
  final String? actionTaken; // 'completed', 'snoozed', 'dismissed', 'ignored'

  @HiveField(6)
  final DateTime createdAt;

  NotificationLogLocalModel({
    required this.id,
    required this.notificationScheduleId,
    required this.scheduledFor,
    this.sentAt,
    required this.status,
    this.actionTaken,
    required this.createdAt,
  });

  // Convertir desde entidad de dominio
  factory NotificationLogLocalModel.fromEntity(NotificationLog log) {
    return NotificationLogLocalModel(
      id: log.id,
      notificationScheduleId: log.notificationScheduleId,
      scheduledFor: log.scheduledFor,
      sentAt: log.sentAt,
      status: log.statusString,
      actionTaken: log.actionString,
      createdAt: log.createdAt,
    );
  }

  // Convertir desde Map (para base de datos)
  factory NotificationLogLocalModel.fromMap(Map<String, dynamic> map) {
    return NotificationLogLocalModel(
      id: map['id'] as String,
      notificationScheduleId: map['notification_schedule_id'] as String,
      scheduledFor: DateTime.parse(map['scheduled_for'] as String),
      sentAt: map['sent_at'] != null 
          ? DateTime.parse(map['sent_at'] as String)
          : null,
      status: map['status'] as String,
      actionTaken: map['action_taken'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir a entidad de dominio
  NotificationLog toEntity() {
    return NotificationLog.fromStrings(
      id: id,
      notificationScheduleId: notificationScheduleId,
      scheduledFor: scheduledFor,
      sentAt: sentAt,
      statusString: status,
      actionString: actionTaken,
      createdAt: createdAt,
    );
  }

  // Convertir a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_schedule_id': notificationScheduleId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'status': status,
      'action_taken': actionTaken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Marcar como enviado
  NotificationLogLocalModel markAsSent() {
    return NotificationLogLocalModel(
      id: id,
      notificationScheduleId: notificationScheduleId,
      scheduledFor: scheduledFor,
      sentAt: DateTime.now(),
      status: 'sent',
      actionTaken: actionTaken,
      createdAt: createdAt,
    );
  }

  // Marcar como fallido
  NotificationLogLocalModel markAsFailed() {
    return NotificationLogLocalModel(
      id: id,
      notificationScheduleId: notificationScheduleId,
      scheduledFor: scheduledFor,
      sentAt: sentAt,
      status: 'failed',
      actionTaken: actionTaken,
      createdAt: createdAt,
    );
  }

  // Marcar como cancelado
  NotificationLogLocalModel markAsCancelled() {
    return NotificationLogLocalModel(
      id: id,
      notificationScheduleId: notificationScheduleId,
      scheduledFor: scheduledFor,
      sentAt: sentAt,
      status: 'cancelled',
      actionTaken: actionTaken,
      createdAt: createdAt,
    );
  }

  // Registrar acción del usuario
  NotificationLogLocalModel recordAction(String action) {
    return NotificationLogLocalModel(
      id: id,
      notificationScheduleId: notificationScheduleId,
      scheduledFor: scheduledFor,
      sentAt: sentAt,
      status: status,
      actionTaken: action,
      createdAt: createdAt,
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'notification_schedule_id': notificationScheduleId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'status': status,
      'action_taken': actionTaken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'NotificationLogLocalModel(id: $id, status: $status, actionTaken: $actionTaken)';
  }
}