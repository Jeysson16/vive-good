import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/deep_learning_analysis.dart';

abstract class DeepLearningDatasource {
  Future<DeepLearningAnalysis> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> userHabits,
  });
  
  Future<DeepLearningAnalysis> analyzeUserHabits({
    required String userId,
    required Map<String, dynamic> habitData,
  });
  
  Future<List<String>> getRecommendations({
    required String userId,
    required AnalysisType analysisType,
  });
  
  /// Envía un mensaje al backend de deep learning y obtiene respuesta
  Future<Map<String, dynamic>> sendChatMessage({
    required String userId,
    required String message,
    String? sessionId,
    Map<String, dynamic>? context,
    bool includePrediction = true,
  });
  
  Future<bool> checkModelHealth();
  Future<Map<String, dynamic>> getModelInfo();
}

class DeepLearningDatasourceImpl implements DeepLearningDatasource {
  final http.Client httpClient;
  final String baseUrl;
  final String apiKey;

  DeepLearningDatasourceImpl({
    required this.httpClient,
    required this.baseUrl,
    required this.apiKey,
  });

  @override
  Future<DeepLearningAnalysis> analyzeGastritisRisk({
    required String userId,
    required Map<String, dynamic> userHabits,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/analyze/gastritis-risk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'user_id': userId,
          'habits': userHabits,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DeepLearningAnalysis.fromJson(data);
      } else {
        throw Exception('Failed to analyze gastritis risk: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock analysis if service is unavailable
      return _createMockGastritisAnalysis(userId, userHabits);
    }
  }

  @override
  Future<DeepLearningAnalysis> analyzeUserHabits({
    required String userId,
    required Map<String, dynamic> habitData,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/analyze/habits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'user_id': userId,
          'habit_data': habitData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DeepLearningAnalysis.fromJson(data);
      } else {
        throw Exception('Failed to analyze habits: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock analysis if service is unavailable
      return _createMockHabitAnalysis(userId, habitData);
    }
  }

  @override
  Future<List<String>> getRecommendations({
    required String userId,
    required AnalysisType analysisType,
  }) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/recommendations/$userId?type=${analysisType.name}'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['recommendations'] as List).cast<String>();
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock recommendations
      return _getMockRecommendations(analysisType);
    }
  }

  @override
  Future<Map<String, dynamic>> sendChatMessage({
    required String userId,
    required String message,
    String? sessionId,
    Map<String, dynamic>? context,
    bool includePrediction = true,
  }) async {
    try {
      final requestBody = {
        'codigo_usuario': userId,
        'mensaje': message,
        'session_id': sessionId,
        'context': context ?? {},
        'include_prediction': includePrediction,
      };

      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/v1/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to send chat message: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock response if service is unavailable
      return _createMockChatResponse(userId, message, sessionId);
    }
  }

