import 'package:equatable/equatable.dart';

class HabitSchedule extends Equatable {
  final String id;
  final String userId;
  final String habitId;
  final String scheduledTime; // Format: "HH:mm"
  final DateTime? scheduledDate;
  final String recurrenceType; // 'none', 'daily', 'weekly', 'monthly'
  final List<int>? recurrenceDays; // Days of week (1-7) for weekly recurrence
  final bool isActive;
  final bool notificationEnabled;
  final int? notificationMinutes; // Minutes before scheduled time
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitSchedule({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.scheduledTime,
    this.scheduledDate,
    this.recurrenceType = 'none',
    this.recurrenceDays,
    this.isActive = true,
    this.notificationEnabled = false,
    this.notificationMinutes,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        habitId,
        scheduledTime,
        scheduledDate,
        recurrenceType,
        recurrenceDays,
        isActive,
        notificationEnabled,
        notificationMinutes,
        isCompleted,
        completedAt,
        createdAt,
        updatedAt,
      ];

  HabitSchedule copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? scheduledTime,
    DateTime? scheduledDate,
    String? recurrenceType,
    List<int>? recurrenceDays,
    bool? isActive,
    bool? notificationEnabled,
    int? notificationMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      isActive: isActive ?? this.isActive,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HabitSchedule(id: $id, habitId: $habitId, scheduledTime: $scheduledTime, isActive: $isActive)';
  }
}