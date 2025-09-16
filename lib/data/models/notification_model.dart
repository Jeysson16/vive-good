import '../../domain/entities/notification.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    super.body,
    required super.type,
    super.relatedId,
    super.data,
    super.isRead = false,
    super.readAt,
    super.scheduledFor,
    super.sentAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String,
      relatedId: json['related_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      scheduledFor: json['scheduled_for'] != null 
          ? DateTime.parse(json['scheduled_for'] as String) 
          : null,
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    final json = toJson();
    json.remove('id'); // Remove ID for insert operations
    json.remove('created_at'); // Let database handle created_at
    json.remove('updated_at'); // Let database handle updated_at
    return json;
  }

  Map<String, dynamic> toJsonForUpdate() {
    final json = toJson();
    json.remove('id'); // Remove ID for update operations
    json.remove('created_at'); // Don't update created_at
    json.remove('updated_at'); // Let database handle updated_at
    return json;
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      relatedId: entity.relatedId,
      data: entity.data,
      isRead: entity.isRead,
      readAt: entity.readAt,
      scheduledFor: entity.scheduledFor,
      sentAt: entity.sentAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  NotificationModel copyWith({
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
    return NotificationModel(
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
}