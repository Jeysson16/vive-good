import 'package:equatable/equatable.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final String userId;
  final DateTime date;

  const LoadDashboardData({required this.userId, required this.date});

  @override
  List<Object?> get props => [userId, date];
}

class ToggleDashboardHabitCompletion extends DashboardEvent {
  final String habitId;
  final DateTime date;
  final bool isCompleted;

  const ToggleDashboardHabitCompletion({
    required this.habitId,
    required this.date,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [habitId, date, isCompleted];
}

class ToggleDashboardHabitsCompletionBulk extends DashboardEvent {
  final List<String> habitIds;
  final DateTime date;
  final bool isCompleted;

  const ToggleDashboardHabitsCompletionBulk({
    required this.habitIds,
    required this.date,
    this.isCompleted = true,
  });

  @override
  List<Object?> get props => [habitIds, date, isCompleted];
}

class FilterDashboardByCategory extends DashboardEvent {
  final String? categoryId;

  const FilterDashboardByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class RefreshDashboardData extends DashboardEvent {
  final String userId;
  final DateTime date;

  const RefreshDashboardData({required this.userId, required this.date});

  @override
  List<Object?> get props => [userId, date];
}
