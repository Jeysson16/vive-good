import 'package:vive_good_app/domain/entities/user_habit.dart' as entities;
import 'package:vive_good_app/domain/entities/habit.dart';

class UserHabitModel {
  final String id;
  final String userId;
  final String? habitId;
  final String frequency;
  final Map<String, dynamic>? frequencyDetails;
  final String? scheduledTime;
  final bool notificationsEnabled;
  final String? notificationTime;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isPublic;
  final int? estimatedDuration;
  final String? difficultyLevel;
  final String? customName;
  final String? customDescription;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompletedToday;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;

  const UserHabitModel({
    required this.id,
    required this.userId,
    this.habitId,
    required this.frequency,
    this.frequencyDetails,
    this.scheduledTime,
    required this.notificationsEnabled,
    this.notificationTime,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.isPublic,
    this.estimatedDuration,
    this.difficultyLevel,
    this.customName,
    this.customDescription,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.isCompletedToday,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
  });

  factory UserHabitModel.fromJson(Map<String, dynamic> json) {
    return UserHabitModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitId: json['habit_id'] as String?,
      frequency: json['frequency'] as String,
      frequencyDetails: json['frequency_details'] as Map<String, dynamic>?,
      scheduledTime: json['scheduled_time'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool,
      notificationTime: json['notification_time'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isActive: json['is_active'] as bool,
      isPublic: json['is_public'] as bool,
      estimatedDuration: json['estimated_duration'] as int?,
      difficultyLevel: json['difficulty_level'] as String?,
      customName: json['custom_name'] as String?,
      customDescription: json['custom_description'] as String?,
      categoryId: json['category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isCompletedToday: json['is_completed_today'] as bool? ?? false,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      totalCompletions: json['total_completions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': (userId.isNotEmpty) ? userId : null,
      'habit_id': (habitId?.isNotEmpty == true) ? habitId : null,
      'frequency': frequency,
      'frequency_details': frequencyDetails,
      'scheduled_time': scheduledTime,
      'notifications_enabled': notificationsEnabled,
      'notification_time': notificationTime,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'is_public': isPublic,
      'estimated_duration': estimatedDuration,
      'difficulty_level': difficultyLevel,
      'custom_name': customName,
      'custom_description': customDescription,
      'category_id': (categoryId?.isNotEmpty == true) ? categoryId : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_completed_today': isCompletedToday,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_completions': totalCompletions,
    };
  }

  entities.UserHabit toEntity() {
    return entities.UserHabit(
      id: id,
      userId: userId,
      habitId: habitId ?? '',
      frequency: frequency,
      frequencyDetails: frequencyDetails,
      scheduledTime: scheduledTime,
      notificationsEnabled: notificationsEnabled,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCompletedToday: isCompletedToday,
      completionCountToday: 0, // UserHabitModel doesn't have this field
      lastCompletedAt: null, // UserHabitModel doesn't have this field
      streakCount: currentStreak, // Map currentStreak to streakCount
      totalCompletions: totalCompletions,
      habit: null, // UserHabitModel doesn't have this field
    );
  }

  factory UserHabitModel.fromEntity(entities.UserHabit entity) {
    return UserHabitModel(
      id: entity.id,
      userId: entity.userId,
      habitId: entity.habitId,
      frequency: entity.frequency,
      scheduledTime: entity.scheduledTime,
      notificationsEnabled: entity.notificationsEnabled,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isCompletedToday: entity.isCompletedToday,
      currentStreak: entity.streakCount, // Map streakCount to currentStreak
      longestStreak: 0, // Default value since entity doesn't have this
      totalCompletions: entity.totalCompletions,
      isPublic: false, // Default value since entity doesn't have this
    );
  }

  UserHabitModel copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? frequency,
    Map<String, dynamic>? frequencyDetails,
    String? scheduledTime,
    bool? notificationsEnabled,
    String? notificationTime,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isPublic,
    int? estimatedDuration,
    String? difficultyLevel,
    String? customName,
    String? customDescription,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompletedToday,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
  }) {
    return UserHabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      frequency: frequency ?? this.frequency,
      frequencyDetails: frequencyDetails ?? this.frequencyDetails,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      customName: customName ?? this.customName,
      customDescription: customDescription ?? this.customDescription,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserHabitModel &&
        other.id == id &&
        other.userId == userId &&
        other.habitId == habitId &&
        other.frequency == frequency &&
        other.scheduledTime == scheduledTime &&
        other.notificationsEnabled == notificationsEnabled &&
        other.notificationTime == notificationTime &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.isPublic == isPublic &&
        other.estimatedDuration == estimatedDuration &&
        other.difficultyLevel == difficultyLevel &&
        other.customName == customName &&
        other.customDescription == customDescription &&
        other.categoryId == categoryId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isCompletedToday == isCompletedToday &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.totalCompletions == totalCompletions;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      userId,
      habitId,
      frequency,
      scheduledTime,
      notificationsEnabled,
      notificationTime,
      startDate,
      endDate,
      isActive,
      isPublic,
      estimatedDuration,
      difficultyLevel,
      customName,
      customDescription,
      categoryId,
      createdAt,
      updatedAt,
      isCompletedToday,
      currentStreak,
      longestStreak,
      totalCompletions,
    ]);
  }

  @override
  String toString() {
    return 'UserHabitModel(id: $id, userId: $userId, habitId: $habitId, frequency: $frequency, scheduledTime: $scheduledTime, isCompletedToday: $isCompletedToday, currentStreak: $currentStreak)';
  }
}