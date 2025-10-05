import '../entities/chat_session.dart';
import '../entities/chat/chat_message.dart';
import '../entities/assistant/assistant_response.dart';

/// Repositorio abstracto para operaciones de chat
abstract class ChatRepository {
  /// Obtiene todas las sesiones de chat de un usuario
  /// 
  /// [userId] - ID del usuario
  /// Retorna una lista de sesiones ordenadas por fecha de creación descendente
  Future<List<ChatSession>> getUserSessions(String userId);

  /// Crea una nueva sesión de chat
  /// 
  /// [userId] - ID del usuario propietario
  /// [title] - Título opcional de la sesión (por defecto: "Nueva conversación")
  /// Retorna la sesión creada
  Future<ChatSession> createSession(String userId, {String? title});

  /// Obtiene todos los mensajes de una sesión específica
  /// 
  /// [sessionId] - ID de la sesión
  /// Retorna una lista de mensajes ordenados por fecha de creación ascendente
  Future<List<ChatMessage>> getSessionMessages(String sessionId);

  /// Envía un nuevo mensaje a una sesión
  /// 
  /// [sessionId] - ID de la sesión
  /// [content] - Contenido del mensaje
  /// [messageType] - Tipo de mensaje (usuario, asistente, sistema)
  /// Retorna el mensaje creado
  Future<ChatMessage> sendMessage(
    String sessionId,
    String content,
    MessageType messageType,
  );

  /// Edita un mensaje existente
  /// 
  /// [messageId] - ID del mensaje a editar
  /// [newContent] - Nuevo contenido del mensaje
  /// Retorna el mensaje actualizado
  Future<ChatMessage> editMessage(String messageId, String newContent);

  /// Regenera la respuesta del asistente para el último mensaje del usuario
  /// 
  /// [sessionId] - ID de la sesión
  /// [lastUserMessage] - Último mensaje del usuario para contexto
  /// Retorna el nuevo mensaje del asistente generado
  Future<ChatMessage> regenerateResponse(
    String sessionId,
    String lastUserMessage,
  );

  /// Actualiza el título de una sesión
  /// 
  /// [sessionId] - ID de la sesión
  /// [newTitle] - Nuevo título
  /// Retorna la sesión actualizada
  Future<ChatSession> updateSessionTitle(String sessionId, String newTitle);

  /// Elimina una sesión de chat y todos sus mensajes
  /// 
  /// [sessionId] - ID de la sesión a eliminar
  Future<void> deleteSession(String sessionId);

  /// Elimina un mensaje específico
  /// 
  /// [messageId] - ID del mensaje a eliminar
  Future<void> deleteMessage(String messageId);

  /// Marca una sesión como activa o inactiva
  /// 
  /// [sessionId] - ID de la sesión
  /// [isActive] - Estado de actividad
  /// Retorna la sesión actualizada
  Future<ChatSession> updateSessionStatus(String sessionId, bool isActive);

  /// Obtiene la sesión activa del usuario (si existe)
  /// 
  /// [userId] - ID del usuario
  /// Retorna la sesión activa o null si no hay ninguna
  Future<ChatSession?> getActiveSession(String userId);

  /// Suscripción en tiempo real a los mensajes de una sesión
  /// 
  /// [sessionId] - ID de la sesión
  /// Retorna un stream de listas de mensajes actualizadas
  Stream<List<ChatMessage>> watchSessionMessages(String sessionId);

  /// Suscripción en tiempo real a las sesiones de un usuario
  /// 
  /// [userId] - ID del usuario
  /// Retorna un stream de listas de sesiones actualizadas
  Stream<List<ChatSession>> watchUserSessions(String userId);

  // Métodos específicos del asistente
  
  /// Envía un mensaje a Gemini AI y obtiene una respuesta
  /// 
  /// [message] - Mensaje del usuario
  /// [sessionId] - ID de la sesión
  /// [userId] - ID del usuario
  /// [conversationHistory] - Historial de mensajes para contexto
  /// [userContext] - Contexto adicional del usuario
  /// Retorna la respuesta del asistente
  Future<AssistantResponse> sendMessageToGemini({
    required String message,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? userContext,
  });

  /// Procesa un mensaje de voz
  /// 
  /// [audioPath] - Ruta del archivo de audio
  /// [sessionId] - ID de la sesión
  /// [userId] - ID del usuario
  /// [conversationHistory] - Historial de mensajes para contexto
  /// Retorna la respuesta del asistente
  Future<AssistantResponse> processVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
  });

  /// Analiza el riesgo de gastritis usando Deep Learning
  /// 
  /// [userId] - ID del usuario
  /// [symptoms] - Síntomas reportados
  /// [habitHistory] - Historial de hábitos
  /// Retorna el análisis de riesgo
  Future<Map<String, dynamic>> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> symptoms,
    required List<Map<String, dynamic>> habitHistory,
  });

  /// Obtiene recomendaciones de hábitos
  /// 
  /// [userId] - ID del usuario
  /// [analysisResult] - Resultado del análisis previo
  /// Retorna lista de recomendaciones
  Future<List<String>> getHabitRecommendations({
    required String userId,
    required Map<String, dynamic> analysisResult,
  });

  /// Convierte texto a voz
  /// 
  /// [text] - Texto a convertir
  /// Retorna la ruta del archivo de audio generado
  Future<String> textToSpeech(String text);

  /// Convierte voz a texto
  /// 
  /// [audioPath] - Ruta del archivo de audio
  /// Retorna el texto transcrito
  Future<String> speechToText(String audioPath);

  /// Obtiene sugerencias contextuales
  /// 
  /// [userId] - ID del usuario
  /// [currentContext] - Contexto actual
  /// Retorna lista de sugerencias
  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  });

  /// Obtiene la configuración del asistente
  /// 
  /// [userId] - ID del usuario
  /// Retorna la configuración actual
  Future<Map<String, dynamic>> getAssistantConfig(String userId);

  /// Actualiza la configuración del asistente
  /// 
  /// [userId] - ID del usuario
  /// [config] - Nueva configuración
  Future<void> updateAssistantConfig({
    required String userId,
    required Map<String, dynamic> config,
  });

  /// Crea un nuevo mensaje de chat
  /// 
  /// [message] - Mensaje a crear
  /// Retorna el mensaje creado
  Future<ChatMessage> createChatMessage(ChatMessage message);

  /// Obtiene mensajes de una sesión (alias para compatibilidad)
  /// 
  /// [sessionId] - ID de la sesión
  /// Retorna lista de mensajes
  Future<List<ChatMessage>> getChatMessages(String sessionId);

  /// Obtiene una sesión específica
  /// 
  /// [sessionId] - ID de la sesión
  /// Retorna la sesión o null si no existe
  Future<ChatSession?> getSession(String sessionId);

  /// Edita una sesión de chat
  /// 
  /// [session] - Sesión con los cambios
  /// Retorna la sesión actualizada
  Future<ChatSession> editChatSession(ChatSession session);

  /// Elimina una sesión de chat
  /// 
  /// [sessionId] - ID de la sesión a eliminar
  Future<void> deleteChatSession(String sessionId);
}