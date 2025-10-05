import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepLearningDatasource {
  final String _baseUrl = 'https://homepage-focusing-lanka-describing.trycloudflare.com';
  final http.Client _httpClient;

  DeepLearningDatasource({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Predice el riesgo de gastritis basado en los hábitos del usuario
  Future<GastritisRiskPrediction> predictGastritisRisk({
    required Map<String, dynamic> userHabits,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'habits': userHabits,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GastritisRiskPrediction.fromJson(data);
      } else {
        throw Exception('Error en predicción: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
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
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'current_habits': currentHabits,
          'risk_level': riskLevel,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = data['recommendations'] as List;
        return recommendations
            .map((rec) => HabitRecommendation.fromJson(rec))
            .toList();
      } else {
        throw Exception('Error obteniendo recomendaciones: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
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
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'habit_history': habitHistory,
          'days_period': daysPeriod ?? 30,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HabitAnalysis.fromJson(data);
      } else {
        throw Exception('Error en análisis: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al analizar patrones: $e');
    }
  }

  /// Verifica el estado de salud del modelo
  Future<bool> checkModelHealth() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene información del modelo
  Future<ModelInfo> getModelInfo() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/info'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ModelInfo.fromJson(data);
      } else {
        throw Exception('Error obteniendo info del modelo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener información del modelo: $e');
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