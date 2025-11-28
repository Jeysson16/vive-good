import 'package:equatable/equatable.dart';

class KnowledgeSymptomsIndicators extends Equatable {
  final String userId;
  final String userName;
  final double knowledgeScore;
  final int totalSymptoms;
  final int identifiedSymptoms;
  final double identificationRate;
  final List<String> strongAreas;
  final List<String> weakAreas;
  final String knowledgeLevel; // 'Alto', 'Medio', 'Bajo'
  final DateTime evaluationDate;
  final Map<String, dynamic>? detailedScores;

  const KnowledgeSymptomsIndicators({
    required this.userId,
    required this.userName,
    required this.knowledgeScore,
    required this.totalSymptoms,
    required this.identifiedSymptoms,
    required this.identificationRate,
    required this.strongAreas,
    required this.weakAreas,
    required this.knowledgeLevel,
    required this.evaluationDate,
    this.detailedScores,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        knowledgeScore,
        totalSymptoms,
        identifiedSymptoms,
        identificationRate,
        strongAreas,
        weakAreas,
        knowledgeLevel,
        evaluationDate,
        detailedScores,
      ];

  KnowledgeSymptomsIndicators copyWith({
    String? userId,
    String? userName,
    double? knowledgeScore,
    int? totalSymptoms,
    int? identifiedSymptoms,
    double? identificationRate,
    List<String>? strongAreas,
    List<String>? weakAreas,
    String? knowledgeLevel,
    DateTime? evaluationDate,
    Map<String, dynamic>? detailedScores,
  }) {
    return KnowledgeSymptomsIndicators(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      knowledgeScore: knowledgeScore ?? this.knowledgeScore,
      totalSymptoms: totalSymptoms ?? this.totalSymptoms,
      identifiedSymptoms: identifiedSymptoms ?? this.identifiedSymptoms,
      identificationRate: identificationRate ?? this.identificationRate,
      strongAreas: strongAreas ?? this.strongAreas,
      weakAreas: weakAreas ?? this.weakAreas,
      knowledgeLevel: knowledgeLevel ?? this.knowledgeLevel,
      evaluationDate: evaluationDate ?? this.evaluationDate,
      detailedScores: detailedScores ?? this.detailedScores,
    );
  }
}