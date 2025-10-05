import '../../domain/entities/user_habit.dart';
import 'package:vive_good_app/data/models/habit_model.dart';

class UserHabitModel extends UserHabit {
  final HabitModel? habit;

  const UserHabitModel({
    required super.id,
    required super.userId,
    super.habitId,
    required super.frequency,
    super.frequencyDetails,
    super.scheduledTime,
    required super.notificationsEnabled,
    required super.startDate,
    super.endDate,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.customName,
    super.customDescription,
    super.isCompletedToday,
    super.completionCountToday,
    super.lastCompletedAt,
    super.streakCount,
    super.totalCompletions,
    this.habit,
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
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customName: json['custom_name'] as String?,
      customDescription: json['custom_description'] as String?,
      isCompletedToday: json['is_completed_today'] as bool? ?? false,
      completionCountToday: json['completion_count_today'] as int? ?? 0,
      lastCompletedAt: json['last_completed_at'] != null ? DateTime.parse(json['last_completed_at'] as String) : null,
      streakCount: json['streak_count'] as int? ?? 0,
      totalCompletions: json['total_completions'] as int? ?? 0,
      habit: json['habits'] != null ? HabitModel.fromJson(json['habits'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'frequency': frequency,
      'frequency_details': frequencyDetails,
      'scheduled_time': scheduledTime,
      'notifications_enabled': notificationsEnabled,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserHabitModel.fromEntity(UserHabit userHabit) {
    return UserHabitModel(
      id: userHabit.id,
      userId: userHabit.userId,
      habitId: userHabit.habitId,
      frequency: userHabit.frequency,
      frequencyDetails: userHabit.frequencyDetails,
      scheduledTime: userHabit.scheduledTime,
      notificationsEnabled: userHabit.notificationsEnabled,
      startDate: userHabit.startDate,
      endDate: userHabit.endDate,
      isActive: userHabit.isActive,
      createdAt: userHabit.createdAt,
      updatedAt: userHabit.updatedAt,
      customName: userHabit.customName,
      customDescription: userHabit.customDescription,
      isCompletedToday: userHabit.isCompletedToday,
      completionCountToday: userHabit.completionCountToday,
      lastCompletedAt: userHabit.lastCompletedAt,
      streakCount: userHabit.streakCount,
      totalCompletions: userHabit.totalCompletions,
      habit: userHabit.habit as HabitModel?,
    );
  }

  UserHabit toEntity() {
    return UserHabit(
      id: id,
      userId: userId,
      habitId: habitId,
      frequency: frequency,
      frequencyDetails: frequencyDetails,
      scheduledTime: scheduledTime,
      notificationsEnabled: notificationsEnabled,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customName: customName,
      customDescription: customDescription,
      isCompletedToday: isCompletedToday,
      completionCountToday: completionCountToday,
      lastCompletedAt: lastCompletedAt,
      streakCount: streakCount,
      totalCompletions: totalCompletions,
      habit: habit?.toEntity(),
    );
  }
}