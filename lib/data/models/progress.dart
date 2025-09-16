import '../../domain/entities/progress.dart' as entity;

class ProgressModel extends entity.Progress {
  const ProgressModel({
    required super.userId,
    required super.userName,
    required super.userProfileImage,
    required super.weeklyCompletedHabits,
    required super.suggestedHabits,
    required super.pendingActivities,
    required super.newHabits,
    required super.weeklyProgressPercentage,
    required super.acceptedNutritionSuggestions,
    required super.motivationalMessage,
    required super.lastUpdated,
    super.dailyProgress,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userProfileImage: json['user_profile_image'] ?? '',
      weeklyCompletedHabits: json['weekly_completed_habits'] ?? 0,
      suggestedHabits: json['suggested_habits'] ?? 0,
      pendingActivities: json['pending_activities'] ?? 0,
      newHabits: json['new_habits'] ?? 0,
      weeklyProgressPercentage: (json['weekly_progress_percentage'] ?? 0.0).toDouble(),
      acceptedNutritionSuggestions: json['accepted_nutrition_suggestions'] ?? 0,
      motivationalMessage: json['motivational_message'] ?? '',
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
      dailyProgress: json['daily_progress'] != null 
          ? List<double>.from(json['daily_progress'].map((x) => x.toDouble()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_profile_image': userProfileImage,
      'weekly_completed_habits': weeklyCompletedHabits,
      'suggested_habits': suggestedHabits,
      'pending_activities': pendingActivities,
      'new_habits': newHabits,
      'weekly_progress_percentage': weeklyProgressPercentage,
      'accepted_nutrition_suggestions': acceptedNutritionSuggestions,
      'motivational_message': motivationalMessage,
      'last_updated': lastUpdated.toIso8601String(),
      'daily_progress': dailyProgress,
    };
  }

  factory ProgressModel.fromEntity(entity.Progress progress) {
    return ProgressModel(
      userId: progress.userId,
      userName: progress.userName,
      userProfileImage: progress.userProfileImage,
      weeklyCompletedHabits: progress.weeklyCompletedHabits,
      suggestedHabits: progress.suggestedHabits,
      pendingActivities: progress.pendingActivities,
      newHabits: progress.newHabits,
      weeklyProgressPercentage: progress.weeklyProgressPercentage,
      acceptedNutritionSuggestions: progress.acceptedNutritionSuggestions,
      motivationalMessage: progress.motivationalMessage,
      lastUpdated: progress.lastUpdated,
      dailyProgress: progress.dailyProgress,
    );
  }

  entity.Progress toEntity() {
    return entity.Progress(
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      weeklyCompletedHabits: weeklyCompletedHabits,
      suggestedHabits: suggestedHabits,
      pendingActivities: pendingActivities,
      newHabits: newHabits,
      weeklyProgressPercentage: weeklyProgressPercentage,
      acceptedNutritionSuggestions: acceptedNutritionSuggestions,
      motivationalMessage: motivationalMessage,
      lastUpdated: lastUpdated,
      dailyProgress: dailyProgress,
    );
  }

  @override
  ProgressModel copyWith({
    String? userId,
    String? userName,
    String? userProfileImage,
    int? weeklyCompletedHabits,
    int? suggestedHabits,
    int? pendingActivities,
    int? newHabits,
    double? weeklyProgressPercentage,
    int? acceptedNutritionSuggestions,
    String? motivationalMessage,
    DateTime? lastUpdated,
    List<double>? dailyProgress,
  }) {
    return ProgressModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      weeklyCompletedHabits: weeklyCompletedHabits ?? this.weeklyCompletedHabits,
      suggestedHabits: suggestedHabits ?? this.suggestedHabits,
      pendingActivities: pendingActivities ?? this.pendingActivities,
      newHabits: newHabits ?? this.newHabits,
      weeklyProgressPercentage: weeklyProgressPercentage ?? this.weeklyProgressPercentage,
      acceptedNutritionSuggestions: acceptedNutritionSuggestions ?? this.acceptedNutritionSuggestions,
      motivationalMessage: motivationalMessage ?? this.motivationalMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dailyProgress: dailyProgress ?? this.dailyProgress,
    );
  }
}