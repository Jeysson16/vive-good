import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat/chat_message.dart';

class MetricsExtractionService {
  final SupabaseClient _supabaseClient;

  MetricsExtractionService(this._supabaseClient);

  // Palabras clave para identificar síntomas
  static const List<String> _symptomsKeywords = [
    'dolor de estómago', 'dolor estomacal', 'acidez', 'reflujo', 'náuseas',
    'vómito', 'indigestión', 'ardor', 'gastritis', 'úlcera', 'hinchazón',
    'gases', 'eructos', 'malestar estomacal', 'dolor abdominal'
  ];

  // Palabras clave para factores de riesgo
  static const List<String> _riskFactorsKeywords = [
    'estrés', 'alcohol', 'cigarro', 'fumar', 'comida picante', 'café',
    'medicamentos', 'antiinflamatorios', 'helicobacter', 'bacteria',
    'saltarse comidas', 'comer tarde', 'comida rápida', 'frituras'
  ];

  // Palabras clave para hábitos alimenticios de riesgo
  static const List<String> _riskEatingHabits = [
    'comida rápida', 'frituras', 'picante', 'alcohol', 'café en exceso',
    'saltarse comidas', 'comer tarde', 'no desayunar', 'comer mucho',
    'atracones', 'comida procesada', 'refrescos', 'dulces en exceso'
  ];

  // Palabras clave para hábitos saludables
  static const List<String> _healthyHabitsKeywords = [
    'ejercicio', 'caminar', 'correr', 'yoga', 'meditación', 'dormir bien',
    'agua', 'hidratarse', 'frutas', 'verduras', 'comida casera',
    'horarios regulares', 'relajación', 'respiración'
  ];

  // Palabras clave para aceptación tecnológica
  static const List<String> _techAcceptanceKeywords = [
    'app', 'aplicación', 'celular', 'teléfono', 'tecnología', 'digital',
    'recordatorio', 'notificación', 'seguimiento', 'monitoreo'
  ];

  /// Extrae métricas de síntomas y conocimiento
  Future<void> extractSymptomsKnowledge({
    required String userId,
    required String sessionId,
    required String text,
    required String geminiResponse,
  }) async {
    try {
      final symptomsFound = <String>[];
      final riskFactorsFound = <String>[];
      
      final lowerText = text.toLowerCase();
      final lowerResponse = geminiResponse.toLowerCase();
      final combinedText = '$lowerText $lowerResponse';

      // Buscar síntomas mencionados
      for (final symptom in _symptomsKeywords) {
        if (combinedText.contains(symptom.toLowerCase())) {
          symptomsFound.add(symptom);
        }
      }

      // Buscar factores de riesgo mencionados
      for (final riskFactor in _riskFactorsKeywords) {
        if (combinedText.contains(riskFactor.toLowerCase())) {
          riskFactorsFound.add(riskFactor);
        }
      }

      if (symptomsFound.isNotEmpty || riskFactorsFound.isNotEmpty) {
        // Calcular nivel de conocimiento basado en la cantidad y especificidad
        int knowledgeLevel = _calculateKnowledgeLevel(symptomsFound, riskFactorsFound);
        double confidenceScore = _calculateConfidenceScore(text, geminiResponse);

        await _supabaseClient.from('user_symptoms').insert({
          'user_id': userId,
          'symptom_type': symptomsFound.join(', '),
          'description': text,
          'triggers': riskFactorsFound,
          'context': {
            'session_id': sessionId,
            'knowledge_level': knowledgeLevel,
            'confidence_score': confidenceScore,
            'extracted_from_text': text,
          },
        });
      }
    } catch (e) {
      print('Error extracting symptoms knowledge: $e');
    }
  }

