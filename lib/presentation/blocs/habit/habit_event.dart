import 'package:equatable/equatable.dart';
import '../../../domain/entities/habit.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object> get props => [];
}

class LoadUserHabits extends HabitEvent {
  final String userId;

  const LoadUserHabits({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadCategories extends HabitEvent {}

class ToggleHabitCompletion extends HabitEvent {
  final String habitId;
  final DateTime date;
  final bool isCompleted;

  const ToggleHabitCompletion({
    required this.habitId,
    required this.date,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [habitId, date, isCompleted];
}

class FilterHabitsByCategory extends HabitEvent {
  final String? categoryId;
  final bool shouldScrollToFirst;

  const FilterHabitsByCategory(this.categoryId, {this.shouldScrollToFirst = false});

  @override
  List<Object> get props => [categoryId, shouldScrollToFirst].whereType<Object>().toList();
}

class FilterHabitsAdvanced extends HabitEvent {
  final String? categoryId;
  final String? frequency;
  final String? completionStatus;
  final int? minStreakCount;
  final String? scheduledTime;
  final bool shouldScrollToFirst;

  const FilterHabitsAdvanced({
    this.categoryId,
    this.frequency,
    this.completionStatus,
    this.minStreakCount,
    this.scheduledTime,
    this.shouldScrollToFirst = false,
  });

  @override
  List<Object> get props => [
    categoryId,
    frequency,
    completionStatus,
    minStreakCount,
    scheduledTime,
    shouldScrollToFirst,
  ].whereType<Object>().toList();
}

class ScrollToFirstHabitOfCategory extends HabitEvent {
  final String categoryId;

  const ScrollToFirstHabitOfCategory(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class LoadHabitSuggestions extends HabitEvent {
  final String? categoryId;
  final String userId;
  final int? limit;

  const LoadHabitSuggestions({
    this.categoryId,
    required this.userId,
    this.limit,
  });

  @override
  List<Object> get props =>
      [categoryId, userId, limit].whereType<Object>().toList();
}

class LoadDashboardHabits extends HabitEvent {
  final String userId;
  final DateTime date;

  const LoadDashboardHabits({required this.userId, required this.date});

  @override
  List<Object> get props => [userId, date];
}

class AddHabit extends HabitEvent {
  final Habit habit;

  const AddHabit(this.habit);

  @override
  List<Object> get props => [habit];
}

class DeleteHabit extends HabitEvent {
  final String habitId;

  const DeleteHabit(this.habitId);

  @override
  List<Object> get props => [habitId];
}

class LoadUserHabitById extends HabitEvent {
  final String userHabitId;

  const LoadUserHabitById(this.userHabitId);

  @override
  List<Object> get props => [userHabitId];
}

class UpdateUserHabit extends HabitEvent {
  final String userHabitId;
  final Map<String, dynamic> updates;

  const UpdateUserHabit({
    required this.userHabitId,
    required this.updates,
  });

  @override
  List<Object> get props => [userHabitId, updates];
}

class DeleteUserHabit extends HabitEvent {
  final String userHabitId;

  const DeleteUserHabit(this.userHabitId);

  @override
  List<Object> get props => [userHabitId];
}

// ===== NOTIFICATION EVENTS =====

class SetupHabitNotifications extends HabitEvent {
  final String userHabitId;
  final List<int> daysOfWeek;
  final DateTime reminderTime;

  const SetupHabitNotifications({
    required this.userHabitId,
    required this.daysOfWeek,
    required this.reminderTime,
  });

  @override
  List<Object> get props => [userHabitId, daysOfWeek, reminderTime];
}

class ToggleHabitNotifications extends HabitEvent {
  final String userHabitId;
  final bool enabled;

  const ToggleHabitNotifications({
    required this.userHabitId,
    required this.enabled,
  });

  @override
  List<Object> get props => [userHabitId, enabled];
}

class UpdateHabitNotificationTime extends HabitEvent {
  final String userHabitId;
  final DateTime newTime;

  const UpdateHabitNotificationTime({
    required this.userHabitId,
    required this.newTime,
  });

  @override
  List<Object> get props => [userHabitId, newTime];
}

class RemoveHabitNotifications extends HabitEvent {
  final String userHabitId;

  const RemoveHabitNotifications(this.userHabitId);

  @override
  List<Object> get props => [userHabitId];
}
