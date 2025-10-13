import 'package:vive_good_app/domain/entities/chat/chat_message.dart';
import 'package:vive_good_app/domain/entities/chat_session.dart';
import 'package:vive_good_app/domain/entities/assistant/assistant_response.dart';
import 'package:vive_good_app/domain/repositories/chat_repository.dart';
import 'package:vive_good_app/data/datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<ChatSession>> getUserSessions(String userId) async {
    return await _remoteDataSource.getUserSessions(userId);
  }

  @override
  Future<ChatSession> createSession(String userId, {String? title}) async {
    return await _remoteDataSource.createSession(userId, title: title);
  }

  @override
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    return await _remoteDataSource.getSessionMessages(sessionId);
  }

  @override
  Future<ChatMessage> sendMessage(
    String sessionId,
    String content,
    MessageType messageType,
    {Map<String, dynamic>? metadata}
  ) async {
    return await _remoteDataSource.sendMessage(
      sessionId,
      content,
      messageType,
      metadata: metadata,
    );
  }

  @override
  Future<ChatMessage> editMessage(String messageId, String newContent) async {
    return await _remoteDataSource.editMessage(messageId, newContent);
  }

  @override
  Future<ChatMessage> regenerateResponse(String sessionId, String lastUserMessage) async {
    try {
      print('🔥 DEBUG: ChatRepositoryImpl.regenerateResponse llamado');
      print('🔥 DEBUG: SessionId: $sessionId, LastUserMessage: $lastUserMessage');
      
      // Generar una nueva respuesta usando la lógica similar a sendMessageToGemini
      final assistantResponse = await sendMessageToGemini(
        message: lastUserMessage,
        sessionId: sessionId,
        userId: 'current_user', // En una implementación real, esto vendría del contexto
      );
      
      // Crear un nuevo mensaje del asistente basado en la respuesta
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        content: assistantResponse.content,
        type: MessageType.assistant,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        metadata: {
          'regenerated': true,
          'original_message': lastUserMessage,
          'source': 'regenerate_response',
          ...?assistantResponse.metadata,
        },
      );
      
      print('🔥 DEBUG: Mensaje regenerado creado: ${newMessage.content}');
      return newMessage;
      
    } catch (e) {
      print('🔥 DEBUG: Error en regenerateResponse: $e');
      
      // Crear un mensaje de fallback en caso de error
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        content: 'Lo siento, no pude regenerar la respuesta en este momento. Por favor, intenta de nuevo.',
        type: MessageType.assistant,
        status: MessageStatus.failed,
        createdAt: DateTime.now(),
        metadata: {
          'regenerated': true,
          'error': true,
          'error_message': e.toString(),
        },
      );
    }
  }

  @override
  Future<ChatSession> updateSessionTitle(String sessionId, String newTitle) async {
    return await _remoteDataSource.updateSessionTitle(sessionId, newTitle);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    return await _remoteDataSource.deleteSession(sessionId);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    return await _remoteDataSource.deleteMessage(messageId);
  }

  @override
  Future<ChatSession> updateSessionStatus(String sessionId, bool isActive) async {
    return await _remoteDataSource.updateSessionStatus(sessionId, isActive);
  }

  @override
  Future<ChatSession?> getActiveSession(String userId) async {
    return await _remoteDataSource.getActiveSession(userId);
  }

  @override
  Stream<List<ChatMessage>> watchSessionMessages(String sessionId) {
    return _remoteDataSource.watchSessionMessages(sessionId);
  }

  @override
  Stream<List<ChatSession>> watchUserSessions(String userId) {
    return _remoteDataSource.watchUserSessions(userId);
  }

  // Métodos del asistente - implementaciones básicas
  @override
  Future<AssistantResponse> sendMessageToGemini({
    required String message,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      print('🔥 DEBUG: ChatRepositoryImpl.sendMessageToGemini llamado');
      print('🔥 DEBUG: Mensaje: $message');
      
      // Respuesta básica de fallback
      return AssistantResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        content: 'Hola, soy tu asistente de salud. ¿En qué puedo ayudarte hoy? Puedes contarme sobre tus síntomas, hábitos alimenticios o cualquier pregunta relacionada con tu bienestar.',
        type: ResponseType.text,
        timestamp: DateTime.now(),
        metadata: {
          'source': 'fallback_response',
          'repository': 'ChatRepositoryImpl',
        },
      );
    } catch (e) {
      print('🔥 DEBUG: Error en sendMessageToGemini: $e');
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  @override
  Future<AssistantResponse> processVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
  }) async {
    throw UnimplementedError('processVoiceMessage not implemented yet');
  }

  @override
  Future<Map<String, dynamic>> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> symptoms,
    required List<Map<String, dynamic>> habitHistory,
  }) async {
    try {
      print('🔥 DEBUG: ChatRepositoryImpl.analyzeGastritisRisk llamado');
      
      // Crear un mensaje descriptivo de los síntomas para el análisis
      final symptomsText = symptoms.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .join(', ');
      
      print('🔥 DEBUG: Síntomas detectados: $symptomsText');
      
      // Retornar un análisis básico ya que este repositorio no tiene acceso a Gemini
      return {
        'confidence': 0.7,
        'riskLevel': 'Moderado',
        'suggestions': [
          'Consultar con un médico especialista',
          'Mantener una dieta balanceada',
          'Evitar alimentos irritantes',
          'Reducir el estrés'
        ],
        'dlChatResponse': 'Análisis básico completado basado en síntomas: $symptomsText. Se recomienda consultar con un profesional de la salud para un diagnóstico completo.',
        'analysis_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'symptoms_analyzed': symptoms.keys.length,
        'habits_analyzed': habitHistory.length,
      };
    } catch (e) {
      print('🔥 DEBUG: Error en analyzeGastritisRisk: $e');
      // Retornar un análisis de fallback
      return {
        'confidence': 0.5,
        'riskLevel': 'Moderado',
        'suggestions': ['Consultar con un médico', 'Mantener una dieta balanceada'],
        'dlChatResponse': 'No se pudo completar el análisis. Se recomienda consultar con un profesional de la salud.',
        'error': e.toString(),
      };
    }
  }

  @override
  Future<List<String>> getHabitRecommendations({
    required String userId,
    required Map<String, dynamic> analysisResult,
  }) async {
    throw UnimplementedError('getHabitRecommendations not implemented yet');
  }

  @override
  Future<String> textToSpeech(String text) async {
    throw UnimplementedError('textToSpeech not implemented yet');
  }

  @override
  Future<String> speechToText(String audioPath) async {
    throw UnimplementedError('speechToText not implemented yet');
  }

  @override
  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  }) async {
    throw UnimplementedError('getContextualSuggestions not implemented yet');
  }

  @override
  Future<Map<String, dynamic>> getAssistantConfig(String userId) async {
    try {
      // Retornar configuración por defecto del asistente
      return {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      };
    } catch (e) {
      // Retornar configuración por defecto en caso de error
      return {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      };
    }
  }

  @override
  Future<void> updateAssistantConfig({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    try {
      // Por ahora solo logueamos la configuración
      // En una implementación completa, esto se guardaría en una base de datos
      print('🔧 Actualizando configuración del asistente para usuario $userId: $config');
    } catch (e) {
      throw Exception('Error al actualizar configuración del asistente: $e');
    }
  }

  @override
  Future<ChatMessage> createChatMessage(ChatMessage message) async {
    return await sendMessage(message.sessionId, message.content, message.type);
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    return await getSessionMessages(sessionId);
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    // Implementación básica - podría necesitar un método específico en el datasource
    throw UnimplementedError('getSession not implemented yet');
  }

  @override
  Future<ChatSession> editChatSession(ChatSession session) async {
    return await updateSessionTitle(session.id, session.title);
  }

  @override
  Future<void> deleteChatSession(String sessionId) async {
    return await deleteSession(sessionId);
  }

  @override
  Future<ChatMessage> updateChatMessage(ChatMessage message) async {
    // Actualizar el mensaje en Supabase usando editMessage
    final updatedMessage = await _remoteDataSource.editMessage(
      message.id,
      message.content,
    );
    
    return updatedMessage;
  }

  // Métodos de feedback de mensajes
  @override
  Future<bool> sendMessageFeedback({
    required String messageId,
    required String userId,
    required String feedbackType,
  }) async {
    try {
      // Por ahora retornamos true como implementación básica
      // En una implementación completa, esto se guardaría en la base de datos
      print('📝 Enviando feedback: $feedbackType para mensaje $messageId del usuario $userId');
      return true;
    } catch (e) {
      print('❌ Error al enviar feedback: $e');
      return false;
    }
  }

  @override
  Future<String?> getMessageFeedback({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Por ahora retornamos null como implementación básica
      // En una implementación completa, esto consultaría la base de datos
      print('🔍 Obteniendo feedback para mensaje $messageId del usuario $userId');
      return null;
    } catch (e) {
      print('❌ Error al obtener feedback: $e');
      return null;
    }
  }

  @override
  Future<bool> removeMessageFeedback({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Por ahora retornamos true como implementación básica
      // En una implementación completa, esto eliminaría el feedback de la base de datos
      print('🗑️ Eliminando feedback para mensaje $messageId del usuario $userId');
      return true;
    } catch (e) {
      print('❌ Error al eliminar feedback: $e');
      return false;
    }
  }

}