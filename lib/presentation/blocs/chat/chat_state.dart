import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat/chat_message.dart';

/// Estados base para el BLoC de chat
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial del chat
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Estado de carga
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Estado cuando se están cargando las sesiones
class SessionsLoading extends ChatState {
  const SessionsLoading();
}

/// Estado cuando se están cargando los mensajes
class MessagesLoading extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  
  const MessagesLoading({
    this.sessions = const [],
    this.currentSession,
  });
  
  @override
  List<Object?> get props => [sessions, currentSession];
}

/// Estado cuando se está enviando un mensaje
class MessageSending extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession currentSession;
  final List<ChatMessage> messages;
  final bool isAssistantTyping;
  
  const MessageSending({
    required this.sessions,
    required this.currentSession,
    required this.messages,
    this.isAssistantTyping = false,
  });
  
  @override
  List<Object?> get props => [sessions, currentSession, messages, isAssistantTyping];
}

/// Estado cuando el asistente está escribiendo
class AssistantTyping extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession currentSession;
  final List<ChatMessage> messages;
  
  const AssistantTyping({
    required this.sessions,
    required this.currentSession,
    required this.messages,
  });
  
  @override
  List<Object?> get props => [sessions, currentSession, messages];
}

/// Estado cuando se está editando un mensaje
class MessageEditing extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession currentSession;
  final List<ChatMessage> messages;
  final String editingMessageId;
  final String editingContent;
  
  const MessageEditing({
    required this.sessions,
    required this.currentSession,
    required this.messages,
    required this.editingMessageId,
    required this.editingContent,
  });
  
  @override
  List<Object?> get props => [
    sessions,
    currentSession,
    messages,
    editingMessageId,
    editingContent,
  ];
}

/// Estado cuando se está regenerando una respuesta
class ResponseRegenerating extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession currentSession;
  final List<ChatMessage> messages;
  
  const ResponseRegenerating({
    required this.sessions,
    required this.currentSession,
    required this.messages,
  });
  
  @override
  List<Object?> get props => [sessions, currentSession, messages];
}

/// Estado exitoso con datos cargados
class ChatLoaded extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final bool isAssistantTyping;
  final String? editingMessageId;
  
  const ChatLoaded({
    this.sessions = const [],
    this.currentSession,
    this.messages = const [],
    this.isAssistantTyping = false,
    this.editingMessageId,
  });
  
  /// Crea una copia del estado con algunos campos modificados
  ChatLoaded copyWith({
    List<ChatSession>? sessions,
    ChatSession? currentSession,
    List<ChatMessage>? messages,
    bool? isAssistantTyping,
    String? editingMessageId,
    bool clearCurrentSession = false,
    bool clearEditingMessageId = false,
  }) {
    return ChatLoaded(
      sessions: sessions ?? this.sessions,
      currentSession: clearCurrentSession ? null : (currentSession ?? this.currentSession),
      messages: messages ?? this.messages,
      isAssistantTyping: isAssistantTyping ?? this.isAssistantTyping,
      editingMessageId: clearEditingMessageId ? null : (editingMessageId ?? this.editingMessageId),
    );
  }
  
  @override
  List<Object?> get props => [
    sessions,
    currentSession,
    messages,
    isAssistantTyping,
    editingMessageId,
  ];
}

/// Estado de error
class ChatError extends ChatState {
  final String message;
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  
  const ChatError({
    required this.message,
    this.sessions = const [],
    this.currentSession,
    this.messages = const [],
  });
  
  @override
  List<Object?> get props => [message, sessions, currentSession, messages];
}

/// Estado cuando no hay sesiones
class NoSessions extends ChatState {
  const NoSessions();
}

/// Estado cuando las sesiones han sido cargadas exitosamente
class SessionsLoaded extends ChatState {
  final List<ChatSession> sessions;
  
  const SessionsLoaded(this.sessions);
  
  @override
  List<Object?> get props => [sessions];
}

/// Estado cuando una sesión está vacía (sin mensajes)
class EmptySession extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession currentSession;
  
  const EmptySession({
    required this.sessions,
    required this.currentSession,
  });
  
  @override
  List<Object?> get props => [sessions, currentSession];
}

/// Estado cuando se está creando una nueva sesión
class SessionCreating extends ChatState {
  final List<ChatSession> sessions;
  
  const SessionCreating(this.sessions);
  
  @override
  List<Object?> get props => [sessions];
}

/// Estado cuando se está eliminando una sesión
class SessionDeleting extends ChatState {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final String deletingSessionId;
  
  const SessionDeleting({
    required this.sessions,
    this.currentSession,
    this.messages = const [],
    required this.deletingSessionId,
  });
  
  @override
  List<Object?> get props => [sessions, currentSession, messages, deletingSessionId];
}