import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/chat_message.dart';

/// Eventos base para el BLoC de chat
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar las sesiones del usuario
class LoadUserSessions extends ChatEvent {
  final String userId;
  
  const LoadUserSessions(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

/// Evento para crear una nueva sesión
class CreateNewSession extends ChatEvent {
  final String userId;
  final String? title;
  
  const CreateNewSession(this.userId, {this.title});
  
  @override
  List<Object?> get props => [userId, title];
}

/// Evento para seleccionar una sesión activa
class SelectSession extends ChatEvent {
  final String sessionId;
  
  const SelectSession(this.sessionId);
  
  @override
  List<Object?> get props => [sessionId];
}

/// Evento para cargar mensajes de una sesión
class LoadSessionMessages extends ChatEvent {
  final String sessionId;
  
  const LoadSessionMessages(this.sessionId);
  
  @override
  List<Object?> get props => [sessionId];
}

/// Evento para enviar un mensaje
class SendMessage extends ChatEvent {
  final String sessionId;
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  
  const SendMessage({
    required this.sessionId,
    required this.content,
    this.type = MessageType.user,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [sessionId, content, type, metadata];
}

/// Evento para enviar mensaje del usuario y generar respuesta automática
class SendUserMessage extends ChatEvent {
  final String sessionId;
  final String content;
  
  const SendUserMessage({
    required this.sessionId,
    required this.content,
  });
  
  @override
  List<Object?> get props => [sessionId, content];
}

/// Evento para editar un mensaje
class EditMessage extends ChatEvent {
  final String messageId;
  final String newContent;
  
  const EditMessage({
    required this.messageId,
    required this.newContent,
  });
  
  @override
  List<Object?> get props => [messageId, newContent];
}

/// Evento para iniciar la edición de un mensaje
class StartEditingMessage extends ChatEvent {
  final String messageId;
  
  const StartEditingMessage(this.messageId);
  
  @override
  List<Object?> get props => [messageId];
}

/// Evento para cancelar la edición de un mensaje
class CancelEditingMessage extends ChatEvent {
  const CancelEditingMessage();
}

/// Evento para regenerar la respuesta del asistente
class RegenerateResponse extends ChatEvent {
  final String sessionId;
  final String lastUserMessage;
  
  const RegenerateResponse({
    required this.sessionId,
    required this.lastUserMessage,
  });
  
  @override
  List<Object?> get props => [sessionId, lastUserMessage];
}

/// Evento para actualizar el título de una sesión
class UpdateSessionTitle extends ChatEvent {
  final String sessionId;
  final String newTitle;
  
  const UpdateSessionTitle({
    required this.sessionId,
    required this.newTitle,
  });
  
  @override
  List<Object?> get props => [sessionId, newTitle];
}

/// Evento para eliminar una sesión
class DeleteSession extends ChatEvent {
  final String sessionId;
  
  const DeleteSession(this.sessionId);
  
  @override
  List<Object?> get props => [sessionId];
}

/// Evento para eliminar un mensaje
class DeleteMessage extends ChatEvent {
  final String messageId;
  
  const DeleteMessage(this.messageId);
  
  @override
  List<Object?> get props => [messageId];
}

/// Evento para indicar que el asistente está escribiendo
class SetTypingStatus extends ChatEvent {
  final bool isTyping;
  
  const SetTypingStatus(this.isTyping);
  
  @override
  List<Object?> get props => [isTyping];
}

/// Evento para limpiar errores
class ClearError extends ChatEvent {
  const ClearError();
}

/// Evento para resetear el estado del chat
class ResetChatState extends ChatEvent {
  const ResetChatState();
}

/// Evento para suscribirse a actualizaciones en tiempo real
class SubscribeToRealtimeUpdates extends ChatEvent {
  final String sessionId;
  
  const SubscribeToRealtimeUpdates(this.sessionId);
  
  @override
  List<Object?> get props => [sessionId];
}

/// Evento para desuscribirse de actualizaciones en tiempo real
class UnsubscribeFromRealtimeUpdates extends ChatEvent {
  const UnsubscribeFromRealtimeUpdates();
}