import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_log.dart';

part 'notification_log_model.g.dart';

@HiveType(typeId: 5)
class NotificationLogModel extends NotificationLog {
  @HiveField(0)
  @override
  final String id;
  
  @HiveField(1)
  @override
  final String notificationScheduleId;
  
  @HiveField(2)
  @override
  final DateTime scheduledFor;
  
  @HiveField(3)
  @override
  final DateTime? sentAt;
  
  @HiveField(4)
  @override
  final NotificationStatus status;
  
  @HiveField(5)
  @override
  final NotificationAction? actionTaken;
  
  @HiveField(6)
  @override
  final DateTime createdAt;

  const NotificationLogModel({
    required this.id,
    required this.notificationScheduleId,
    required this.scheduledFor,
    this.sentAt,
    required this.status,
    this.actionTaken,
    required this.createdAt,
  }) : super(
          id: id,
          notificationScheduleId: notificationScheduleId,
          scheduledFor: scheduledFor,
          sentAt: sentAt,
          status: status,
          actionTaken: actionTaken,
          createdAt: createdAt,
        );

  factory NotificationLogModel.fromEntity(NotificationLog log) {
    return NotificationLogModel(
      id: log.id,
      notificationScheduleId: log.notificationScheduleId,
      scheduledFor: log.scheduledFor,
      sentAt: log.sentAt,
      status: log.status,
      actionTaken: log.actionTaken,
      createdAt: log.createdAt,
    );
  }

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) {
    return NotificationLogModel(
      id: json['id'] as String,
      notificationScheduleId: json['notification_schedule_id'] as String,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.scheduled,
      ),
      actionTaken: json['action_taken'] != null 
        ? NotificationAction.values.firstWhere(
            (e) => e.name == json['action_taken'],
            orElse: () => NotificationAction.ignored,
          )
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_schedule_id': notificationScheduleId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'status': status.name,
      'action_taken': actionTaken?.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  NotificationLogModel copyWith({
    String? id,
    String? notificationScheduleId,
    DateTime? scheduledFor,
    DateTime? sentAt,
    NotificationStatus? status,
    NotificationAction? actionTaken,
    DateTime? createdAt,
  }) {
    return NotificationLogModel(
      id: id ?? this.id,
      notificationScheduleId: notificationScheduleId ?? this.notificationScheduleId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        notificationScheduleId,
        scheduledFor,
        sentAt,
        status,
        actionTaken,
        createdAt,
      ];
}