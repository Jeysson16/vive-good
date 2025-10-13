import 'dart:async';
import 'dart:math';
import 'package:vive_good_app/data/datasources/assistant/supabase_assistant_datasource.dart';
import 'package:vive_good_app/services/automatic_symptom_registration_service.dart';

import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat/chat_message.dart';
import '../../domain/entities/assistant/assistant_response.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/assistant/gemini_assistant_datasource.dart';
import '../datasources/assistant/deep_learning_datasource.dart';

/// Implementación del repositorio de chat usando Supabase
class SupabaseChatRepository implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final SupabaseAssistantDatasource? _supabaseDatasource;
  final GeminiAssistantDatasource? _geminiDatasource;
  final DeepLearningDatasource? _deepLearningDatasource;
  
  SupabaseChatRepository(
    this._remoteDataSource, {
    SupabaseAssistantDatasource? supabaseDatasource,
    GeminiAssistantDatasource? geminiDatasource,
    DeepLearningDatasource? deepLearningDatasource,
  }) : _supabaseDatasource = supabaseDatasource,
       _geminiDatasource = geminiDatasource,
       _deepLearningDatasource = deepLearningDatasource;

  @override
  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      return await _remoteDataSource.getUserSessions(userId);
    } catch (e) {
      throw Exception('Error al obtener sesiones del usuario: ${e.toString()}');
    }
  }

  @override
  Future<ChatSession> createSession(String userId, {String? title}) async {
    try {
      return await _remoteDataSource.createSession(userId, title: title);
    } catch (e) {
      throw Exception('Error al crear sesión: ${e.toString()}');
    }
  }

  @override
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    try {
      return await _remoteDataSource.getSessionMessages(sessionId);
    } catch (e) {
      throw Exception('Error al obtener mensajes: ${e.toString()}');
    }
  }

  @override
  Future<ChatMessage> sendMessage(
    String sessionId,
    String content,
    MessageType messageType,
    {Map<String, dynamic>? metadata}
  ) async {
    try {
      return await _remoteDataSource.sendMessage(
        sessionId,
        content,
        messageType,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Error al enviar mensaje: ${e.toString()}');
    }
  }

  @override
  Future<ChatMessage> editMessage(String messageId, String newContent) async {
    try {
      return await _remoteDataSource.editMessage(messageId, newContent);
    } catch (e) {
      throw Exception('Error al editar mensaje: ${e.toString()}');
    }
  }

  @override
  Future<ChatMessage> regenerateResponse(
    String sessionId,
    String lastUserMessage,
  ) async {
    try {
      // Simulación de generación de respuesta del asistente
      // En una implementación real, aquí se conectaría con el modelo de IA
      final responses = [
        'Basándome en tu consulta sobre gastritis, te recomiendo seguir una dieta blanda y evitar alimentos irritantes como picantes, café y alcohol.',
        'Para prevenir la gastritis, es importante mantener horarios regulares de comida y evitar el estrés. ¿Has considerado técnicas de relajación?',
        'Los síntomas que describes podrían estar relacionados con gastritis. Te sugiero consultar con un médico y mientras tanto, evita medicamentos antiinflamatorios.',
        'Una alimentación rica en fibra y probióticos puede ayudar a mejorar la salud digestiva. ¿Te gustaría que te sugiera algunos alimentos específicos?',
        'El estrés puede ser un factor importante en la gastritis. Te recomiendo incorporar ejercicio suave y técnicas de mindfulness en tu rutina diaria.',
      ];
      
      final random = Random();
      final responseContent = responses[random.nextInt(responses.length)];
      
      return await _remoteDataSource.sendMessage(
        sessionId,
        responseContent,
        MessageType.assistant,
        metadata: null,
      );
    } catch (e) {
      throw Exception('Error al regenerar respuesta: ${e.toString()}');
    }
  }

  @override
  Future<ChatSession> updateSessionTitle(String sessionId, String newTitle) async {
    try {
      return await _remoteDataSource.updateSessionTitle(sessionId, newTitle);
    } catch (e) {
      throw Exception('Error al actualizar título: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _remoteDataSource.deleteSession(sessionId);
    } catch (e) {
      throw Exception('Error al eliminar sesión: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _remoteDataSource.deleteMessage(messageId);
    } catch (e) {
      throw Exception('Error al eliminar mensaje: ${e.toString()}');
    }
  }

  @override
  Future<ChatSession> updateSessionStatus(String sessionId, bool isActive) async {
    try {
      return await _remoteDataSource.updateSessionStatus(sessionId, isActive);
    } catch (e) {
      throw Exception('Error al actualizar estado: ${e.toString()}');
    }
  }

  @override
  Future<ChatSession?> getActiveSession(String userId) async {
    try {
      return await _remoteDataSource.getActiveSession(userId);
    } catch (e) {
      throw Exception('Error al obtener sesión activa: ${e.toString()}');
    }
  }

  @override
  Stream<List<ChatMessage>> watchSessionMessages(String sessionId) {
    try {
      return _remoteDataSource.watchSessionMessages(sessionId);
    } catch (e) {
      throw Exception('Error al suscribirse a mensajes: ${e.toString()}');
    }
  }

  @override
  Stream<List<ChatSession>> watchUserSessions(String userId) {
    try {
      return _remoteDataSource.watchUserSessions(userId);
    } catch (e) {
      throw Exception('Error al suscribirse a sesiones: ${e.toString()}');
    }
  }

  /// Genera una respuesta automática del asistente basada en el mensaje del usuario
  Future<ChatMessage> _generateAssistantResponse(
    String sessionId,
    String userMessage,
  ) async {
    // Simulación de procesamiento de IA
    await Future.delayed(const Duration(seconds: 2));
    
    String response;
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('dolor') || lowerMessage.contains('duele')) {
      response = 'Entiendo que tienes dolor. Para la gastritis, es importante evitar alimentos irritantes y considerar medicamentos antiácidos bajo supervisión médica.';
    } else if (lowerMessage.contains('comida') || lowerMessage.contains('comer')) {
      response = 'Para una dieta amigable con la gastritis, te recomiendo: arroz blanco, pollo hervido, plátano maduro, y evitar picantes, café y alcohol.';
    } else if (lowerMessage.contains('síntoma') || lowerMessage.contains('síntomas')) {
      response = 'Los síntomas comunes de gastritis incluyen dolor abdominal, náuseas, sensación de llenura y acidez. ¿Experimentas alguno de estos?';
    } else if (lowerMessage.contains('estrés') || lowerMessage.contains('ansiedad')) {
      response = 'El estrés puede empeorar la gastritis. Te sugiero técnicas de relajación, ejercicio suave y mantener horarios regulares de comida.';
    } else {
      response = 'Gracias por tu consulta. Para la gastritis, es fundamental mantener una dieta balanceada, evitar irritantes y manejar el estrés. ¿Hay algo específico que te preocupe?';
    }
    
    return await _remoteDataSource.sendMessage(
      sessionId,
      response,
      MessageType.assistant,
    );
  }

  // Métodos específicos del asistente
  @override
  Future<AssistantResponse> sendMessageToGemini({
    required String message,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    if (_geminiDatasource == null) {
      throw Exception('Gemini datasource no está configurado');
    }
    try {
      print('🔥 DEBUG: SupabaseChatRepository.sendMessageToGemini iniciado');
      print('🔥 DEBUG: Mensaje del usuario: "$message"');
      
      // 1. Procesar síntomas automáticamente ANTES de enviar a Gemini
      print('🔥 DEBUG: Procesando síntomas automáticamente...');
      final registeredSymptoms = await AutomaticSymptomRegistrationService.processMessageForSymptoms(
        message: message,
        userId: userId,
      );
      
      // 2. Obtener respuesta de Gemini
      print('🔥 DEBUG: Enviando mensaje a Gemini...');
      final geminiResponse = await _geminiDatasource!.sendMessage(
        message: message,
        sessionId: sessionId,
        userId: userId,
        conversationHistory: conversationHistory ?? [],
      );
      
      // 3. Agregar información de síntomas registrados a la respuesta si hay alguno
      String finalContent = geminiResponse.content;
      if (registeredSymptoms.isNotEmpty) {
        final symptomsSummary = AutomaticSymptomRegistrationService.generateSymptomsRegistrationSummary(registeredSymptoms);
        finalContent += symptomsSummary;
        print('🔥 DEBUG: Síntomas registrados automáticamente: ${registeredSymptoms.length}');
      }
      
      // 4. Crear respuesta final con contenido actualizado
      final finalResponse = AssistantResponse(
        id: geminiResponse.id,
        sessionId: geminiResponse.sessionId,
        content: finalContent,
        type: geminiResponse.type,
        timestamp: geminiResponse.timestamp,
        metadata: {
          ...?geminiResponse.metadata,
          'auto_registered_symptoms': registeredSymptoms.length,
          'symptoms_detected': registeredSymptoms.isNotEmpty,
        },
      );
      
      print('🔥 DEBUG: SupabaseChatRepository.sendMessageToGemini completado');
      return finalResponse;
    } catch (e) {
      print('🔥 DEBUG: Error en SupabaseChatRepository.sendMessageToGemini: $e');
      throw Exception('Error al enviar mensaje a Gemini: ${e.toString()}');
    }
  }

  @override
  Future<AssistantResponse> processVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
  }) async {
    if (_geminiDatasource == null) {
      throw Exception('Gemini datasource no está configurado');
    }
    try {
      return await _geminiDatasource!.processVoiceMessage(
        audioPath: audioPath,
        sessionId: sessionId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Error al procesar mensaje de voz: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> symptoms,
    required List<Map<String, dynamic>> habitHistory,
  }) async {
    try {
      print('🔥 DEBUG: SupabaseChatRepository.analyzeGastritisRisk llamado');
      
      // Si tenemos el datasource de Gemini, usarlo para Deep Learning
      if (_geminiDatasource != null) {
        print('🔥 DEBUG: Usando GeminiDatasource para Deep Learning');
        
        // Crear un mensaje descriptivo de los síntomas para el análisis
        final symptomsText = symptoms.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .join(', ');
        
        final message = 'Síntomas reportados: $symptomsText';
        
        // Llamar al datasource de Gemini para procesar Deep Learning
        final result = await _geminiDatasource!.processDeepLearningAnalysis(
          message: message,
          userId: userId,
        );
        
        print('🔥 DEBUG: Resultado de Deep Learning obtenido: $result');
        return result;
      }
      
      // Fallback si no hay datasource de Gemini
      print('🔥 DEBUG: Usando análisis de fallback (sin Gemini)');
      return {
        'confidence': 0.75,
        'riskLevel': 'Moderado',
        'suggestions': ['Evitar comidas picantes', 'Reducir el estrés', 'Consultar con un médico'],
        'dlChatResponse': 'Análisis básico completado. Se recomienda consultar con un profesional de la salud para un diagnóstico completo.',
        'analysis_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'symptoms_analyzed': symptoms.keys.length,
        'habits_analyzed': habitHistory.length,
      };
    } catch (e) {
      print('🔥 DEBUG: Error en analyzeGastritisRisk: $e');
      // Retornar un análisis de fallback en caso de error
      return {
        'confidence': 0.5,
        'riskLevel': 'Moderado',
        'suggestions': ['Consultar con un médico', 'Mantener una dieta balanceada'],
        'dlChatResponse': 'No se pudo completar el análisis de Deep Learning. Se recomienda consultar con un profesional de la salud.',
        'error': e.toString(),
      };
    }
  }

  @override
  Future<List<String>> getHabitRecommendations({
    required String userId,
    required Map<String, dynamic> analysisResult,
  }) async {
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      return await _supabaseDatasource!.getHabitRecommendations(userId, analysisResult);
    } catch (e) {
      throw Exception('Error al obtener recomendaciones: ${e.toString()}');
    }
  }

  @override
  Future<String> textToSpeech(String text) async {
    // TODO: Implementar síntesis de voz
    throw UnimplementedError('Síntesis de voz no implementada aún');
  }

  @override
  Future<String> speechToText(String audioPath) async {
    // TODO: Implementar reconocimiento de voz
    throw UnimplementedError('Reconocimiento de voz no implementado aún');
  }

  @override
  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  }) async {
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      return await _supabaseDatasource!.getContextualSuggestions(userId, currentContext);
    } catch (e) {
      throw Exception('Error al obtener sugerencias: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAssistantConfig(String userId) async {
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      return await _supabaseDatasource!.getAssistantConfig() ?? {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      };
    } catch (e) {
      throw Exception('Error al obtener configuración: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAssistantConfig({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      await _supabaseDatasource!.updateAssistantConfig(
        userId: userId,
        config: config,
      );
    } catch (e) {
      throw Exception('Error al actualizar configuración: ${e.toString()}');
    }
  }

  // Métodos de compatibilidad con AssistantBloc
  @override
  Future<ChatMessage> createChatMessage(ChatMessage message) async {
    return await sendMessage(
      message.sessionId,
      message.content,
      message.type,
      metadata: message.metadata,
    );
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    return await getSessionMessages(sessionId);
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    try {
      final sessions = await _remoteDataSource.getUserSessions('');
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ChatSession> editChatSession(ChatSession session) async {
    return await updateSessionTitle(session.id, session.title);
  }

  @override
  Future<void> deleteChatSession(String sessionId) async {
    await deleteSession(sessionId);
  }

  @override
  Future<ChatMessage> updateChatMessage(ChatMessage message) async {
    try {
      return await _remoteDataSource.editMessage(message.id, message.content);
    } catch (e) {
      throw Exception('Error al actualizar mensaje: ${e.toString()}');
    }
  }

  /// Genera automáticamente un título para una sesión basado en el primer mensaje
  Future<ChatSession> generateAndUpdateSessionTitle(String sessionId, String firstMessage) async {
    try {
      if (_geminiDatasource == null) {
        // Si no hay Gemini disponible, usar un título por defecto
        return await updateSessionTitle(sessionId, 'Nueva conversación');
      }

      // Generar título con Gemini
      final generatedTitle = await _geminiDatasource!.generateConversationTitle(firstMessage);
      
      // Actualizar la sesión con el nuevo título
      return await updateSessionTitle(sessionId, generatedTitle);
    } catch (e) {
      print('❌ Error al generar título automático: $e');
      // En caso de error, usar un título por defecto
      return await updateSessionTitle(sessionId, 'Nueva conversación');
    }
  }

  // Métodos para feedback de mensajes

  @override
  Future<bool> sendMessageFeedback({
    required String messageId,
    required String userId,
    required String feedbackType,
  }) async {
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      return await _supabaseDatasource!.sendMessageFeedback(
        messageId: messageId,
        userId: userId,
        feedbackType: feedbackType,
      );
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
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      return await _supabaseDatasource!.getMessageFeedback(
        messageId: messageId,
        userId: userId,
      );
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
    if (_supabaseDatasource == null) {
      throw Exception('Supabase datasource no está configurado');
    }
    try {
      return await _supabaseDatasource!.removeMessageFeedback(
        messageId: messageId,
        userId: userId,
      );
    } catch (e) {
      print('❌ Error al eliminar feedback: $e');
      return false;
    }
  }
}
