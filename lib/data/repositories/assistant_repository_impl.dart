import '../../domain/entities/chat/chat_session.dart';
import '../../domain/entities/chat/chat_message.dart';
import '../../domain/entities/assistant/assistant_response.dart';
import '../../domain/entities/assistant/voice_animation_state.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant/supabase_assistant_datasource.dart';
import '../datasources/assistant/gemini_assistant_datasource.dart';
import '../datasources/assistant/deep_learning_datasource.dart';
import '../models/chat/chat_session_model.dart';
import '../models/chat/chat_message_model.dart';
import '../models/assistant/assistant_response_model.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  final SupabaseAssistantDatasource _supabaseDatasource;
  final GeminiAssistantDatasource _geminiDatasource;
  final DeepLearningDatasource _deepLearningDatasource;

  AssistantRepositoryImpl({
    required SupabaseAssistantDatasource supabaseDatasource,
    required GeminiAssistantDatasource geminiDatasource,
    required DeepLearningDatasource deepLearningDatasource,
  }) : _supabaseDatasource = supabaseDatasource,
       _geminiDatasource = geminiDatasource,
       _deepLearningDatasource = deepLearningDatasource;

  @override
  Future<List<ChatSession>> getChatSessions(String userId) async {
    try {
      final sessionModels = await _supabaseDatasource.getChatSessions(userId);
      return sessionModels;
    } catch (e) {
      throw Exception('Error al obtener sesiones de chat: $e');
    }
  }

  @override
  Future<ChatSession?> getChatSession(String sessionId) async {
    try {
      final session = await _supabaseDatasource.getChatSession(sessionId);
      return session;
    } catch (e) {
      throw Exception('Error al obtener sesión de chat: $e');
    }
  }

  @override
  Future<ChatSession> updateChatSession(ChatSession session) async {
    try {
      final updatedSession = await _supabaseDatasource.updateChatSession(session as ChatSessionModel);
      return updatedSession;
    } catch (e) {
      throw Exception('Error al actualizar sesión de chat: $e');
    }
  }

  @override
  Future<ChatSession> createChatSession({
    required String userId,
    String? title,
  }) async {
    try {
      final createdSession = await _supabaseDatasource.createChatSession(
        userId: userId,
        title: title ?? 'Nueva sesión de chat',
      );
      return createdSession;
    } catch (e) {
      throw Exception('Error al crear sesión de chat: $e');
    }
  }

  @override
  Future<void> deleteChatSession(String sessionId) async {
    try {
      await _supabaseDatasource.deleteChatSession(sessionId);
    } catch (e) {
      throw Exception('Error al eliminar sesión de chat: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    try {
      final messageModels = await _supabaseDatasource.getChatMessages(sessionId);
      return messageModels;
    } catch (e) {
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  @override
  Future<ChatMessage> saveChatMessage(ChatMessage message) async {
    try {
      final savedMessage = await _supabaseDatasource.saveChatMessage(message as ChatMessageModel);
      return savedMessage;
    } catch (e) {
      throw Exception('Error al guardar mensaje: $e');
    }
  }

  @override
  Future<void> deleteChatMessage(String messageId) async {
    try {
      await _supabaseDatasource.deleteChatMessage(messageId);
    } catch (e) {
      throw Exception('Error al eliminar mensaje: $e');
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
    required String userId,
    MessageType type = MessageType.user,
    String? audioUrl,
  }) async {
    try {
      // Crear el mensaje del usuario
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        content: content,
        type: type,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        metadata: audioUrl != null ? {'audioUrl': audioUrl} : null,
      );

      // Guardar el mensaje del usuario
      final savedUserMessage = await _supabaseDatasource.saveChatMessage(userMessage);

      return savedUserMessage;
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  @override
  Future<AssistantResponse> sendMessageToGemini({
    required String message,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      print('🔥 DEBUG REPOSITORY: ===== INICIANDO sendMessageToGemini =====');
      print('🔥 DEBUG REPOSITORY: Mensaje: "$message"');
      print('🔥 DEBUG REPOSITORY: SessionId: $sessionId');
      print('🔥 DEBUG REPOSITORY: UserId: $userId');
      
      print('🔥 DEBUG REPOSITORY: Llamando a _geminiDatasource.sendMessage');
      final response = await _geminiDatasource.sendMessage(
        message: message,
        sessionId: sessionId,
        userId: userId,
        conversationHistory: conversationHistory ?? [],
      );
      print('🔥 DEBUG REPOSITORY: Respuesta recibida de Gemini datasource');
      print('🔥 DEBUG REPOSITORY: Contenido de respuesta: "${response.content}"');

      // Guardar la respuesta del asistente como mensaje
      print('🔥 DEBUG REPOSITORY: Guardando respuesta en Supabase');
      final assistantMessage = ChatMessageModel(
        id: response.id,
        sessionId: response.sessionId,
        content: response.content,
        type: MessageType.assistant,
        status: MessageStatus.sent,
        createdAt: response.timestamp,
        metadata: response.metadata,
      );
      await _supabaseDatasource.saveChatMessage(assistantMessage);
      print('🔥 DEBUG REPOSITORY: Respuesta guardada en Supabase');

      print('🔥 DEBUG REPOSITORY: ===== sendMessageToGemini COMPLETADO =====');
      return response;
    } catch (e) {
      print('🔥 DEBUG REPOSITORY: ===== ERROR EN sendMessageToGemini =====');
      print('🔥 DEBUG REPOSITORY: Error: $e');
      print('🔥 DEBUG REPOSITORY: Stack trace: ${StackTrace.current}');
      throw Exception('Error al procesar mensaje con Gemini: $e');
    }
  }

  @override
  Future<AssistantResponse> processVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final response = await _geminiDatasource.processVoiceMessage(
        audioPath: audioPath,
        sessionId: sessionId,
        userId: userId,
        conversationHistory: conversationHistory,
      );

      // Guardar la respuesta del asistente como mensaje
      final assistantMessage = ChatMessageModel(
        id: response.id,
        sessionId: response.sessionId,
        content: response.content,
        type: MessageType.assistant,
        status: MessageStatus.sent,
        createdAt: response.timestamp,
        metadata: response.metadata,
      );
      await _supabaseDatasource.saveChatMessage(assistantMessage);

      return response;
    } catch (e) {
      throw Exception('Error al procesar mensaje de voz: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> symptoms,
    required List<Map<String, dynamic>> habitHistory,
  }) async {
    try {
      final prediction = await _deepLearningDatasource.predictGastritisRisk(
        userHabits: symptoms,
        userId: userId,
      );

      return {
        'riskLevel': prediction.riskLevel,
        'riskCategory': prediction.riskCategory,
        'confidence': prediction.confidence,
        'riskFactors': prediction.riskFactors,
        'factorContributions': prediction.factorContributions,
        'timestamp': prediction.timestamp.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error en análisis de riesgo de gastritis: $e');
    }
  }

  /// Procesa análisis de Deep Learning por separado
  Future<Map<String, dynamic>> processDeepLearningAnalysis({
    required String message,
    required String userId,
    String? sessionId,
  }) async {
    try {
      print('🔥 DEBUG REPOSITORY: ===== INICIANDO processDeepLearningAnalysis =====');
      
      final result = await _geminiDatasource.processDeepLearningAnalysis(
        message: message,
        userId: userId,
        sessionId: sessionId,
      );
      
      print('🔥 DEBUG REPOSITORY: Deep Learning analysis completado');
      return result;
    } catch (e) {
      print('🔥 DEBUG REPOSITORY: Error en processDeepLearningAnalysis: $e');
      throw Exception('Error al procesar análisis de Deep Learning: $e');
    }
  }

  @override
  Future<List<String>> getHabitRecommendations({
    required String userId,
    required Map<String, dynamic> analysisResult,
  }) async {
    try {
      final recommendations = await _deepLearningDatasource.getHabitRecommendations(
        userId: userId,
        currentHabits: {},
        riskLevel: analysisResult['risk_level'] ?? 'low',
      );

      return recommendations.map((r) => r.title).toList();
    } catch (e) {
      throw Exception('Error al obtener recomendaciones: $e');
    }
  }





  @override
  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  }) async {
    try {
      final suggestions = await _geminiDatasource.getContextualSuggestions(
        userId: userId,
        currentContext: currentContext,
      );
      return suggestions;
    } catch (e) {
      // Retornar sugerencias por defecto en caso de error
      return ['Beber más agua', 'Comer despacio', 'Reducir estrés'];
    }
  }

  @override
  Future<Map<String, dynamic>> getAssistantConfig(String userId) async {
    try {
      final config = await _supabaseDatasource.getAssistantConfig();
      return config ?? {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      };
    } catch (e) {
      // Retornar configuración por defecto
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
      await _supabaseDatasource.updateAssistantConfig(
        userId: userId,
        config: config,
      );
    } catch (e) {
      throw Exception('Error al actualizar configuración: $e');
    }
  }

  @override
  Future<String> speechToText(String audioPath) async {
    try {
      // TODO: Implementar integración con servicio de speech-to-text
      // Por ahora retornamos un placeholder
      return 'Transcripción de audio no implementada aún';
    } catch (e) {
      throw Exception('Error en speech-to-text: $e');
    }
  }

  @override
  Future<String> textToSpeech(String text) async {
    try {
      // TODO: Implementar integración con servicio de text-to-speech
      // Por ahora retornamos un placeholder
      return 'audio_placeholder.mp3';
    } catch (e) {
      throw Exception('Error en text-to-speech: $e');
    }
  }

  @override
  Future<String> generateConversationTitle(String firstMessage) async {
    try {
      return await _geminiDatasource.generateConversationTitle(firstMessage);
    } catch (e) {
      throw Exception('Error al generar título de conversación: $e');
    }
  }

  void dispose() {
    _geminiDatasource.dispose();
    _deepLearningDatasource.dispose();
  }
}