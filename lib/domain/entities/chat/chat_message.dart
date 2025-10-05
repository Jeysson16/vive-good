import 'package:equatable/equatable.dart';

enum MessageType {
  user,
  assistant,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
  generating,
  regenerating,
}

class ChatMessage extends Equatable {
  final String id;
  final String sessionId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? parentMessageId; // Para respuestas regeneradas
  final bool isEdited;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.parentMessageId,
    this.isEdited = false,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? parentMessageId,
    bool? isEdited,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  // Método para crear ChatMessage desde Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      sessionId: map['session_id'] ?? '',
      content: map['content'] ?? '',
      type: _messageTypeFromString(map['message_type'] ?? 'user'),
      status: _messageStatusFromString(map['status'] ?? 'sent'),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      metadata: map['metadata'],
      parentMessageId: map['parent_message_id'],
      isEdited: map['is_edited'] ?? false,
    );
  }

  // Método para convertir ChatMessage a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'message_type': type.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'parent_message_id': parentMessageId,
      'is_edited': isEdited,
    };
  }

  // Métodos auxiliares para conversión de enums
  static MessageType _messageTypeFromString(String type) {
    switch (type) {
      case 'user':
        return MessageType.user;
      case 'assistant':
        return MessageType.assistant;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.user;
    }
  }

  static MessageStatus _messageStatusFromString(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'failed':
        return MessageStatus.failed;
      case 'generating':
        return MessageStatus.generating;
      case 'regenerating':
        return MessageStatus.regenerating;
      default:
        return MessageStatus.sent;
    }
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        content,
        type,
        status,
        createdAt,
        updatedAt,
        metadata,
        parentMessageId,
        isEdited,
      ];
}