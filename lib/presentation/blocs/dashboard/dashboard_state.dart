import 'package:equatable/equatable.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../../domain/entities/user_habit.dart';
import '../habit/habit_state.dart';

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<UserHabit> userHabits;
  final List<UserHabit> filteredHabits;
  final List<Habit> habits;
  final List<Category> categories;
  final Map<String, List<HabitLog>> habitLogs;
  final int pendingCount;
  final int completedCount;
  final String? selectedCategoryId;
  final String? animatedHabitId;
  final AnimationState animationState;

  const DashboardLoaded({
    required this.userHabits,
    required this.filteredHabits,
    required this.habits,
    required this.categories,
    required this.habitLogs,
    required this.pendingCount,
    required this.completedCount,
    this.selectedCategoryId,
    this.animatedHabitId,
    this.animationState = AnimationState.idle,
  });

  @override
  List<Object?> get props => [
    userHabits,
    filteredHabits,
    habits,
    categories,
    habitLogs,
    pendingCount,
    completedCount,
    selectedCategoryId,
    animatedHabitId,
    animationState,
  ];

  DashboardLoaded copyWith({
    List<UserHabit>? userHabits,
    List<UserHabit>? filteredHabits,
    List<Habit>? habits,
    List<Category>? categories,
    Map<String, List<HabitLog>>? habitLogs,
    int? pendingCount,
    int? completedCount,
    String? selectedCategoryId,
    String? animatedHabitId,
    AnimationState? animationState,
    bool clearCategoryFilter = false,
  }) {
    return DashboardLoaded(
      userHabits: userHabits ?? this.userHabits,
      filteredHabits: filteredHabits ?? this.filteredHabits,
      habits: habits ?? this.habits,
      categories: categories ?? this.categories,
      habitLogs: habitLogs ?? this.habitLogs,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      selectedCategoryId: clearCategoryFilter
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      animatedHabitId: animatedHabitId ?? this.animatedHabitId,
      animationState: animationState ?? this.animationState,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class DashboardSyncError extends DashboardState {
  final String message;
  final bool shouldAutoRefresh;

  const DashboardSyncError(this.message, {this.shouldAutoRefresh = true});

  @override
  List<Object?> get props => [message, shouldAutoRefresh];
}
