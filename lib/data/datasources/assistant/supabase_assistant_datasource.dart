import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_good_app/data/models/chat/chat_message_model.dart';
import 'package:vive_good_app/data/models/chat/chat_session_model.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat/chat_message.dart';

class SupabaseAssistantDatasource {
  final SupabaseClient _supabaseClient;

  SupabaseAssistantDatasource(this._supabaseClient);

  // Sesiones de chat
  Future<List<ChatSessionModel>> getChatSessions(String userId) async {
    try {
      final response = await _supabaseClient
          .from('chat_sessions')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ChatSessionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener sesiones de chat: $e');
    }
  }

  Future<ChatSessionModel?> getChatSession(String sessionId) async {
    try {
      final response = await _supabaseClient
          .from('chat_sessions')
          .select('*')
          .eq('id', sessionId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return ChatSessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener sesión de chat: $e');
    }
  }

  Future<ChatSessionModel> createChatSession({
    required String userId,
    required String title,
  }) async {
    try {
      print('DEBUG SUPABASE: Creating chat session - userId: $userId, title: $title');
      final response = await _supabaseClient
          .from('chat_sessions')
          .insert({
            'user_id': userId,
            'title': title,
            'is_active': true,
          })
          .select()
          .single();

      print('DEBUG SUPABASE: Chat session created successfully: ${response.toString()}');
      return ChatSessionModel.fromJson(response);
    } catch (e) {
      print('DEBUG SUPABASE: Error creating chat session: $e');
      print('DEBUG SUPABASE: Error stack trace: ${StackTrace.current}');
      throw Exception('Error al crear sesión de chat: $e');
    }
  }

  Future<ChatSessionModel> updateChatSession(ChatSessionModel session) async {
    try {
      final response = await _supabaseClient
          .from('chat_sessions')
          .update({
            'title': session.title
          })
          .eq('id', session.id)
          .select()
          .single();

      return ChatSessionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar sesión de chat: $e');
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    try {
      await _supabaseClient
          .from('chat_sessions')
          .update({'is_active': false})
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al eliminar sesión de chat: $e');
    }
  }

  // Mensajes de chat
  Future<List<ChatMessageModel>> getChatMessages(String sessionId) async {
    try {
      final response = await _supabaseClient
          .from('chat_messages')
          .select('*')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener mensajes de chat: $e');
    }
  }

  Future<ChatMessageModel> saveChatMessage(ChatMessageModel message) async {
    try {
      print('DEBUG SUPABASE: Saving chat message - id: ${message.id}, sessionId: ${message.sessionId}');
      print('DEBUG SUPABASE: Message content: "${message.content}"');
      print('DEBUG SUPABASE: Message type: ${message.type.name}');
      
      final insertData = {
        'id': message.id,
        'session_id': message.sessionId,
        'content': message.content,
        'message_type': message.type.name,
        'created_at': message.createdAt.toIso8601String(),
        'metadata': message.metadata,
      };
      
      print('DEBUG SUPABASE: Insert data: ${insertData.toString()}');
      
      final response = await _supabaseClient
          .from('chat_messages')
          .insert(insertData)
          .select()
          .single();

      print('DEBUG SUPABASE: Chat message saved successfully: ${response.toString()}');
      return ChatMessageModel.fromJson(response);
    } catch (e) {
      print('DEBUG SUPABASE: Error saving chat message: $e');
      print('DEBUG SUPABASE: Error stack trace: ${StackTrace.current}');
      throw Exception('Error al guardar mensaje de chat: $e');
    }
  }

  Future<void> deleteChatMessage(String messageId) async {
    try {
      await _supabaseClient
          .from('chat_messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Error al eliminar mensaje de chat: $e');
    }
  }

  Future<void> updateChatMessage(String messageId, Map<String, dynamic> updates) async {
    try {
      print('DEBUG SUPABASE: Updating chat message - id: $messageId');
      print('DEBUG SUPABASE: Updates: ${updates.toString()}');
      
      await _supabaseClient
          .from('chat_messages')
          .update(updates)
          .eq('id', messageId);
          
      print('DEBUG SUPABASE: Chat message updated successfully');
    } catch (e) {
      print('DEBUG SUPABASE: Error updating chat message: $e');
      throw Exception('Error al actualizar mensaje de chat: $e');
    }
  }

  // Configuración del asistente
  Future<Map<String, dynamic>> getAssistantConfig() async {
    try {
      final response = await _supabaseClient
          .from('assistant_config')
          .select('*')
          .limit(1)
          .maybeSingle();

      return response ?? {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      };
    } catch (e) {
      return {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      };
    }
  }

  Future<void> updateAssistantConfig({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    try {
      await _supabaseClient
          .from('assistant_config')
          .upsert({
            'user_id': userId,
            'config': config,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Error al actualizar configuración del asistente: $e');
    }
  }

  // Recomendaciones de hábitos
  Future<List<String>> getHabitRecommendations(
    String userId,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      // Simulación de recomendaciones basadas en el perfil del usuario
      final recommendations = <String>[
        'Mantén horarios regulares de comida para evitar la acidez estomacal',
        'Evita alimentos picantes y bebidas con cafeína',
        'Practica técnicas de relajación para reducir el estrés',
        'Come porciones más pequeñas y frecuentes',
        'Evita acostarte inmediatamente después de comer',
      ];
      
      return recommendations.take(3).toList();
    } catch (e) {
      throw Exception('Error al obtener recomendaciones de hábitos: $e');
    }
  }

  // Sugerencias contextuales
  Future<List<String>> getContextualSuggestions(
    String sessionId,
    String currentMessage,
  ) async {
    try {
      // Simulación de sugerencias basadas en el contexto
      final suggestions = <String>[
        '¿Qué síntomas específicos estás experimentando?',
        '¿Has notado algún patrón en tus síntomas?',
        '¿Qué alimentos has consumido recientemente?',
        '¿Cómo ha sido tu nivel de estrés últimamente?',
        '¿Has tomado algún medicamento recientemente?',
      ];
      
      return suggestions.take(3).toList();
    } catch (e) {
      throw Exception('Error al obtener sugerencias contextuales: $e');
    }
  }

  // Métodos para feedback de mensajes

  /// Envía feedback (like/dislike) para un mensaje
  Future<bool> sendMessageFeedback({
    required String messageId,
    required String userId,
    required String feedbackType,
  }) async {
    try {
      print('DEBUG SUPABASE: Sending message feedback - messageId: $messageId, userId: $userId, type: $feedbackType');
      
      // Validar que el tipo de feedback sea válido
      if (feedbackType != 'like' && feedbackType != 'dislike') {
        throw Exception('Tipo de feedback inválido: $feedbackType');
      }

      // Usar upsert para insertar o actualizar el feedback
      await _supabaseClient
          .from('message_feedback')
          .upsert({
            'user_id': userId,
            'message_id': messageId,
            'feedback_type': feedbackType,
            'updated_at': DateTime.now().toIso8601String(),
          });

      print('DEBUG SUPABASE: Message feedback sent successfully');
      return true;
    } catch (e) {
      print('DEBUG SUPABASE: Error sending message feedback: $e');
      throw Exception('Error al enviar feedback del mensaje: $e');
    }
  }

  /// Obtiene el feedback de un usuario para un mensaje específico
  Future<String?> getMessageFeedback({
    required String messageId,
    required String userId,
  }) async {
    try {
      print('DEBUG SUPABASE: Getting message feedback - messageId: $messageId, userId: $userId');
      
      final response = await _supabaseClient
          .from('message_feedback')
          .select('feedback_type')
          .eq('user_id', userId)
          .eq('message_id', messageId)
          .maybeSingle();

      final feedbackType = response?['feedback_type'] as String?;
      print('DEBUG SUPABASE: Message feedback retrieved: $feedbackType');
      
      return feedbackType;
    } catch (e) {
      print('DEBUG SUPABASE: Error getting message feedback: $e');
      throw Exception('Error al obtener feedback del mensaje: $e');
    }
  }

  /// Elimina el feedback de un usuario para un mensaje
  Future<bool> removeMessageFeedback({
    required String messageId,
    required String userId,
  }) async {
    try {
      print('DEBUG SUPABASE: Removing message feedback - messageId: $messageId, userId: $userId');
      
      await _supabaseClient
          .from('message_feedback')
          .delete()
          .eq('user_id', userId)
          .eq('message_id', messageId);

      print('DEBUG SUPABASE: Message feedback removed successfully');
      return true;
    } catch (e) {
      print('DEBUG SUPABASE: Error removing message feedback: $e');
      throw Exception('Error al eliminar feedback del mensaje: $e');
    }
  }
}