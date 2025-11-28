import 'package:equatable/equatable.dart';
import 'package:vive_good_app/domain/entities/habit_breakdown.dart';

class HabitBreakdownModel extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final int totalHabits;
  final int completedHabits;
  final double completionPercentage;
  final int totalLogs;
  final int completedLogs;

  const HabitBreakdownModel({
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

  factory HabitBreakdownModel.fromJson(Map<String, dynamic> json) {
    return HabitBreakdownModel(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      categoryColor: json['category_color'] ?? '#4CAF50',
      categoryIcon: json['category_icon'] ?? 'star',
      totalHabits: (json['total_habits'] ?? 0).toInt(),
      completedHabits: (json['completed_habits'] ?? 0).toInt(),
      completionPercentage: (json['completion_percentage'] ?? 0.0).toDouble(),
      totalLogs: (json['total_logs'] ?? 0).toInt(),
      completedLogs: (json['completed_logs'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': (categoryId.isNotEmpty == true) ? categoryId : null,
      'category_name': categoryName,
      'category_color': categoryColor,
      'category_icon': categoryIcon,
      'total_habits': totalHabits,
      'completed_habits': completedHabits,
      'completion_percentage': completionPercentage,
      'total_logs': totalLogs,
      'completed_logs': completedLogs,
    };
  }

  HabitBreakdown toEntity() {
    return HabitBreakdown(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      totalHabits: totalHabits,
      completedHabits: completedHabits,
      completionPercentage: completionPercentage,
      totalLogs: totalLogs,
      completedLogs: completedLogs,
    );
  }

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
    return 'HabitBreakdownModel(categoryId: $categoryId, categoryName: $categoryName, totalHabits: $totalHabits, completedHabits: $completedHabits, completionPercentage: $completionPercentage)';
  }
}