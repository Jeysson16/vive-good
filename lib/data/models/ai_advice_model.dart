import '../../domain/entities/ai_advice.dart';

class AIAdviceModel extends AIAdvice {
  const AIAdviceModel({
    required super.id,
    required super.userId,
    required super.habitName,
    super.habitCategory,
    required super.adviceText,
    required super.adviceType,
    required super.source,
    required super.isApplied,
    required super.isFavorite,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AIAdviceModel.fromJson(Map<String, dynamic> json) {
    return AIAdviceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitName: json['habit_name'] as String,
      habitCategory: json['habit_category'] as String?,
      adviceText: json['advice_text'] as String,
      adviceType: json['advice_type'] as String? ?? 'general',
      source: json['source'] as String? ?? 'ai',
      isApplied: json['is_applied'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_name': habitName,
      'habit_category': habitCategory,
      'advice_text': adviceText,
      'advice_type': adviceType,
      'source': source,
      'is_applied': isApplied,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AIAdviceModel.fromEntity(AIAdvice advice) {
    return AIAdviceModel(
      id: advice.id,
      userId: advice.userId,
      habitName: advice.habitName,
      habitCategory: advice.habitCategory,
      adviceText: advice.adviceText,
      adviceType: advice.adviceType,
      source: advice.source,
      isApplied: advice.isApplied,
      isFavorite: advice.isFavorite,
      createdAt: advice.createdAt,
      updatedAt: advice.updatedAt,
    );
  }

  AIAdvice toEntity() {
    return AIAdvice(
      id: id,
      userId: userId,
      habitName: habitName,
      habitCategory: habitCategory,
      adviceText: adviceText,
      adviceType: adviceType,
      source: source,
      isApplied: isApplied,
      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  AIAdviceModel copyWith({
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
    return AIAdviceModel(
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
}