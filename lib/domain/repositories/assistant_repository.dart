import '../entities/chat/chat_session.dart';
import '../entities/chat/chat_message.dart';
import '../entities/assistant/assistant_response.dart';

abstract class AssistantRepository {
  // Sesiones de chat
  Future<List<ChatSession>> getChatSessions(String userId);
  Future<ChatSession?> getChatSession(String sessionId);
  Future<ChatSession> createChatSession({
    required String userId,
    String? title,
  });
  Future<ChatSession> updateChatSession(ChatSession session);
  Future<void> deleteChatSession(String sessionId);

  // Mensajes
  Future<List<ChatMessage>> getChatMessages(String sessionId);
  Future<ChatMessage> saveChatMessage(ChatMessage message);
  Future<void> deleteChatMessage(String messageId);

  // Integración con Gemini AI
  Future<AssistantResponse> sendMessageToGemini({
    required String message,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? userContext,
    bool isInitialResponse = false,
  });

  Future<AssistantResponse> processVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
  });

  // Integración con modelo de Deep Learning
  Future<Map<String, dynamic>> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> symptoms,
    required List<Map<String, dynamic>> habitHistory,
  });

  Future<List<String>> getHabitRecommendations({
    required String userId,
    required Map<String, dynamic> analysisResult,
  });

  // Servicios de voz
  Future<String> speechToText(String audioPath);
  Future<String> textToSpeech(String text);

  // Generación de títulos
  Future<String> generateConversationTitle(String firstMessage);

  // Sugerencias contextuales
  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  });

  // Configuración y estado
  Future<Map<String, dynamic>> getAssistantConfig(String userId);
  Future<void> updateAssistantConfig({
    required String userId,
    required Map<String, dynamic> config,
  });
}