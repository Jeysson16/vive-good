import 'package:equatable/equatable.dart';

class Progress extends Equatable {
  final String userId;
  final String userName;
  final String userProfileImage;
  final int weeklyCompletedHabits;
  final int suggestedHabits;
  final int pendingActivities;
  final int newHabits;
  final double weeklyProgressPercentage;
  final int acceptedNutritionSuggestions;
  final String motivationalMessage;
  final DateTime lastUpdated;
  final List<double>? dailyProgress;

  const Progress({
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.weeklyCompletedHabits,
    required this.suggestedHabits,
    required this.pendingActivities,
    required this.newHabits,
    required this.weeklyProgressPercentage,
    required this.acceptedNutritionSuggestions,
    required this.motivationalMessage,
    required this.lastUpdated,
    this.dailyProgress,
  });

  Progress copyWith({
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
    return Progress(
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

  @override
  List<Object?> get props => [
        userId,
        userName,
        userProfileImage,
        weeklyCompletedHabits,
        suggestedHabits,
        pendingActivities,
        newHabits,
        weeklyProgressPercentage,
        acceptedNutritionSuggestions,
        motivationalMessage,
        lastUpdated,
        dailyProgress,
      ];

  @override
  String toString() {
    return 'Progress(userId: $userId, userName: $userName, userProfileImage: $userProfileImage, weeklyCompletedHabits: $weeklyCompletedHabits, suggestedHabits: $suggestedHabits, pendingActivities: $pendingActivities, newHabits: $newHabits, weeklyProgressPercentage: $weeklyProgressPercentage, acceptedNutritionSuggestions: $acceptedNutritionSuggestions, motivationalMessage: $motivationalMessage, lastUpdated: $lastUpdated, dailyProgress: $dailyProgress)';
  }
}