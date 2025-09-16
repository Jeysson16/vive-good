import 'package:equatable/equatable.dart';

class HabitBreakdown extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final int totalHabits;
  final int completedHabits;
  final double completionPercentage;
  final int totalLogs;
  final int completedLogs;

  const HabitBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.totalHabits,
    required this.completedHabits,
    required this.completionPercentage,
    required this.totalLogs,
    required this.completedLogs,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryColor,
        categoryIcon,
        totalHabits,
        completedHabits,
        completionPercentage,
        totalLogs,
        completedLogs,
      ];

  @override
  String toString() {
    return 'HabitBreakdown(categoryId: $categoryId, categoryName: $categoryName, totalHabits: $totalHabits, completedHabits: $completedHabits, completionPercentage: $completionPercentage)';
  }
}