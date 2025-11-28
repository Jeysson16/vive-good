import 'package:equatable/equatable.dart';

class TechAcceptanceIndicators extends Equatable {
  final String userId;
  final String userName;
  final double perceivedUsefulness;
  final double perceivedEaseOfUse;
  final double attitudeTowardUsing;
  final double behavioralIntention;
  final double actualSystemUse;
  final double overallScore;
  final String acceptanceLevel; // 'Alto', 'Medio', 'Bajo'
  final DateTime evaluationDate;
  final Map<String, dynamic>? additionalMetrics;

  const TechAcceptanceIndicators({
    required this.userId,
    required this.userName,
    required this.perceivedUsefulness,
    required this.perceivedEaseOfUse,
    required this.attitudeTowardUsing,
    required this.behavioralIntention,
    required this.actualSystemUse,
    required this.overallScore,
    required this.acceptanceLevel,
    required this.evaluationDate,
    this.additionalMetrics,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        perceivedUsefulness,
        perceivedEaseOfUse,
        attitudeTowardUsing,
        behavioralIntention,
        actualSystemUse,
        overallScore,
        acceptanceLevel,
        evaluationDate,
        additionalMetrics,
      ];

  TechAcceptanceIndicators copyWith({
    String? userId,
    String? userName,
    double? perceivedUsefulness,
    double? perceivedEaseOfUse,
    double? attitudeTowardUsing,
    double? behavioralIntention,
    double? actualSystemUse,
    double? overallScore,
    String? acceptanceLevel,
    DateTime? evaluationDate,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return TechAcceptanceIndicators(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      perceivedUsefulness: perceivedUsefulness ?? this.perceivedUsefulness,
      perceivedEaseOfUse: perceivedEaseOfUse ?? this.perceivedEaseOfUse,
      attitudeTowardUsing: attitudeTowardUsing ?? this.attitudeTowardUsing,
      behavioralIntention: behavioralIntention ?? this.behavioralIntention,
      actualSystemUse: actualSystemUse ?? this.actualSystemUse,
      overallScore: overallScore ?? this.overallScore,
      acceptanceLevel: acceptanceLevel ?? this.acceptanceLevel,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }
}