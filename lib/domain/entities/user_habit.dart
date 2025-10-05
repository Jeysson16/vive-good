import 'package:vive_good_app/domain/entities/habit.dart';

class UserHabit {
  final String id;
  final String userId;
  final String? habitId; // Can be null for custom habits
  final String frequency; // daily, weekly, monthly
  final Map<String, dynamic>? frequencyDetails; // Contains days_of_week for weekly habits
  final String? scheduledTime;
  final bool notificationsEnabled;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? customName; // For custom habits when habitId is null
  final String? customDescription; // For custom habits when habitId is null

  // Dashboard specific fields from stored procedure
  final bool isCompletedToday;
  final int completionCountToday;
  final DateTime? lastCompletedAt;
  final int streakCount;
  final int totalCompletions;
  final Habit? habit;

  const UserHabit({
    required this.id,
    required this.userId,
    this.habitId, // Can be null for custom habits
    required this.frequency,
    this.frequencyDetails,
    this.scheduledTime,
    required this.notificationsEnabled,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.customName,
    this.customDescription,
    this.isCompletedToday = false,
    this.completionCountToday = 0,
    this.lastCompletedAt,
    this.streakCount = 0,
    this.totalCompletions = 0,
    this.habit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserHabit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory UserHabit.fromHabit(Habit habit) {
    return UserHabit(
      id: '',
      userId: '',
      habitId: habit.id,
      frequency: '',
      scheduledTime: '',
      notificationsEnabled: false,
      startDate: DateTime.now(),
      endDate: null,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCompletedToday: false,
      completionCountToday: 0,
      lastCompletedAt: null,
      streakCount: 0,
      totalCompletions: 0,
      habit: habit,
    );
  }

  UserHabit copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? frequency,
    Map<String, dynamic>? frequencyDetails,
    String? scheduledTime,
    bool? notificationsEnabled,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customName,
    String? customDescription,
    bool? isCompletedToday,
    int? completionCountToday,
    DateTime? lastCompletedAt,
    int? streakCount,
    int? totalCompletions,
    Habit? habit,
  }) {
    return UserHabit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      frequency: frequency ?? this.frequency,
      frequencyDetails: frequencyDetails ?? this.frequencyDetails,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customName: customName ?? this.customName,
      customDescription: customDescription ?? this.customDescription,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      completionCountToday: completionCountToday ?? this.completionCountToday,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      streakCount: streakCount ?? this.streakCount,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      habit: habit ?? this.habit,
    );
  }
}
