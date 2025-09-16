import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String type; // 'habit_reminder', 'habit_completion', 'system', 'achievement'
  final String? relatedId; // ID of related entity (habit, event, etc.)
  final Map<String, dynamic>? data; // Additional data for the notification
  final bool isRead;
  final DateTime? readAt;
  final DateTime? scheduledFor; // When the notification should be sent
  final DateTime? sentAt; // When the notification was actually sent
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    required this.type,
    this.relatedId,
    this.data,
    this.isRead = false,
    this.readAt,
    this.scheduledFor,
    this.sentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        relatedId,
        data,
        isRead,
        readAt,
        scheduledFor,
        sentAt,
        createdAt,
        updatedAt,
      ];

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NotificationEntity(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}