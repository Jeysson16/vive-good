import 'package:vive_good_app/domain/entities/habit.dart';

class UserHabit {
  final String id;
  final String userId;
  final String habitId;
  final String frequency; // daily, weekly, monthly
  final String? scheduledTime;
  final bool notificationsEnabled;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.habitId,
    required this.frequency,
    this.scheduledTime,
    required this.notificationsEnabled,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
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


}
