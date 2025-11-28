import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/chat/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../services/supabase_realtime_service.dart';

/// Excepción personalizada para errores del datasource de chat
class ChatDataSourceException implements Exception {
  final String message;
  final String? code;

  const ChatDataSourceException(this.message, {this.code});

  @override
  String toString() => 'ChatDataSourceException: $message';
}

/// Datasource remoto para operaciones de chat con Supabase
class ChatRemoteDataSource {
  final SupabaseClient _client;
  final SupabaseRealtimeService _realtimeService;

  ChatRemoteDataSource(this._client) : _realtimeService = SupabaseRealtimeService();

  /// Obtiene todas las sesiones de chat de un usuario
  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      final response = await _client
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ChatSession.fromMap(json))
          .toList();
    } catch (e) {
      throw ChatDataSourceException(
        'Error al obtener sesiones del usuario: ${e.toString()}',
      );
    }
  }

  /// Crea una nueva sesión de chat
  Future<ChatSession> createSession(String userId, {String? title}) async {
    try {
      final response = await _client
          .from('chat_sessions')
          .insert({'user_id': userId, 'title': title ?? 'Nueva conversación'})
          .select()
          .single();

      return ChatSession.fromMap(response);
    } catch (e) {
      throw ChatDataSourceException('Error al crear sesión: ${e.toString()}');
    }
  }

  /// Obtiene todos los mensajes de una sesión específica
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromMap(json))
          .toList();
    } catch (e) {
      throw ChatDataSourceException(
        'Error al obtener mensajes de la sesión: ${e.toString()}',
      );
    }
  }

  /// Envía un nuevo mensaje a una sesión
  Future<ChatMessage> sendMessage(
    String sessionId,
    String content,
    MessageType messageType, {
    Map<String, dynamic>? metadata
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .insert({
            'session_id': sessionId,
            'content': content,
            'message_type': messageType.name,
            if (metadata != null) 'metadata': metadata,
          })
          .select()
          .single();

      return ChatMessage.fromMap(response);
    } catch (e) {
      throw ChatDataSourceException('Error al enviar mensaje: ${e.toString()}');
    }
  }

  /// Edita un mensaje existente
  Future<ChatMessage> editMessage(String messageId, String newContent) async {
    try {
      final response = await _client
          .from('chat_messages')
          .update({'content': newContent, 'is_editing': false})
          .eq('id', messageId)
          .select()
          .single();

      return ChatMessage.fromMap(response);
    } catch (e) {
      throw ChatDataSourceException('Error al editar mensaje: ${e.toString()}');
    }
  }

  /// Actualiza el título de una sesión
  Future<ChatSession> updateSessionTitle(
    String sessionId,
    String newTitle,
  ) async {
    try {
      final response = await _client
          .from('chat_sessions')
          .update({'title': newTitle})
          .eq('id', sessionId)
          .select()
          .single();

      return ChatSession.fromMap(response);
    } catch (e) {
      throw ChatDataSourceException(
        'Error al actualizar título de sesión: ${e.toString()}',
      );
    }
  }

  /// Elimina una sesión de chat
  Future<void> deleteSession(String sessionId) async {
    try {
      await _client.from('chat_sessions').delete().eq('id', sessionId);
    } catch (e) {
      throw ChatDataSourceException(
        'Error al eliminar sesión: ${e.toString()}',
      );
    }
  }

  /// Elimina un mensaje específico
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      throw ChatDataSourceException(
        'Error al eliminar mensaje: ${e.toString()}',
      );
    }
  }

  /// Actualiza el estado de actividad de una sesión
  Future<ChatSession> updateSessionStatus(
    String sessionId,
    bool isActive,
  ) async {
    try {
      final response = await _client
          .from('chat_sessions')
          .update({'is_active': isActive})
          .eq('id', sessionId)
          .select()
          .single();

      return ChatSession.fromMap(response);
    } catch (e) {
      throw ChatDataSourceException(
        'Error al actualizar estado de sesión: ${e.toString()}',
      );
    }
  }

  /// Obtiene la sesión activa del usuario
  Future<ChatSession?> getActiveSession(String userId) async {
    try {
      final response = await _client
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? ChatSession.fromMap(response) : null;
    } catch (e) {
      throw ChatDataSourceException(
        'Error al obtener sesión activa: ${e.toString()}',
      );
    }
  }

  /// Suscripción en tiempo real a los mensajes de una sesión
  Stream<List<ChatMessage>> watchSessionMessages(String sessionId) {
    try {
      return _client
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('session_id', sessionId)
          .order('created_at')
          .map((data) => data.map((json) => ChatMessage.fromMap(json)).toList())
          .handleError((error) {
            _realtimeService.handleStreamError(error, 'mensajes de sesión');
          });
    } catch (e) {
      throw ChatDataSourceException(
        'Error al suscribirse a mensajes: ${e.toString()}',
      );
    }
  }

  /// Suscripción en tiempo real a las sesiones del usuario
  Stream<List<ChatSession>> watchUserSessions(String userId) {
    try {
      return _client
          .from('chat_sessions')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .map((data) => data.map((json) => ChatSession.fromMap(json)).toList())
          .handleError((error) {
            _realtimeService.handleStreamError(error, 'sesiones de usuario');
          });
    } catch (e) {
      throw ChatDataSourceException(
        'Error al suscribirse a sesiones: ${e.toString()}',
      );
    }
  }
}
