import '../../../domain/entities/chat/chat_message.dart';

class ChatMessageLocalModel {
  final String id;
  final String sessionId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? parentMessageId;
  final bool isEdited;
  final bool isSynced;
  final DateTime? lastSyncAt;

  const ChatMessageLocalModel({
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
    required this.isSynced,
    this.lastSyncAt,
  });

  // Conversión desde Map (SQLite)
  factory ChatMessageLocalModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageLocalModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      content: map['content'] as String,
      type: _messageTypeFromString(map['message_type'] as String? ?? 'user'),
      status: _messageStatusFromString(map['status'] as String? ?? 'sent'),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      parentMessageId: map['parent_message_id'] as String?,
      isEdited: (map['is_edited'] as int?) == 1,
      isSynced: (map['is_synced'] as int) == 1,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
    );
  }

  // Conversión a Map (SQLite)
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
      'is_edited': isEdited ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'last_sync_at': lastSyncAt?.toIso8601String(),
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

  // Conversión desde entidad de dominio
  factory ChatMessageLocalModel.fromEntity(ChatMessage message, {bool isSynced = false}) {
    return ChatMessageLocalModel(
      id: message.id,
      sessionId: message.sessionId,
      content: message.content,
      type: message.type,
      status: message.status,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      metadata: message.metadata,
      parentMessageId: message.parentMessageId,
      isEdited: message.isEdited,
      isSynced: isSynced,
    );
  }

  // Conversión a entidad de dominio
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      content: content,
      type: type,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
      parentMessageId: parentMessageId,
      isEdited: isEdited,
    );
  }

  // Crear copia con cambios
  ChatMessageLocalModel copyWith({
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
    bool? isSynced,
    DateTime? lastSyncAt,
  }) {
    return ChatMessageLocalModel(
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
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return 'ChatMessageLocalModel(id: $id, sessionId: $sessionId, type: $type, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatMessageLocalModel &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.content == content &&
        other.type == type &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.metadata == metadata &&
        other.parentMessageId == parentMessageId &&
        other.isEdited == isEdited &&
        other.isSynced == isSynced &&
        other.lastSyncAt == lastSyncAt;
  }

  @override
  int get hashCode {
    return Object.hash(
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
      isSynced,
      lastSyncAt,
    );
  }
}