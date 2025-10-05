import 'package:equatable/equatable.dart';

class AssistantConfig extends Equatable {
  final String userId;
  final bool voiceEnabled;
  final bool animationEnabled;
  final bool deepLearningEnabled;
  final String preferredLanguage;
  final double voiceSpeed;
  final String voiceGender;
  final bool notificationsEnabled;
  final bool contextualSuggestionsEnabled;
  final Map<String, dynamic> personalPreferences;
  final DateTime lastUpdated;

  const AssistantConfig({
    required this.userId,
    this.voiceEnabled = true,
    this.animationEnabled = true,
    this.deepLearningEnabled = true,
    this.preferredLanguage = 'es',
    this.voiceSpeed = 1.0,
    this.voiceGender = 'female',
    this.notificationsEnabled = true,
    this.contextualSuggestionsEnabled = true,
    this.personalPreferences = const {},
    required this.lastUpdated,
  });

  AssistantConfig copyWith({
    String? userId,
    bool? voiceEnabled,
    bool? animationEnabled,
    bool? deepLearningEnabled,
    String? preferredLanguage,
    double? voiceSpeed,
    String? voiceGender,
    bool? notificationsEnabled,
    bool? contextualSuggestionsEnabled,
    Map<String, dynamic>? personalPreferences,
    DateTime? lastUpdated,
  }) {
    return AssistantConfig(
      userId: userId ?? this.userId,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      animationEnabled: animationEnabled ?? this.animationEnabled,
      deepLearningEnabled: deepLearningEnabled ?? this.deepLearningEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      voiceGender: voiceGender ?? this.voiceGender,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      contextualSuggestionsEnabled: contextualSuggestionsEnabled ?? this.contextualSuggestionsEnabled,
      personalPreferences: personalPreferences ?? this.personalPreferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'voice_enabled': voiceEnabled,
      'animation_enabled': animationEnabled,
      'deep_learning_enabled': deepLearningEnabled,
      'preferred_language': preferredLanguage,
      'voice_speed': voiceSpeed,
      'voice_gender': voiceGender,
      'notifications_enabled': notificationsEnabled,
      'contextual_suggestions_enabled': contextualSuggestionsEnabled,
      'personal_preferences': personalPreferences,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory AssistantConfig.fromJson(Map<String, dynamic> json) {
    return AssistantConfig(
      userId: json['user_id'] as String,
      voiceEnabled: json['voice_enabled'] as bool? ?? true,
      animationEnabled: json['animation_enabled'] as bool? ?? true,
      deepLearningEnabled: json['deep_learning_enabled'] as bool? ?? true,
      preferredLanguage: json['preferred_language'] as String? ?? 'es',
      voiceSpeed: (json['voice_speed'] as num?)?.toDouble() ?? 1.0,
      voiceGender: json['voice_gender'] as String? ?? 'female',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      contextualSuggestionsEnabled: json['contextual_suggestions_enabled'] as bool? ?? true,
      personalPreferences: json['personal_preferences'] as Map<String, dynamic>? ?? {},
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  factory AssistantConfig.defaultConfig(String userId) {
    return AssistantConfig(
      userId: userId,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        voiceEnabled,
        animationEnabled,
        deepLearningEnabled,
        preferredLanguage,
        voiceSpeed,
        voiceGender,
        notificationsEnabled,
        contextualSuggestionsEnabled,
        personalPreferences,
        lastUpdated,
      ];
}