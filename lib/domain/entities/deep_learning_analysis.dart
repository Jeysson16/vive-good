import 'package:equatable/equatable.dart';

enum AnalysisType {
  gastritisRisk,
  habitAnalysis,
  nutritionAssessment,
  lifestyleRecommendation,
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

class DeepLearningAnalysis extends Equatable {
  final String id;
  final String userId;
  final AnalysisType type;
  final Map<String, dynamic> inputData;
  final Map<String, dynamic> results;
  final RiskLevel riskLevel;
  final double confidence;
  final List<String> recommendations;
  final List<String> warnings;
  final DateTime timestamp;
  final String modelVersion;
  final Map<String, dynamic>? metadata;

  const DeepLearningAnalysis({
    required this.id,
    required this.userId,
    required this.type,
    required this.inputData,
    required this.results,
    required this.riskLevel,
    required this.confidence,
    required this.recommendations,
    this.warnings = const [],
    required this.timestamp,
    required this.modelVersion,
    this.metadata,
  });

  DeepLearningAnalysis copyWith({
    String? id,
    String? userId,
    AnalysisType? type,
    Map<String, dynamic>? inputData,
    Map<String, dynamic>? results,
    RiskLevel? riskLevel,
    double? confidence,
    List<String>? recommendations,
    List<String>? warnings,
    DateTime? timestamp,
    String? modelVersion,
    Map<String, dynamic>? metadata,
  }) {
    return DeepLearningAnalysis(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      inputData: inputData ?? this.inputData,
      results: results ?? this.results,
      riskLevel: riskLevel ?? this.riskLevel,
      confidence: confidence ?? this.confidence,
      recommendations: recommendations ?? this.recommendations,
      warnings: warnings ?? this.warnings,
      timestamp: timestamp ?? this.timestamp,
      modelVersion: modelVersion ?? this.modelVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters for easy access to common analysis results
  double? get gastritisRiskScore => results['gastritis_risk_score'] as double?;
  Map<String, double>? get habitScores => results['habit_scores'] as Map<String, double>?;
  List<String>? get identifiedRiskFactors => (results['risk_factors'] as List?)?.cast<String>();
  Map<String, dynamic>? get nutritionalAnalysis => results['nutritional_analysis'] as Map<String, dynamic>?;

  bool get isHighRisk => riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical;
  bool get isReliable => confidence >= 0.7;
  
  String get riskLevelText {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Bajo';
      case RiskLevel.medium:
        return 'Medio';
      case RiskLevel.high:
        return 'Alto';
      case RiskLevel.critical:
        return 'Crítico';
    }
  }

  String get typeText {
    switch (type) {
      case AnalysisType.gastritisRisk:
        return 'Análisis de Riesgo de Gastritis';
      case AnalysisType.habitAnalysis:
        return 'Análisis de Hábitos';
      case AnalysisType.nutritionAssessment:
        return 'Evaluación Nutricional';
      case AnalysisType.lifestyleRecommendation:
        return 'Recomendaciones de Estilo de Vida';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'input_data': inputData,
      'results': results,
      'risk_level': riskLevel.name,
      'confidence': confidence,
      'recommendations': recommendations,
      'warnings': warnings,
      'timestamp': timestamp.toIso8601String(),
      'model_version': modelVersion,
      'metadata': metadata,
    };
  }

  factory DeepLearningAnalysis.fromJson(Map<String, dynamic> json) {
    return DeepLearningAnalysis(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: AnalysisType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnalysisType.gastritisRisk,
      ),
      inputData: json['input_data'] as Map<String, dynamic>,
      results: json['results'] as Map<String, dynamic>,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => RiskLevel.low,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      recommendations: (json['recommendations'] as List).cast<String>(),
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      modelVersion: json['model_version'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        inputData,
        results,
        riskLevel,
        confidence,
        recommendations,
        warnings,
        timestamp,
        modelVersion,
        metadata,
      ];
}