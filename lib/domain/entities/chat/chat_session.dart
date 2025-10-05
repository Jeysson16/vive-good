import 'package:equatable/equatable.dart';
import 'chat_message.dart';

enum SessionStatus { active, archived, deleted }

class ChatSession extends Equatable {
  final String id;
  final String userId;
  final String title;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatMessage> messages;
  final Map<String, dynamic>? metadata;
  final String? lastMessagePreview;

  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
    this.metadata,
    this.lastMessagePreview,
  });

  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    Map<String, dynamic>? metadata,
    String? lastMessagePreview,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }

  ChatSession addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
      lastMessagePreview: message.content.length > 50
          ? '${message.content.substring(0, 50)}...'
          : message.content,
    );
  }

  ChatSession updateMessage(ChatMessage updatedMessage) {
    final updatedMessages = messages.map((message) {
      return message.id == updatedMessage.id ? updatedMessage : message;
    }).toList();

    return copyWith(messages: updatedMessages, updatedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    status,
    createdAt,
    updatedAt,
    messages,
    metadata,
    lastMessagePreview,
  ];
}