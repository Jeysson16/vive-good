import 'package:equatable/equatable.dart';

class AIAdvice extends Equatable {
  final String id;
  final String userId;
  final String habitName;
  final String? habitCategory;
  final String adviceText;
  final String adviceType; // 'general', 'motivation', 'tips', 'schedule'
  final String source; // 'ai', 'gemini', 'manual'
  final bool isApplied;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIAdvice({
    required this.id,
    required this.userId,
    required this.habitName,
    this.habitCategory,
    required this.adviceText,
    required this.adviceType,
    required this.source,
    required this.isApplied,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  AIAdvice copyWith({
    String? id,
    String? userId,
    String? habitName,
    String? habitCategory,
    String? adviceText,
    String? adviceType,
    String? source,
    bool? isApplied,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIAdvice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitName: habitName ?? this.habitName,
      habitCategory: habitCategory ?? this.habitCategory,
      adviceText: adviceText ?? this.adviceText,
      adviceType: adviceType ?? this.adviceType,
      source: source ?? this.source,
      isApplied: isApplied ?? this.isApplied,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        habitName,
        habitCategory,
        adviceText,
        adviceType,
        source,
        isApplied,
        isFavorite,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'AIAdvice(id: $id, userId: $userId, habitName: $habitName, habitCategory: $habitCategory, adviceText: $adviceText, adviceType: $adviceType, source: $source, isApplied: $isApplied, isFavorite: $isFavorite, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}