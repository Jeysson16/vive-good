import '../../../domain/entities/chat/chat_session.dart';
import 'chat_message_model.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.messages,
    super.metadata,
    super.lastMessagePreview,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((messageJson) => ChatMessageModel.fromJson(messageJson))
              .toList()
          : [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      lastMessagePreview: json['last_message_preview'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'last_message_preview': lastMessagePreview,
    };
  }

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messages: entity.messages,
      metadata: entity.metadata,
      lastMessagePreview: entity.lastMessagePreview,
    );
  }

  ChatSession toEntity() {
    return ChatSession(
      id: id,
      userId: userId,
      title: title,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: messages,
      metadata: metadata,
      lastMessagePreview: lastMessagePreview,
    );
  }

  static ChatSessionModel create({
    required String userId,
    required String title,
  }) {
    final now = DateTime.now();
    return ChatSessionModel(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      status: SessionStatus.active,
      createdAt: now,
      messages: [],
    );
  }
}