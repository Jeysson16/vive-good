import 'package:equatable/equatable.dart';

class RiskHabitsIndicators extends Equatable {
  final String userId;
  final String userName;
  final int totalRiskHabits;
  final int highRiskHabits;
  final int mediumRiskHabits;
  final int lowRiskHabits;
  final double riskScore;
  final String riskLevel; // 'Alto', 'Medio', 'Bajo'
  final List<String> mainRiskCategories;
  final Map<String, int> habitsByCategory;
  final DateTime evaluationDate;
  final String? recommendations;

  const RiskHabitsIndicators({
    required this.userId,
    required this.userName,
    required this.totalRiskHabits,
    required this.highRiskHabits,
    required this.mediumRiskHabits,
    required this.lowRiskHabits,
    required this.riskScore,
    required this.riskLevel,
    required this.mainRiskCategories,
    required this.habitsByCategory,
    required this.evaluationDate,
    this.recommendations,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        totalRiskHabits,
        highRiskHabits,
        mediumRiskHabits,
        lowRiskHabits,
        riskScore,
        riskLevel,
        mainRiskCategories,
        habitsByCategory,
        evaluationDate,
        recommendations,
      ];

  RiskHabitsIndicators copyWith({
    String? userId,
    String? userName,
    int? totalRiskHabits,
    int? highRiskHabits,
    int? mediumRiskHabits,
    int? lowRiskHabits,
    double? riskScore,
    String? riskLevel,
    List<String>? mainRiskCategories,
    Map<String, int>? habitsByCategory,
    DateTime? evaluationDate,
    String? recommendations,
  }) {
    return RiskHabitsIndicators(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      totalRiskHabits: totalRiskHabits ?? this.totalRiskHabits,
      highRiskHabits: highRiskHabits ?? this.highRiskHabits,
      mediumRiskHabits: mediumRiskHabits ?? this.mediumRiskHabits,
      lowRiskHabits: lowRiskHabits ?? this.lowRiskHabits,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      mainRiskCategories: mainRiskCategories ?? this.mainRiskCategories,
      habitsByCategory: habitsByCategory ?? this.habitsByCategory,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}