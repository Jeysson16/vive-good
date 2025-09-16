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

  const FilterHabitsByCategory(this.categoryId);

  @override
  List<Object> get props => [categoryId].whereType<Object>().toList();
}

class LoadHabitSuggestions extends HabitEvent {
  final String? categoryId;
  final String userId;

  const LoadHabitSuggestions({this.categoryId, required this.userId});

  @override
  List<Object> get props => [categoryId, userId].whereType<Object>().toList();
}

class LoadDashboardHabits extends HabitEvent {
  final String userId;
  final DateTime date;

  const LoadDashboardHabits({
    required this.userId,
    required this.date,
  });

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