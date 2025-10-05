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
  final String notificationId;
  
  @HiveField(2)
  @override
  final String action;
  
  @HiveField(3)
  @override
  final DateTime timestamp;
  
  @HiveField(4)
  @override
  final String? details;
  
  @HiveField(5)
  @override
  final String? errorMessage;

  const NotificationLogModel({
    required this.id,
    required this.notificationId,
    required this.action,
    required this.timestamp,
    this.details,
    this.errorMessage,
  }) : super(
          id: id,
          notificationId: notificationId,
          action: action,
          timestamp: timestamp,
          details: details,
          errorMessage: errorMessage,
        );

  factory NotificationLogModel.fromEntity(NotificationLog log) {
    return NotificationLogModel(
      id: log.id,
      notificationId: log.notificationId,
      action: log.action,
      timestamp: log.timestamp,
      details: log.details,
      errorMessage: log.errorMessage,
    );
  }

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) {
    return NotificationLogModel(
      id: json['id'] as String,
      notificationId: json['notificationId'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notificationId': notificationId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'errorMessage': errorMessage,
    };
  }

  NotificationLogModel copyWith({
    String? id,
    String? notificationId,
    String? action,
    DateTime? timestamp,
    String? details,
    String? errorMessage,
  }) {
    return NotificationLogModel(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        notificationId,
        action,
        timestamp,
        details,
        errorMessage,
      ];
}