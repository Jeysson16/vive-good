import 'package:equatable/equatable.dart';

/// Entidad que representa los indicadores mensuales expandidos del progreso del usuario
class MonthlyIndicators extends Equatable {
  // Métricas de hábitos actuales
  final String bestDay;
  final String mostConsistentHabit;
  final String areaToImprove;
  final String bestCategory;
  final String categoryNeedsAttention;
  final String mostProductiveHour;
  final double weeklyChange;

  // Métricas de salud
  final double symptomsKnowledgePct;
  final double techAcceptanceRate;
  final int riskyEatingHabitsCount;
  final double healthyHabitsAdoptionPct;
  final String mostAcceptedTool;
  final String riskiestHabit;
  final String bestAdoptedCategory;

  // Análisis de conversaciones
  final String keyTopic;
  final int conversationCount;

  // Métricas avanzadas
  final int currentStreak;
  final double wellnessScore;

  const MonthlyIndicators({
    required this.bestDay,
    required this.mostConsistentHabit,
    required this.areaToImprove,
    required this.bestCategory,
    required this.categoryNeedsAttention,
    required this.mostProductiveHour,
    required this.weeklyChange,
    required this.symptomsKnowledgePct,
    required this.techAcceptanceRate,
    required this.riskyEatingHabitsCount,
    required this.healthyHabitsAdoptionPct,
    required this.mostAcceptedTool,
    required this.riskiestHabit,
    required this.bestAdoptedCategory,
    required this.keyTopic,
    required this.conversationCount,
    required this.currentStreak,
    required this.wellnessScore,
  });

  factory MonthlyIndicators.fromMap(Map<String, dynamic> map) {
    return MonthlyIndicators(
      bestDay: map['best_day'] as String? ?? 'Lunes',
      mostConsistentHabit: map['most_consistent_habit'] as String? ?? 'Sin datos',
      areaToImprove: map['area_to_improve'] as String? ?? 'Sin datos',
      bestCategory: map['best_category'] as String? ?? 'Sin datos',
      categoryNeedsAttention: map['category_needs_attention'] as String? ?? 'Sin datos',
      mostProductiveHour: map['most_productive_hour'] as String? ?? '08:00',
      weeklyChange: (map['weekly_change'] as num?)?.toDouble() ?? 0.0,
      symptomsKnowledgePct: (map['symptoms_knowledge_pct'] as num?)?.toDouble() ?? 0.0,
      techAcceptanceRate: (map['tech_acceptance_rate'] as num?)?.toDouble() ?? 0.0,
      riskyEatingHabitsCount: map['risky_eating_habits_count'] as int? ?? 0,
      healthyHabitsAdoptionPct: (map['healthy_habits_adoption_pct'] as num?)?.toDouble() ?? 0.0,
      mostAcceptedTool: map['most_accepted_tool'] as String? ?? 'Sin datos',
      riskiestHabit: map['riskiest_habit'] as String? ?? 'Sin datos',
      bestAdoptedCategory: map['best_adopted_category'] as String? ?? 'Sin datos',
      keyTopic: map['key_topic'] as String? ?? 'Sin datos',
      conversationCount: map['conversation_count'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      wellnessScore: (map['wellness_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'best_day': bestDay,
      'most_consistent_habit': mostConsistentHabit,
      'area_to_improve': areaToImprove,
      'best_category': bestCategory,
      'category_needs_attention': categoryNeedsAttention,
      'most_productive_hour': mostProductiveHour,
      'weekly_change': weeklyChange,
      'symptoms_knowledge_pct': symptomsKnowledgePct,
      'tech_acceptance_rate': techAcceptanceRate,
      'risky_eating_habits_count': riskyEatingHabitsCount,
      'healthy_habits_adoption_pct': healthyHabitsAdoptionPct,
      'most_accepted_tool': mostAcceptedTool,
      'riskiest_habit': riskiestHabit,
      'best_adopted_category': bestAdoptedCategory,
      'key_topic': keyTopic,
      'conversation_count': conversationCount,
      'current_streak': currentStreak,
      'wellness_score': wellnessScore,
    };
  }

  MonthlyIndicators copyWith({
    String? bestDay,
    String? mostConsistentHabit,
    String? areaToImprove,
    String? bestCategory,
    String? categoryNeedsAttention,
    String? mostProductiveHour,
    double? weeklyChange,
    double? symptomsKnowledgePct,
    double? techAcceptanceRate,
    int? riskyEatingHabitsCount,
    double? healthyHabitsAdoptionPct,
    String? mostAcceptedTool,
    String? riskiestHabit,
    String? bestAdoptedCategory,
    String? keyTopic,
    int? conversationCount,
    int? currentStreak,
    double? wellnessScore,
  }) {
    return MonthlyIndicators(
      bestDay: bestDay ?? this.bestDay,
      mostConsistentHabit: mostConsistentHabit ?? this.mostConsistentHabit,
      areaToImprove: areaToImprove ?? this.areaToImprove,
      bestCategory: bestCategory ?? this.bestCategory,
      categoryNeedsAttention: categoryNeedsAttention ?? this.categoryNeedsAttention,
      mostProductiveHour: mostProductiveHour ?? this.mostProductiveHour,
      weeklyChange: weeklyChange ?? this.weeklyChange,
      symptomsKnowledgePct: symptomsKnowledgePct ?? this.symptomsKnowledgePct,
      techAcceptanceRate: techAcceptanceRate ?? this.techAcceptanceRate,
      riskyEatingHabitsCount: riskyEatingHabitsCount ?? this.riskyEatingHabitsCount,
      healthyHabitsAdoptionPct: healthyHabitsAdoptionPct ?? this.healthyHabitsAdoptionPct,
      mostAcceptedTool: mostAcceptedTool ?? this.mostAcceptedTool,
      riskiestHabit: riskiestHabit ?? this.riskiestHabit,
      bestAdoptedCategory: bestAdoptedCategory ?? this.bestAdoptedCategory,
      keyTopic: keyTopic ?? this.keyTopic,
      conversationCount: conversationCount ?? this.conversationCount,
      currentStreak: currentStreak ?? this.currentStreak,
      wellnessScore: wellnessScore ?? this.wellnessScore,
    );
  }

  @override
  List<Object?> get props => [
        bestDay,
        mostConsistentHabit,
        areaToImprove,
        bestCategory,
        categoryNeedsAttention,
        mostProductiveHour,
        weeklyChange,
        symptomsKnowledgePct,
        techAcceptanceRate,
        riskyEatingHabitsCount,
        healthyHabitsAdoptionPct,
        mostAcceptedTool,
        riskiestHabit,
        bestAdoptedCategory,
        keyTopic,
        conversationCount,
        currentStreak,
        wellnessScore,
      ];

  @override
  String toString() {
    return 'MonthlyIndicators(bestDay: $bestDay, mostConsistentHabit: $mostConsistentHabit, '
           'areaToImprove: $areaToImprove, wellnessScore: $wellnessScore)';
  }
}