  /// Extrae métricas de aceptación tecnológica
  Future<void> extractTechAcceptance({
    required String userId,
    required String sessionId,
    required String text,
    required String geminiResponse,
  }) async {
    try {
      final lowerText = text.toLowerCase();
      final lowerResponse = geminiResponse.toLowerCase();
      final combinedText = '$lowerText $lowerResponse';

      // Buscar menciones de tecnología
      for (final techKeyword in _techAcceptanceKeywords) {
        if (combinedText.contains(techKeyword.toLowerCase())) {
          final sentiment = _analyzeSentiment(combinedText, techKeyword);
          final acceptanceLevel = _calculateAcceptanceLevel(sentiment, combinedText);
          
          await _supabaseClient.from('user_tech_acceptance').insert({
            'user_id': userId,
            'session_id': sessionId,
            'tool_mentioned': techKeyword,
            'acceptance_level': acceptanceLevel,
            'sentiment': sentiment,
            'extracted_from_text': text,
          });
          break; // Solo registrar una vez por conversación
        }
      }
    } catch (e) {
      print('Error extracting tech acceptance: $e');
    }
  }

  /// Extrae hábitos alimenticios
  Future<void> extractEatingHabits({
    required String userId,
    required String sessionId,
    required String text,
    required String geminiResponse,
  }) async {
    try {
      final lowerText = text.toLowerCase();
      final lowerResponse = geminiResponse.toLowerCase();
      final combinedText = '$lowerText $lowerResponse';

      // Buscar hábitos de riesgo
      for (final riskHabit in _riskEatingHabits) {
        if (combinedText.contains(riskHabit.toLowerCase())) {
          final frequency = _extractFrequency(combinedText);
          final riskLevel = _calculateRiskLevel(riskHabit, frequency);

          // Note: Storing eating habits data in a separate table or handling differently
          // as the user_habits table doesn't have session_id, habit_type, habit_description, risk_level, extracted_from_text columns
          print('Risk eating habit detected: $riskHabit (frequency: $frequency, risk: $riskLevel)');
        }
      }
    } catch (e) {
      print('Error extracting eating habits: $e');
    }
  }

  /// Extrae hábitos saludables
  Future<void> extractHealthyHabits({
    required String userId,
    required String sessionId,
    required String text,
    required String geminiResponse,
  }) async {
    try {
      final lowerText = text.toLowerCase();
      final lowerResponse = geminiResponse.toLowerCase();
      final combinedText = '$lowerText $lowerResponse';

      // Buscar hábitos saludables
      for (final healthyHabit in _healthyHabitsKeywords) {
        if (combinedText.contains(healthyHabit.toLowerCase())) {
          final frequency = _extractFrequency(combinedText);
          final adoptionStatus = _extractAdoptionStatus(combinedText);
          final category = _categorizeHealthyHabit(healthyHabit);

          // Note: Storing healthy habits data in a separate table or handling differently
          // as the user_habits table doesn't have notes column and requires habit_id
          print('Healthy habit detected: $healthyHabit (frequency: $frequency, adoption: $adoptionStatus)');
        }
      }
    } catch (e) {
      print('Error extracting healthy habits: $e');
    }
  }

  /// Guarda análisis completo de la conversación
  Future<void> saveConversationAnalysis({
    required String userId,
    required String sessionId,
    required String geminiResponse,
    Map<String, dynamic>? dlModelResponse,
    required String userMessage,
  }) async {
    try {
      final extractedMetrics = await _generateMetricsSummary(
        userId, sessionId, userMessage, geminiResponse
      );

      final keyTopics = _extractKeyTopics(userMessage, geminiResponse);
      final actionItems = _extractActionItems(geminiResponse);

      await _supabaseClient.from('consultations').insert({
        'user_id': userId,
        'query_text': userMessage,
        'session_id': sessionId,
        // Note: Storing additional data in a separate table or handling differently
        // as the consultations table doesn't have consultation_type, symptoms, notes, context columns
      });
    } catch (e) {
      print('Error saving conversation analysis: $e');
    }
  }

  // Métodos auxiliares privados
  int _calculateKnowledgeLevel(List<String> symptoms, List<String> riskFactors) {
    final totalMentions = symptoms.length + riskFactors.length;
    if (totalMentions >= 5) return 5;
    if (totalMentions >= 4) return 4;
    if (totalMentions >= 3) return 3;
    if (totalMentions >= 2) return 2;
    return 1;
  }

  double _calculateConfidenceScore(String text, String response) {
    final textLength = text.length;
    final responseLength = response.length;
    final totalLength = textLength + responseLength;
    
    // Más texto generalmente significa más confianza en la extracción
    if (totalLength > 500) return 0.9;
    if (totalLength > 300) return 0.7;
    if (totalLength > 150) return 0.5;
    return 0.3;
  }

