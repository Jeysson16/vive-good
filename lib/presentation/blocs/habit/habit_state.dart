import 'package:equatable/equatable.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../../domain/entities/user_habit.dart';

enum AnimationState {
  idle,
  loading,
  success,
  error,
  habitToggled,
  categoryChanged,
}

enum HabitItemAnimation { slideIn, fadeIn, scaleIn, none }

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

class HabitInitial extends HabitState {
  const HabitInitial();
}

class HabitLoading extends HabitState {
  const HabitLoading();
}

class HabitLoaded extends HabitState {
  final List<UserHabit> userHabits;
  final List<Category> categories;
  final List<Habit> habits;
  final Map<String, List<HabitLog>> habitLogs;
  final String? selectedCategoryId;
  final int pendingCount;
  final int completedCount;
  final List<Habit> habitSuggestions;
  final AnimationState animationState;
  final HabitItemAnimation itemAnimation;
  final String? animatedHabitId;
  final bool shouldAnimateList;

  const HabitLoaded({
    required this.userHabits,
    required this.categories,
    required this.habits,
    required this.habitLogs,
    this.selectedCategoryId,
    required this.pendingCount,
    required this.completedCount,
    this.habitSuggestions = const [],
    this.animationState = AnimationState.idle,
    this.itemAnimation = HabitItemAnimation.none,
    this.animatedHabitId,
    this.shouldAnimateList = false,
  });

  @override
  List<Object?> get props => [
    userHabits,
    categories,
    habits,
    habitLogs,
    selectedCategoryId,
    pendingCount,
    completedCount,
    habitSuggestions,
    animationState,
    itemAnimation,
    animatedHabitId,
    shouldAnimateList,
  ];

  HabitLoaded copyWith({
    List<UserHabit>? userHabits,
    List<Category>? categories,
    List<Habit>? habits,
    Map<String, List<HabitLog>>? habitLogs,
    String? selectedCategoryId,
    bool resetSelectedCategory = false,
    int? pendingCount,
    int? completedCount,
    List<Habit>? habitSuggestions,
    AnimationState? animationState,
    HabitItemAnimation? itemAnimation,
    String? animatedHabitId,
    bool? shouldAnimateList,
  }) {
    return HabitLoaded(
      userHabits: userHabits ?? this.userHabits,
      categories: categories ?? this.categories,
      habits: habits ?? this.habits,
      habitLogs: habitLogs ?? this.habitLogs,
      selectedCategoryId: resetSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      habitSuggestions: habitSuggestions ?? this.habitSuggestions,
      animationState: animationState ?? this.animationState,
      itemAnimation: itemAnimation ?? this.itemAnimation,
      animatedHabitId: animatedHabitId ?? this.animatedHabitId,
      shouldAnimateList: shouldAnimateList ?? this.shouldAnimateList,
    );
  }

  List<UserHabit> get filteredHabits {
    if (selectedCategoryId == null) return userHabits;
    return userHabits.where((userHabit) {
      final habit = habits.firstWhere((h) => h.id == userHabit.habitId);
      return habit.categoryId == selectedCategoryId;
    }).toList();
  }

  // Get all categories to ensure tabs are always visible
  List<Category> get filteredCategories {
    // Mostrar solo categorías que tienen al menos un hábito del usuario
    final categoryIdsWithHabits = userHabits.map((uh) {
      final habit = habits.firstWhere((h) => h.id == uh.habitId);
      return habit.categoryId;
    }).toSet();

    return categories.where((cat) => categoryIdsWithHabits.contains(cat.id)).toList();
  }
}

class HabitError extends HabitState {
  final String message;

  const HabitError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserHabitDetailLoading extends HabitState {
  const UserHabitDetailLoading();
}

class UserHabitDetailLoaded extends HabitState {
  final UserHabit userHabit;

  const UserHabitDetailLoaded(this.userHabit);

  @override
  List<Object?> get props => [userHabit];
}

class UserHabitUpdating extends HabitState {
  const UserHabitUpdating();
}

class UserHabitUpdated extends HabitState {
  const UserHabitUpdated();
}

class UserHabitDeleting extends HabitState {
  const UserHabitDeleting();
}

class UserHabitDeleted extends HabitState {
  const UserHabitDeleted();
}
