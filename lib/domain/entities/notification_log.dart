import 'package:equatable/equatable.dart';

enum NotificationStatus {
  scheduled,
  sent,
  failed,
  cancelled,
}

enum NotificationAction {
  completed,
  snoozed,
  dismissed,
  ignored,
}

class NotificationLog extends Equatable {
  final String id;
  final String notificationScheduleId;
  final DateTime scheduledFor;
  final DateTime? sentAt;
  final NotificationStatus status;
  final NotificationAction? actionTaken;
  final DateTime createdAt;

  const NotificationLog({
    required this.id,
    required this.notificationScheduleId,
    required this.scheduledFor,
    this.sentAt,
    required this.status,
    this.actionTaken,
    required this.createdAt,
  });

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

  NotificationLog copyWith({
    String? id,
    String? notificationScheduleId,
    DateTime? scheduledFor,
    DateTime? sentAt,
    NotificationStatus? status,
    NotificationAction? actionTaken,
    DateTime? createdAt,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      notificationScheduleId: notificationScheduleId ?? this.notificationScheduleId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convierte el enum a string para almacenamiento
  String get statusString => status.name;
  String? get actionString => actionTaken?.name;

  /// Crea un NotificationLog desde strings
  static NotificationLog fromStrings({
    required String id,
    required String notificationScheduleId,
    required DateTime scheduledFor,
    DateTime? sentAt,
    required String statusString,
    String? actionString,
    required DateTime createdAt,
  }) {
    final status = NotificationStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => NotificationStatus.scheduled,
    );

    NotificationAction? action;
    if (actionString != null) {
      action = NotificationAction.values.firstWhere(
        (e) => e.name == actionString,
        orElse: () => NotificationAction.ignored,
      );
    }

    return NotificationLog(
      id: id,
      notificationScheduleId: notificationScheduleId,
      scheduledFor: scheduledFor,
      sentAt: sentAt,
      status: status,
      actionTaken: action,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationLog(id: $id, status: $status, actionTaken: $actionTaken)';
  }
}