  String _analyzeSentiment(String text, String keyword) {
    final positiveWords = ['bueno', 'útil', 'ayuda', 'fácil', 'me gusta', 'genial'];
    final negativeWords = ['malo', 'difícil', 'no me gusta', 'complicado', 'odio'];
    
    final lowerText = text.toLowerCase();
    final positiveCount = positiveWords.where((word) => lowerText.contains(word)).length;
    final negativeCount = negativeWords.where((word) => lowerText.contains(word)).length;
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  int _calculateAcceptanceLevel(String sentiment, String text) {
    switch (sentiment) {
      case 'positive': return 4;
      case 'negative': return 2;
      default: return 3;
    }
  }

  String _extractFrequency(String text) {
    if (text.contains('siempre') || text.contains('todos los días') || text.contains('diario')) {
      return 'daily';
    }
    if (text.contains('frecuentemente') || text.contains('seguido') || text.contains('mucho')) {
      return 'often';
    }
    if (text.contains('a veces') || text.contains('ocasionalmente')) {
      return 'sometimes';
    }
    if (text.contains('rara vez') || text.contains('poco')) {
      return 'rarely';
    }
    if (text.contains('nunca') || text.contains('jamás')) {
      return 'never';
    }
    return 'sometimes'; // default
  }

  int _calculateRiskLevel(String habit, String frequency) {
    final highRiskHabits = ['alcohol', 'cigarro', 'comida rápida', 'frituras'];
    final isHighRisk = highRiskHabits.any((risk) => habit.contains(risk));
    
    if (isHighRisk && (frequency == 'daily' || frequency == 'often')) return 5;
    if (isHighRisk && frequency == 'sometimes') return 4;
    if (frequency == 'daily' || frequency == 'often') return 3;
    if (frequency == 'sometimes') return 2;
    return 1;
  }

  String _extractAdoptionStatus(String text) {
    if (text.contains('empezando') || text.contains('comenzando')) return 'starting';
    if (text.contains('mantengo') || text.contains('sigo') || text.contains('continúo')) return 'maintaining';
    if (text.contains('difícil') || text.contains('cuesta') || text.contains('problema')) return 'struggling';
    if (text.contains('dejé') || text.contains('abandoné') || text.contains('ya no')) return 'abandoned';
    if (text.contains('planeo') || text.contains('voy a') || text.contains('quiero')) return 'planning';
    return 'planning'; // default
  }

  String _categorizeHealthyHabit(String habit) {
    if (habit.contains('ejercicio') || habit.contains('caminar') || habit.contains('correr')) {
      return 'exercise';
    }
    if (habit.contains('dormir') || habit.contains('sueño')) {
      return 'sleep';
    }
    if (habit.contains('estrés') || habit.contains('relajación') || habit.contains('meditación')) {
      return 'stress_management';
    }
    if (habit.contains('agua') || habit.contains('hidrat')) {
      return 'hydration';
    }
    return 'nutrition';
  }

  Future<Map<String, dynamic>> _generateMetricsSummary(
    String userId, String sessionId, String userMessage, String geminiResponse
  ) async {
    return {
      'symptoms_mentioned': _symptomsKeywords.where((s) => 
        userMessage.toLowerCase().contains(s.toLowerCase()) ||
        geminiResponse.toLowerCase().contains(s.toLowerCase())
      ).length,
      'risk_factors_mentioned': _riskFactorsKeywords.where((r) => 
        userMessage.toLowerCase().contains(r.toLowerCase()) ||
        geminiResponse.toLowerCase().contains(r.toLowerCase())
      ).length,
      'healthy_habits_mentioned': _healthyHabitsKeywords.where((h) => 
        userMessage.toLowerCase().contains(h.toLowerCase()) ||
        geminiResponse.toLowerCase().contains(h.toLowerCase())
      ).length,
      'tech_acceptance_indicators': _techAcceptanceKeywords.where((t) => 
        userMessage.toLowerCase().contains(t.toLowerCase()) ||
        geminiResponse.toLowerCase().contains(t.toLowerCase())
      ).length,
    };
  }

  List<String> _extractKeyTopics(String userMessage, String geminiResponse) {
    final topics = <String>[];
    final combinedText = '$userMessage $geminiResponse'.toLowerCase();
    
    if (_symptomsKeywords.any((s) => combinedText.contains(s.toLowerCase()))) {
      topics.add('síntomas');
    }
    if (_riskFactorsKeywords.any((r) => combinedText.contains(r.toLowerCase()))) {
      topics.add('factores_de_riesgo');
    }
    if (_healthyHabitsKeywords.any((h) => combinedText.contains(h.toLowerCase()))) {
      topics.add('hábitos_saludables');
    }
    if (_riskEatingHabits.any((e) => combinedText.contains(e.toLowerCase()))) {
      topics.add('hábitos_alimenticios_riesgo');
    }
    
    return topics;
  }

  List<String> _extractActionItems(String geminiResponse) {
    final actionItems = <String>[];
    final lowerResponse = geminiResponse.toLowerCase();
    
    if (lowerResponse.contains('recomiendo') || lowerResponse.contains('sugiero')) {
      actionItems.add('recomendaciones_dadas');
    }
    if (lowerResponse.contains('consulta') || lowerResponse.contains('médico')) {
      actionItems.add('derivación_médica');
    }
    if (lowerResponse.contains('seguimiento') || lowerResponse.contains('monitoreo')) {
      actionItems.add('seguimiento_requerido');
    }
    
    return actionItems;
  }

  /// Procesa todas las métricas de una conversación
  Future<void> processConversationMetrics({
    required String userId,
    required String sessionId,
    required String userMessage,
    required String geminiResponse,
    Map<String, dynamic>? dlModelResponse,
  }) async {
    // Extraer todas las métricas en paralelo
    await Future.wait([
      extractSymptomsKnowledge(
        userId: userId,
        sessionId: sessionId,
        text: userMessage,
        geminiResponse: geminiResponse,
      ),
      extractTechAcceptance(
        userId: userId,
        sessionId: sessionId,
        text: userMessage,
        geminiResponse: geminiResponse,
      ),
      extractEatingHabits(
        userId: userId,
        sessionId: sessionId,
        text: userMessage,
        geminiResponse: geminiResponse,
      ),
      extractHealthyHabits(
        userId: userId,
        sessionId: sessionId,
        text: userMessage,
        geminiResponse: geminiResponse,
      ),
      saveConversationAnalysis(
        userId: userId,
        sessionId: sessionId,
        geminiResponse: geminiResponse,
        dlModelResponse: dlModelResponse,
        userMessage: userMessage,
      ),
    ]);
  }

  /// Extrae métricas de síntomas y conocimiento usando lista de mensajes
  static Future<void> extractSymptomsKnowledgeMetric({
    required String userId,
    required String sessionId,
    required List<ChatMessage> messages,
  }) async {
    try {
      final symptoms = <String>[];
      final knowledge = <String>[];
      
      for (final message in messages) {
        if (message.type == MessageType.user) {
          // Extraer síntomas mencionados por el usuario
          final content = message.content.toLowerCase();
          if (content.contains('dolor') || content.contains('malestar') ||
              content.contains('náusea') || content.contains('acidez')) {
            symptoms.add(message.content);
          }
        } else {
          // Extraer conocimiento compartido por el asistente
          if (message.content.contains('recomendación') ||
              message.content.contains('consejo') ||
              message.content.contains('importante')) {
            knowledge.add(message.content);
          }
        }
      }

      // Crear datos para guardar en lugar de usar SymptomsKnowledgeMetric
      final metricData = {
        'user_id': userId,
        'session_id': sessionId,
        'symptoms': symptoms,
        'knowledge_shared': knowledge,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _saveMetric('user_symptoms', {
        'user_id': userId,
        'symptom_type': symptoms.join(', '),
        'description': knowledge.join(', '),
        'context': {
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (e) {
      print('Error extracting symptoms knowledge metric: $e');
    }
  }

  /// Método auxiliar para guardar métricas
  static Future<void> _saveMetric(String table, Map<String, dynamic> data) async {
    // Implementación para guardar en base de datos
    print('Saving metric to $table: $data');
  }
}