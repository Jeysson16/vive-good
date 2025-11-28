import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../repositories/auth/deep_learning_auth_repository.dart';

class DeepLearningDatasource {
  final String _baseUrl = 'https://api.jeysson.cloud/api/v1';
  final http.Client _httpClient;
  final DeepLearningAuthRepositoryImpl _authRepository;

  DeepLearningDatasource({
    http.Client? httpClient,
    required DeepLearningAuthRepositoryImpl authRepository,
  }) : _httpClient = httpClient ?? http.Client(),
       _authRepository = authRepository;

  /// Obtiene headers autenticados para las peticiones
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await _authRepository.getValidToken();
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      developer.log(
        '🔐 [DL DATASOURCE] Headers autenticados agregados',
        name: 'DeepLearningDatasource',
      );
    } else {
      developer.log(
        '⚠️ [DL DATASOURCE] No se pudo obtener token válido',
        name: 'DeepLearningDatasource',
      );
      throw Exception('No se pudo obtener token de autenticación válido');
    }
    
    return headers;
  }

  /// Predice el riesgo de gastritis basado en los hábitos del usuario
  Future<GastritisRiskPrediction> predictGastritisRisk({
    required Map<String, dynamic> userHabits,
    required String userId,
  }) async {
    try {
      final headers = await _getAuthenticatedHeaders();
      final url = '$_baseUrl/predict';
      
      developer.log(
        '🤖 [DL DATASOURCE] Prediciendo riesgo de gastritis...',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '🤖 [DL DATASOURCE] URL: $url',
        name: 'DeepLearningDatasource',
      );
      
      final requestBody = {
        'user_id': userId,
        'habits': userHabits,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      developer.log(
        '🤖 [DL DATASOURCE] Request body: ${jsonEncode(requestBody)}',
        name: 'DeepLearningDatasource',
      );

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      developer.log(
        '🤖 [DL DATASOURCE] Response status: ${response.statusCode}',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '🤖 [DL DATASOURCE] Response body: ${response.body}',
        name: 'DeepLearningDatasource',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log(
          '✅ [DL DATASOURCE] Predicción exitosa',
          name: 'DeepLearningDatasource',
        );
        return GastritisRiskPrediction.fromJson(data);
      } else {
        developer.log(
          '❌ [DL DATASOURCE] Error en predicción: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningDatasource',
        );
        throw Exception('Error en predicción: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL DATASOURCE] Excepción en predicción: $e',
        name: 'DeepLearningDatasource',
      );
      throw Exception('Error al conectar con el modelo de deep learning: $e');
    }
  }

  /// Obtiene recomendaciones personalizadas basadas en el análisis
  Future<List<HabitRecommendation>> getHabitRecommendations({
    required String userId,
    required Map<String, dynamic> currentHabits,
    required double riskLevel,
  }) async {
    try {
      final headers = await _getAuthenticatedHeaders();
      final url = '$_baseUrl/chat/send';
      
      developer.log(
        '💬 [DL DATASOURCE] Obteniendo recomendaciones de hábitos...',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '💬 [DL DATASOURCE] URL: $url',
        name: 'DeepLearningDatasource',
      );
      
      final requestBody = {
        'user_id': userId,
        'current_habits': currentHabits,
        'risk_level': riskLevel,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      developer.log(
        '💬 [DL DATASOURCE] Request body: ${jsonEncode(requestBody)}',
        name: 'DeepLearningDatasource',
      );

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      developer.log(
        '💬 [DL DATASOURCE] Response status: ${response.statusCode}',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '💬 [DL DATASOURCE] Response body: ${response.body}',
        name: 'DeepLearningDatasource',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = data['recommendations'] as List;
        developer.log(
          '✅ [DL DATASOURCE] Recomendaciones obtenidas: ${recommendations.length}',
          name: 'DeepLearningDatasource',
        );
        return recommendations
            .map((rec) => HabitRecommendation.fromJson(rec))
            .toList();
      } else {
        developer.log(
          '❌ [DL DATASOURCE] Error obteniendo recomendaciones: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningDatasource',
        );
        throw Exception('Error obteniendo recomendaciones: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL DATASOURCE] Excepción obteniendo recomendaciones: $e',
        name: 'DeepLearningDatasource',
      );
      throw Exception('Error al obtener recomendaciones: $e');
    }
  }

  /// Analiza patrones de hábitos para detectar tendencias
  Future<HabitAnalysis> analyzeHabitPatterns({
    required String userId,
    required List<Map<String, dynamic>> habitHistory,
    int? daysPeriod,
  }) async {
    try {
      final headers = await _getAuthenticatedHeaders();
      final url = '$_baseUrl/sequences/analyze';
      
      developer.log(
        '📊 [DL DATASOURCE] Analizando patrones de hábitos...',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '📊 [DL DATASOURCE] URL: $url',
        name: 'DeepLearningDatasource',
      );
      
      final requestBody = {
        'user_id': userId,
        'habit_history': habitHistory,
        'days_period': daysPeriod ?? 30,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      developer.log(
        '📊 [DL DATASOURCE] Request body: ${jsonEncode(requestBody)}',
        name: 'DeepLearningDatasource',
      );

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      developer.log(
        '📊 [DL DATASOURCE] Response status: ${response.statusCode}',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '📊 [DL DATASOURCE] Response body: ${response.body}',
        name: 'DeepLearningDatasource',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log(
          '✅ [DL DATASOURCE] Análisis de patrones exitoso',
          name: 'DeepLearningDatasource',
        );
        return HabitAnalysis.fromJson(data);
      } else {
        developer.log(
          '❌ [DL DATASOURCE] Error en análisis: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningDatasource',
        );
        throw Exception('Error en análisis: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL DATASOURCE] Excepción en análisis: $e',
        name: 'DeepLearningDatasource',
      );
      throw Exception('Error al analizar patrones: $e');
    }
  }

  /// Verifica el estado de salud del modelo
  Future<bool> checkModelHealth() async {
    try {
      final headers = await _getAuthenticatedHeaders();
      final url = '$_baseUrl/health';
      
      developer.log(
        '🏥 [DL DATASOURCE] Verificando salud del modelo...',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '🏥 [DL DATASOURCE] URL: $url',
        name: 'DeepLearningDatasource',
      );

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      );

      developer.log(
        '🏥 [DL DATASOURCE] Response status: ${response.statusCode}',
        name: 'DeepLearningDatasource',
      );

      final isHealthy = response.statusCode == 200;
      
      developer.log(
        '🏥 [DL DATASOURCE] Modelo saludable: $isHealthy',
        name: 'DeepLearningDatasource',
      );

      return isHealthy;
    } catch (e) {
      developer.log(
        '💥 [DL DATASOURCE] Error verificando salud: $e',
        name: 'DeepLearningDatasource',
      );
      return false;
    }
  }



  /// Obtiene información del modelo
  Future<ModelInfo> getModelInfo() async {
    try {
      final headers = await _getAuthenticatedHeaders();
      final url = '$_baseUrl/health';
      
      developer.log(
        'ℹ️ [DL DATASOURCE] Obteniendo información del modelo...',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        'ℹ️ [DL DATASOURCE] URL: $url',
        name: 'DeepLearningDatasource',
      );

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      );

      developer.log(
        'ℹ️ [DL DATASOURCE] Response status: ${response.statusCode}',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        'ℹ️ [DL DATASOURCE] Response body: ${response.body}',
        name: 'DeepLearningDatasource',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log(
          '✅ [DL DATASOURCE] Información del modelo obtenida',
          name: 'DeepLearningDatasource',
        );
        return ModelInfo.fromJson(data);
      } else {
        developer.log(
          '❌ [DL DATASOURCE] Error obteniendo info del modelo: ${response.statusCode}',
          name: 'DeepLearningDatasource',
        );
        throw Exception('Error obteniendo info del modelo: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL DATASOURCE] Excepción obteniendo info del modelo: $e',
        name: 'DeepLearningDatasource',
      );
      throw Exception('Error al obtener información del modelo: $e');
    }
  }

  /// Analiza síntomas médicos usando el endpoint de análisis médico
  Future<Map<String, dynamic>> analyzeMedicalSymptoms({
    required String message,
    required String userId,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final headers = await _getAuthenticatedHeaders();
      final url = '$_baseUrl/medical-analysis/analyze';
      
      developer.log(
        '🏥 [DL DATASOURCE] Analizando síntomas médicos...',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '🏥 [DL DATASOURCE] URL: $url',
        name: 'DeepLearningDatasource',
      );
      
      final requestBody = {
        'message': message,
        'user_id': userId,
        'context': additionalContext ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'analysis_type': 'gastritis_prevention',
        'target_population': 'university_students',
      };
      
      developer.log(
        '🏥 [DL DATASOURCE] Request body: ${jsonEncode(requestBody)}',
        name: 'DeepLearningDatasource',
      );

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      developer.log(
        '🏥 [DL DATASOURCE] Response status: ${response.statusCode}',
        name: 'DeepLearningDatasource',
      );
      
      developer.log(
        '🏥 [DL DATASOURCE] Response body: ${response.body}',
        name: 'DeepLearningDatasource',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        developer.log(
          '✅ [DL DATASOURCE] Análisis médico exitoso',
          name: 'DeepLearningDatasource',
        );
        
        return responseData;
      } else {
        developer.log(
          '❌ [DL DATASOURCE] Error en análisis médico: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningDatasource',
        );
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL DATASOURCE] Excepción en análisis médico: $e',
        name: 'DeepLearningDatasource',
      );
      throw Exception('Error al conectar con el análisis médico: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

// Modelos de datos para las respuestas del API
class GastritisRiskPrediction {
  final String userId;
  final double riskLevel;
  final String riskCategory;
  final Map<String, double> factorContributions;
  final List<String> riskFactors;
  final DateTime timestamp;
  final double confidence;

  GastritisRiskPrediction({
    required this.userId,
    required this.riskLevel,
    required this.riskCategory,
    required this.factorContributions,
    required this.riskFactors,
    required this.timestamp,
    required this.confidence,
  });

  factory GastritisRiskPrediction.fromJson(Map<String, dynamic> json) {
    return GastritisRiskPrediction(
      userId: json['user_id'] ?? '',
      riskLevel: (json['risk_level'] ?? 0.0).toDouble(),
      riskCategory: json['risk_category'] ?? 'unknown',
      factorContributions: Map<String, double>.from(
        json['factor_contributions'] ?? {},
      ),
      riskFactors: List<String>.from(json['risk_factors'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'risk_level': riskLevel,
      'risk_category': riskCategory,
      'factor_contributions': factorContributions,
      'risk_factors': riskFactors,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
    };
  }
}

class HabitRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final int priority;
  final double impactScore;
  final List<String> actionSteps;
  final String timeframe;

  HabitRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.impactScore,
    required this.actionSteps,
    required this.timeframe,
  });

  factory HabitRecommendation.fromJson(Map<String, dynamic> json) {
    return HabitRecommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 0,
      impactScore: (json['impact_score'] ?? 0.0).toDouble(),
      actionSteps: List<String>.from(json['action_steps'] ?? []),
      timeframe: json['timeframe'] ?? '',
    );
  }
}

class HabitAnalysis {
  final String userId;
  final Map<String, dynamic> patterns;
  final List<String> trends;
  final Map<String, double> improvements;
  final List<String> concerns;
  final DateTime analysisDate;

  HabitAnalysis({
    required this.userId,
    required this.patterns,
    required this.trends,
    required this.improvements,
    required this.concerns,
    required this.analysisDate,
  });

  factory HabitAnalysis.fromJson(Map<String, dynamic> json) {
    return HabitAnalysis(
      userId: json['user_id'] ?? '',
      patterns: Map<String, dynamic>.from(json['patterns'] ?? {}),
      trends: List<String>.from(json['trends'] ?? []),
      improvements: Map<String, double>.from(json['improvements'] ?? {}),
      concerns: List<String>.from(json['concerns'] ?? []),
      analysisDate: DateTime.parse(json['analysis_date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ModelInfo {
  final String version;
  final String name;
  final DateTime lastTrained;
  final double accuracy;
  final Map<String, dynamic> metrics;

  ModelInfo({
    required this.version,
    required this.name,
    required this.lastTrained,
    required this.accuracy,
    required this.metrics,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      version: json['version'] ?? '',
      name: json['name'] ?? '',
      lastTrained: DateTime.parse(json['last_trained'] ?? DateTime.now().toIso8601String()),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
    );
  }
}
