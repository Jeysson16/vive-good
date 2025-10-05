import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC para el manejo de estado del chat
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _sessionsSubscription;
  
  ChatBloc({
    required ChatRepository chatRepository,
  }) : _chatRepository = chatRepository,
       super(const ChatInitial()) {
    
    // Registrar manejadores de eventos
    on<LoadUserSessions>(_onLoadUserSessions);
    on<CreateNewSession>(_onCreateNewSession);
    on<SelectSession>(_onSelectSession);
    on<LoadSessionMessages>(_onLoadSessionMessages);
    on<SendMessage>(_onSendMessage);
    on<SendUserMessage>(_onSendUserMessage);
    on<EditMessage>(_onEditMessage);
    on<StartEditingMessage>(_onStartEditingMessage);
    on<CancelEditingMessage>(_onCancelEditingMessage);
    on<RegenerateResponse>(_onRegenerateResponse);
    on<UpdateSessionTitle>(_onUpdateSessionTitle);
    on<DeleteSession>(_onDeleteSession);
    on<DeleteMessage>(_onDeleteMessage);
    on<SetTypingStatus>(_onSetTypingStatus);
    on<ClearError>(_onClearError);
    on<ResetChatState>(_onResetChatState);
    on<SubscribeToRealtimeUpdates>(_onSubscribeToRealtimeUpdates);
    on<UnsubscribeFromRealtimeUpdates>(_onUnsubscribeFromRealtimeUpdates);
  }
  
  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _sessionsSubscription?.cancel();
    return super.close();
  }
  
  /// Cargar sesiones del usuario
  Future<void> _onLoadUserSessions(
    LoadUserSessions event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const SessionsLoading());
      
      final sessions = await _chatRepository.getUserSessions(event.userId);
      
      if (sessions.isEmpty) {
        emit(const NoSessions());
      } else {
        emit(SessionsLoaded(sessions));
        
        // Suscribirse a actualizaciones de sesiones
        _sessionsSubscription?.cancel();
        _sessionsSubscription = _chatRepository
            .watchUserSessions(event.userId)
            .listen((updatedSessions) {
          if (!isClosed) {
            final currentState = state;
            if (currentState is SessionsLoaded) {
              emit(SessionsLoaded(updatedSessions));
            } else if (currentState is ChatLoaded) {
              emit(currentState.copyWith(sessions: updatedSessions));
            }
          }
        });
      }
    } catch (e) {
      emit(ChatError(message: 'Error al cargar sesiones: ${e.toString()}'));
    }
  }
  
  /// Crear nueva sesión
  Future<void> _onCreateNewSession(
    CreateNewSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      List<ChatSession> currentSessions = [];
      
      if (currentState is ChatLoaded) {
        currentSessions = currentState.sessions;
        emit(SessionCreating(currentSessions));
      } else if (currentState is SessionsLoaded) {
        currentSessions = currentState.sessions;
        emit(SessionCreating(currentSessions));
      } else {
        emit(const SessionsLoading());
      }
      
      final newSession = await _chatRepository.createSession(
        event.userId,
        title: event.title,
      );
      
      final updatedSessions = [newSession, ...currentSessions];
      
      emit(EmptySession(
        sessions: updatedSessions,
        currentSession: newSession,
      ));
    } catch (e) {
      List<ChatSession> sessions = [];
      if (state is ChatLoaded) {
        sessions = (state as ChatLoaded).sessions;
      } else if (state is SessionsLoaded) {
        sessions = (state as SessionsLoaded).sessions;
      }
      
      emit(ChatError(
        message: 'Error al crear sesión: ${e.toString()}',
        sessions: sessions,
      ));
    }
  }
  
  /// Seleccionar sesión activa
  Future<void> _onSelectSession(
    SelectSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      List<ChatSession> sessions = [];
      
      if (currentState is ChatLoaded) {
        sessions = currentState.sessions;
      } else if (currentState is SessionsLoaded) {
        sessions = currentState.sessions;
      } else {
        return;
      }
      
      final session = sessions
          .firstWhere((s) => s.id == event.sessionId);
      
      emit(MessagesLoading(
        sessions: sessions,
        currentSession: session,
      ));
      
      add(LoadSessionMessages(event.sessionId));
    } catch (e) {
      List<ChatSession> sessions = [];
      if (state is ChatLoaded) {
        sessions = (state as ChatLoaded).sessions;
      } else if (state is SessionsLoaded) {
        sessions = (state as SessionsLoaded).sessions;
      }
      
      emit(ChatError(
        message: 'Error al seleccionar sesión: ${e.toString()}',
        sessions: sessions,
      ));
    }
  }
  
  /// Cargar mensajes de una sesión
  Future<void> _onLoadSessionMessages(
    LoadSessionMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final messages = await _chatRepository.getSessionMessages(event.sessionId);
      
      final currentState = state;
      if (currentState is MessagesLoading) {
        if (messages.isEmpty) {
          emit(EmptySession(
            sessions: currentState.sessions,
            currentSession: currentState.currentSession!,
          ));
        } else {
          emit(ChatLoaded(
            sessions: currentState.sessions,
            currentSession: currentState.currentSession,
            messages: messages,
          ));
        }
        
        // Suscribirse a actualizaciones de mensajes
        add(SubscribeToRealtimeUpdates(event.sessionId));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Error al cargar mensajes: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Enviar mensaje
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded && currentState is! EmptySession) return;
      
      List<ChatSession> sessions = [];
      ChatSession? currentSession;
      List<ChatMessage> messages = [];
      
      if (currentState is ChatLoaded) {
        sessions = currentState.sessions;
        currentSession = currentState.currentSession;
        messages = currentState.messages;
      } else if (currentState is EmptySession) {
        sessions = currentState.sessions;
        currentSession = currentState.currentSession;
      }
      
      if (currentSession == null) return;
      
      emit(MessageSending(
        sessions: sessions,
        currentSession: currentSession,
        messages: messages,
      ));
      
      final newMessage = await _chatRepository.sendMessage(
        event.sessionId,
        event.content,
        event.type,
      );
      
      final updatedMessages = [...messages, newMessage];
      
      emit(ChatLoaded(
        sessions: sessions,
        currentSession: currentSession,
        messages: updatedMessages,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Error al enviar mensaje: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Enviar mensaje del usuario y generar respuesta automática
  Future<void> _onSendUserMessage(
    SendUserMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Primero enviar el mensaje del usuario
      add(SendMessage(
        sessionId: event.sessionId,
        content: event.content,
        type: MessageType.user,
      ));
      
      // Esperar un poco para que se procese el mensaje del usuario
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Indicar que el asistente está escribiendo
      add(const SetTypingStatus(true));
      
      // Generar respuesta del asistente
      final response = await _chatRepository.regenerateResponse(
        event.sessionId,
        event.content,
      );
      
      // Enviar la respuesta del asistente
      add(SendMessage(
        sessionId: event.sessionId,
        content: response.content,
        type: MessageType.assistant,
      ));
      
      // Detener indicador de escritura
      add(const SetTypingStatus(false));
    } catch (e) {
      add(const SetTypingStatus(false));
      emit(ChatError(
        message: 'Error al generar respuesta: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Editar mensaje
  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.editMessage(event.messageId, event.newContent);
      
      // Cancelar modo de edición
      add(const CancelEditingMessage());
      
      // Recargar mensajes
      final currentState = state;
      if (currentState is ChatLoaded && currentState.currentSession != null) {
        add(LoadSessionMessages(currentState.currentSession!.id));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Error al editar mensaje: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Iniciar edición de mensaje
  Future<void> _onStartEditingMessage(
    StartEditingMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    
    final message = currentState.messages
        .firstWhere((m) => m.id == event.messageId);
    
    emit(MessageEditing(
      sessions: currentState.sessions,
      currentSession: currentState.currentSession!,
      messages: currentState.messages,
      editingMessageId: event.messageId,
      editingContent: message.content,
    ));
  }
  
  /// Cancelar edición de mensaje
  Future<void> _onCancelEditingMessage(
    CancelEditingMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is MessageEditing) {
      emit(ChatLoaded(
        sessions: currentState.sessions,
        currentSession: currentState.currentSession,
        messages: currentState.messages,
      ));
    } else if (currentState is ChatLoaded) {
      emit(currentState.copyWith(clearEditingMessageId: true));
    }
  }
  
  /// Regenerar respuesta
  Future<void> _onRegenerateResponse(
    RegenerateResponse event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded) return;
      
      emit(ResponseRegenerating(
        sessions: currentState.sessions,
        currentSession: currentState.currentSession!,
        messages: currentState.messages,
      ));
      
      final newResponse = await _chatRepository.regenerateResponse(
        event.sessionId,
        event.lastUserMessage,
      );
      
      // Enviar la nueva respuesta
      add(SendMessage(
        sessionId: event.sessionId,
        content: newResponse.content,
        type: MessageType.assistant,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Error al regenerar respuesta: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Actualizar título de sesión
  Future<void> _onUpdateSessionTitle(
    UpdateSessionTitle event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.updateSessionTitle(event.sessionId, event.newTitle);
      
      // Recargar sesiones
      final currentState = state;
      if (currentState is ChatLoaded) {
        final updatedSessions = currentState.sessions.map((session) {
          if (session.id == event.sessionId) {
            return session.copyWith(title: event.newTitle);
          }
          return session;
        }).toList();
        
        emit(currentState.copyWith(sessions: updatedSessions));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Error al actualizar título: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Eliminar sesión
  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded) return;
      
      emit(SessionDeleting(
        sessions: currentState.sessions,
        currentSession: currentState.currentSession,
        messages: currentState.messages,
        deletingSessionId: event.sessionId,
      ));
      
      await _chatRepository.deleteSession(event.sessionId);
      
      final updatedSessions = currentState.sessions
          .where((session) => session.id != event.sessionId)
          .toList();
      
      if (updatedSessions.isEmpty) {
        emit(const NoSessions());
      } else {
        emit(ChatLoaded(sessions: updatedSessions));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Error al eliminar sesión: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Eliminar mensaje
  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(event.messageId);
      
      // Recargar mensajes
      final currentState = state;
      if (currentState is ChatLoaded && currentState.currentSession != null) {
        add(LoadSessionMessages(currentState.currentSession!.id));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Error al eliminar mensaje: ${e.toString()}',
        sessions: state is ChatLoaded ? (state as ChatLoaded).sessions : [],
      ));
    }
  }
  
  /// Establecer estado de escritura
  Future<void> _onSetTypingStatus(
    SetTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isAssistantTyping: event.isTyping));
    } else if (currentState is MessageSending) {
      emit(MessageSending(
        sessions: currentState.sessions,
        currentSession: currentState.currentSession,
        messages: currentState.messages,
        isAssistantTyping: event.isTyping,
      ));
    }
  }
  
  /// Limpiar errores
  Future<void> _onClearError(
    ClearError event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatError) {
      emit(ChatLoaded(
        sessions: currentState.sessions,
        currentSession: currentState.currentSession,
        messages: currentState.messages,
      ));
    }
  }
  
  /// Resetear estado del chat
  Future<void> _onResetChatState(
    ResetChatState event,
    Emitter<ChatState> emit,
  ) async {
    _messagesSubscription?.cancel();
    _sessionsSubscription?.cancel();
    emit(const ChatInitial());
  }
  
  /// Suscribirse a actualizaciones en tiempo real
  Future<void> _onSubscribeToRealtimeUpdates(
    SubscribeToRealtimeUpdates event,
    Emitter<ChatState> emit,
  ) async {
    _messagesSubscription?.cancel();
    
    _messagesSubscription = _chatRepository
        .watchSessionMessages(event.sessionId)
        .listen((updatedMessages) {
      if (!isClosed) {
        final currentState = state;
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(messages: updatedMessages));
        }
      }
    });
  }
  
  /// Desuscribirse de actualizaciones en tiempo real
  Future<void> _onUnsubscribeFromRealtimeUpdates(
    UnsubscribeFromRealtimeUpdates event,
    Emitter<ChatState> emit,
  ) async {
    _messagesSubscription?.cancel();
    _sessionsSubscription?.cancel();
  }
}