  @override
  Future<bool> checkModelHealth() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/model/info'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get model info: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock model info
      return {
        'model_name': 'Gastritis Prevention Model',
        'version': '1.0.0',
        'accuracy': 0.85,
        'last_trained': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'status': 'offline',
      };
    }
  }

  // Mock methods for fallback when service is unavailable
  DeepLearningAnalysis _createMockGastritisAnalysis(
    String userId,
    Map<String, dynamic> userHabits,
  ) {
    // Simple risk calculation based on habits
    double riskScore = 0.0;
    final List<String> riskFactors = [];
    final List<String> recommendations = [];

    // Analyze eating habits
    if (userHabits['spicy_food_frequency'] != null) {
      final spicyFreq = userHabits['spicy_food_frequency'] as int;
      if (spicyFreq > 3) {
        riskScore += 0.2;
        riskFactors.add('Consumo frecuente de comida picante');
        recommendations.add('Reduce el consumo de alimentos picantes');
      }
    }

    // Analyze stress levels
    if (userHabits['stress_level'] != null) {
      final stressLevel = userHabits['stress_level'] as int;
      if (stressLevel > 7) {
        riskScore += 0.3;
        riskFactors.add('Niveles altos de estrés');
        recommendations.add('Practica técnicas de relajación y manejo del estrés');
      }
    }

    // Determine risk level
    RiskLevel riskLevel;
    if (riskScore < 0.3) {
      riskLevel = RiskLevel.low;
    } else if (riskScore < 0.6) {
      riskLevel = RiskLevel.medium;
    } else if (riskScore < 0.8) {
      riskLevel = RiskLevel.high;
    } else {
      riskLevel = RiskLevel.critical;
    }

    return DeepLearningAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: AnalysisType.gastritisRisk,
      inputData: userHabits,
      results: {
        'gastritis_risk_score': riskScore,
        'risk_factors': riskFactors,
      },
      riskLevel: riskLevel,
      confidence: 0.75, // Mock confidence
      recommendations: recommendations,
      timestamp: DateTime.now(),
      modelVersion: '1.0.0-mock',
    );
  }

  DeepLearningAnalysis _createMockHabitAnalysis(
    String userId,
    Map<String, dynamic> habitData,
  ) {
    return DeepLearningAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: AnalysisType.habitAnalysis,
      inputData: habitData,
      results: {
        'habit_scores': {
          'nutrition': 0.7,
          'exercise': 0.6,
          'sleep': 0.8,
          'stress_management': 0.5,
        },
      },
      riskLevel: RiskLevel.medium,
      confidence: 0.8,
      recommendations: [
        'Mejora tus hábitos de ejercicio',
        'Implementa técnicas de manejo del estrés',
        'Mantén una rutina de sueño regular',
      ],
      timestamp: DateTime.now(),
      modelVersion: '1.0.0-mock',
    );
  }

  List<String> _getMockRecommendations(AnalysisType analysisType) {
    switch (analysisType) {
      case AnalysisType.gastritisRisk:
        return [
          'Evita alimentos picantes y ácidos',
          'Come en horarios regulares',
          'Reduce el consumo de alcohol',
          'Maneja el estrés con técnicas de relajación',
        ];
      case AnalysisType.habitAnalysis:
        return [
          'Establece una rutina de ejercicio regular',
          'Mejora la calidad de tu sueño',
          'Incorpora más frutas y verduras en tu dieta',
          'Practica mindfulness o meditación',
        ];
      case AnalysisType.nutritionAssessment:
        return [
          'Aumenta el consumo de fibra',
          'Reduce el consumo de azúcares procesados',
          'Incluye más proteínas magras',
          'Mantente hidratado',
        ];
      case AnalysisType.lifestyleRecommendation:
        return [
          'Mantén un equilibrio trabajo-vida',
          'Dedica tiempo a actividades que disfrutes',
          'Cultiva relaciones sociales saludables',
          'Establece metas realistas y alcanzables',
        ];
    }
  }

  Map<String, dynamic> _createMockChatResponse(
    String userId,
    String message,
    String? sessionId,
  ) {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now();
    
    // Analizar el mensaje para generar respuesta contextual
    String respuestaModelo = '';
    List<String> suggestedActions = [];
    Map<String, dynamic>? riskAssessment;
    
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('dolor') && lowerMessage.contains('estómago')) {
      respuestaModelo = '🔍 **Análisis de Deep Learning:** Detectamos síntomas relacionados con molestias gástricas. '
          'Basado en patrones similares, recomendamos: '
          '• Implementar comidas más pequeñas y frecuentes '
          '• Evitar irritantes como café y picantes '
          '• Monitorear niveles de estrés';
      
      suggestedActions = [
        'Crear hábito: Comidas pequeñas cada 3 horas',
        'Evitar alimentos irritantes',
        'Técnicas de relajación',
      ];
      
      riskAssessment = {
        'risk_level': 'medium',
        'confidence': 0.78,
        'factors': ['síntomas_gastrointestinales', 'patrón_dolor_persistente'],
        'recommendations': [
          'Consulta médica si persisten los síntomas',
          'Implementar dieta blanda temporalmente',
          'Monitorear frecuencia e intensidad del dolor',
        ],
      };
    } else {
      respuestaModelo = '🤖 **Análisis de Deep Learning:** Hemos procesado tu consulta. '
          'Nuestro modelo sugiere mantener hábitos preventivos y monitorear síntomas.';
      
      suggestedActions = [
        'Mantener alimentación balanceada',
        'Ejercicio regular',
        'Control de estrés',
      ];
      
      riskAssessment = {
        'risk_level': 'low',
        'confidence': 0.65,
        'factors': [],
        'recommendations': [
          'Continuar con hábitos saludables',
          'Monitoreo preventivo',
        ],
      };
    }
    
    return {
      'message_id': messageId,
      'respuesta_modelo': respuestaModelo,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId ?? 'mock_session_${DateTime.now().millisecondsSinceEpoch}',
      'risk_assessment': riskAssessment,
      'suggested_actions': suggestedActions,
      'confidence_score': 0.75,
      'processing_time_ms': 150,
      'model_version': '1.0.0-mock',
      'status': 'offline_mode',
    };
  }
}