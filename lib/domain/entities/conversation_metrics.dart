/// Entidad base para métricas de conversación
abstract class ConversationMetric {
  final String id;
  final String userId;
  final String sessionId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const ConversationMetric({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.createdAt,
    required this.metadata,
  });
}

/// Entidad para métricas de conocimiento de síntomas
class SymptomsKnowledgeMetric extends ConversationMetric {
  final String symptomType;
  final String knowledgeLevel;
  final List<String> riskFactorsIdentified;
  final List<String> symptomsMentioned;

  const SymptomsKnowledgeMetric({
    required super.id,
    required super.userId,
    required super.sessionId,
    required super.createdAt,
    required super.metadata,
    required this.symptomType,
    required this.knowledgeLevel,
    required this.riskFactorsIdentified,
    required this.symptomsMentioned,
  });

  factory SymptomsKnowledgeMetric.fromMap(Map<String, dynamic> map) {
    return SymptomsKnowledgeMetric(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sessionId: map['session_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      symptomType: map['symptom_type'] as String,
      knowledgeLevel: map['knowledge_level'] as String,
      riskFactorsIdentified: List<String>.from(map['risk_factors_identified'] ?? []),
      symptomsMentioned: List<String>.from(map['symptoms_mentioned'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'symptom_type': symptomType,
      'knowledge_level': knowledgeLevel,
      'risk_factors_identified': riskFactorsIdentified,
      'symptoms_mentioned': symptomsMentioned,
    };
  }
}

/// Entidad para métricas de hábitos alimenticios
class EatingHabitsMetric extends ConversationMetric {
  final String habitType;
  final String riskLevel;
  final String? frequency;
  final List<String> habitsIdentified;
  final List<String> recommendationsGiven;

  const EatingHabitsMetric({
    required super.id,
    required super.userId,
    required super.sessionId,
    required super.createdAt,
    required super.metadata,
    required this.habitType,
    required this.riskLevel,
    this.frequency,
    required this.habitsIdentified,
    required this.recommendationsGiven,
  });

  factory EatingHabitsMetric.fromMap(Map<String, dynamic> map) {
    return EatingHabitsMetric(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sessionId: map['session_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      habitType: map['habit_type'] as String,
      riskLevel: map['risk_level'] as String,
      frequency: map['frequency'] as String?,
      habitsIdentified: List<String>.from(map['habits_identified'] ?? []),
      recommendationsGiven: List<String>.from(map['recommendations_given'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'habit_type': habitType,
      'risk_level': riskLevel,
      'frequency': frequency,
      'habits_identified': habitsIdentified,
      'recommendations_given': recommendationsGiven,
    };
  }
}

/// Entidad para métricas de hábitos saludables
class HealthyHabitsMetric extends ConversationMetric {
  final String habitCategory;
  final String adoptionStatus;
  final String? commitmentLevel;
  final List<String> habitsAdopted;
  final List<String> barriersIdentified;
  final DateTime updatedAt;

  const HealthyHabitsMetric({
    required super.id,
    required super.userId,
    required super.sessionId,
    required super.createdAt,
    required super.metadata,
    required this.habitCategory,
    required this.adoptionStatus,
    this.commitmentLevel,
    required this.habitsAdopted,
    required this.barriersIdentified,
    required this.updatedAt,
  });

  factory HealthyHabitsMetric.fromMap(Map<String, dynamic> map) {
    return HealthyHabitsMetric(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sessionId: map['session_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      habitCategory: map['habit_category'] as String,
      adoptionStatus: map['adoption_status'] as String,
      commitmentLevel: map['commitment_level'] as String?,
      habitsAdopted: List<String>.from(map['habits_adopted'] ?? []),
      barriersIdentified: List<String>.from(map['barriers_identified'] ?? []),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'habit_category': habitCategory,
      'adoption_status': adoptionStatus,
      'commitment_level': commitmentLevel,
      'habits_adopted': habitsAdopted,
      'barriers_identified': barriersIdentified,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Entidad para métricas de aceptación tecnológica
class TechAcceptanceMetric extends ConversationMetric {
  final String toolType;
  final String acceptanceLevel;
  final String? usageFrequency;
  final String? feedbackSentiment;
  final List<String> featuresUsed;
  final List<String> suggestionsGiven;

  const TechAcceptanceMetric({
    required super.id,
    required super.userId,
    required super.sessionId,
    required super.createdAt,
    required super.metadata,
    required this.toolType,
    required this.acceptanceLevel,
    this.usageFrequency,
    this.feedbackSentiment,
    required this.featuresUsed,
    required this.suggestionsGiven,
  });

  factory TechAcceptanceMetric.fromMap(Map<String, dynamic> map) {
    return TechAcceptanceMetric(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sessionId: map['session_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      toolType: map['tool_type'] as String,
      acceptanceLevel: map['acceptance_level'] as String,
      usageFrequency: map['usage_frequency'] as String?,
      feedbackSentiment: map['feedback_sentiment'] as String?,
      featuresUsed: List<String>.from(map['features_used'] ?? []),
      suggestionsGiven: List<String>.from(map['suggestions_given'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'tool_type': toolType,
      'acceptance_level': acceptanceLevel,
      'usage_frequency': usageFrequency,
      'feedback_sentiment': feedbackSentiment,
      'features_used': featuresUsed,
      'suggestions_given': suggestionsGiven,
    };
  }
}