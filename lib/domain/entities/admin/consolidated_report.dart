import 'package:equatable/equatable.dart';

class ConsolidatedReport extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final String? roleName;
  final DateTime? lastLogin;
  final int totalHabits;
  final int completedHabits;
  final double completionRate;
  final int totalConsultations;
  final double? averageRating;
  final double? techAcceptanceScore;
  final String? techAcceptanceLevel;
  final double? knowledgeScore;
  final String? knowledgeLevel;
  final int totalRiskHabits;
  final double? riskScore;
  final String? riskLevel;
  final DateTime createdAt;
  final bool isActive;

  const ConsolidatedReport({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.roleName,
    this.lastLogin,
    required this.totalHabits,
    required this.completedHabits,
    required this.completionRate,
    required this.totalConsultations,
    this.averageRating,
    this.techAcceptanceScore,
    this.techAcceptanceLevel,
    this.knowledgeScore,
    this.knowledgeLevel,
    required this.totalRiskHabits,
    this.riskScore,
    this.riskLevel,
    required this.createdAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        userEmail,
        roleName,
        lastLogin,
        totalHabits,
        completedHabits,
        completionRate,
        totalConsultations,
        averageRating,
        techAcceptanceScore,
        techAcceptanceLevel,
        knowledgeScore,
        knowledgeLevel,
        totalRiskHabits,
        riskScore,
        riskLevel,
        createdAt,
        isActive,
      ];

  ConsolidatedReport copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? roleName,
    DateTime? lastLogin,
    int? totalHabits,
    int? completedHabits,
    double? completionRate,
    int? totalConsultations,
    double? averageRating,
    double? techAcceptanceScore,
    String? techAcceptanceLevel,
    double? knowledgeScore,
    String? knowledgeLevel,
    int? totalRiskHabits,
    double? riskScore,
    String? riskLevel,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ConsolidatedReport(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      roleName: roleName ?? this.roleName,
      lastLogin: lastLogin ?? this.lastLogin,
      totalHabits: totalHabits ?? this.totalHabits,
      completedHabits: completedHabits ?? this.completedHabits,
      completionRate: completionRate ?? this.completionRate,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      averageRating: averageRating ?? this.averageRating,
      techAcceptanceScore: techAcceptanceScore ?? this.techAcceptanceScore,
      techAcceptanceLevel: techAcceptanceLevel ?? this.techAcceptanceLevel,
      knowledgeScore: knowledgeScore ?? this.knowledgeScore,
      knowledgeLevel: knowledgeLevel ?? this.knowledgeLevel,
      totalRiskHabits: totalRiskHabits ?? this.totalRiskHabits,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}