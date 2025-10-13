import 'package:equatable/equatable.dart';

/// Entidad para estadísticas detalladas de hábitos por categoría
/// Siguiendo Clean Architecture - Domain Layer
class HabitStatistics extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final int totalHabits;
  final int completedHabits;
  final int pendingHabits;
  final double completionPercentage;
  final int currentStreak;
  final int bestStreak;
  final String bestDayOfWeek;
  final double weeklyConsistency;
  final int daysThisWeek;
  final int completedDaysThisWeek;
  final double averageCompletionTime;
  final int totalLogs;
  final int completedLogs;

  const HabitStatistics({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.totalHabits,
    required this.completedHabits,
    required this.pendingHabits,
    required this.completionPercentage,
    required this.currentStreak,
    required this.bestStreak,
    required this.bestDayOfWeek,
    required this.weeklyConsistency,
    required this.daysThisWeek,
    required this.completedDaysThisWeek,
    required this.averageCompletionTime,
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
        pendingHabits,
        completionPercentage,
        currentStreak,
        bestStreak,
        bestDayOfWeek,
        weeklyConsistency,
        daysThisWeek,
        completedDaysThisWeek,
        averageCompletionTime,
        totalLogs,
        completedLogs,
      ];

  HabitStatistics copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    int? totalHabits,
    int? completedHabits,
    int? pendingHabits,
    double? completionPercentage,
    int? currentStreak,
    int? bestStreak,
    String? bestDayOfWeek,
    double? weeklyConsistency,
    int? daysThisWeek,
    int? completedDaysThisWeek,
    double? averageCompletionTime,
    int? totalLogs,
    int? completedLogs,
  }) {
    return HabitStatistics(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      totalHabits: totalHabits ?? this.totalHabits,
      completedHabits: completedHabits ?? this.completedHabits,
      pendingHabits: pendingHabits ?? this.pendingHabits,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestDayOfWeek: bestDayOfWeek ?? this.bestDayOfWeek,
      weeklyConsistency: weeklyConsistency ?? this.weeklyConsistency,
      daysThisWeek: daysThisWeek ?? this.daysThisWeek,
      completedDaysThisWeek: completedDaysThisWeek ?? this.completedDaysThisWeek,
      averageCompletionTime: averageCompletionTime ?? this.averageCompletionTime,
      totalLogs: totalLogs ?? this.totalLogs,
      completedLogs: completedLogs ?? this.completedLogs,
    );
  }

  @override
  String toString() {
    return 'HabitStatistics(categoryId: $categoryId, categoryName: $categoryName, totalHabits: $totalHabits, completedHabits: $completedHabits, currentStreak: $currentStreak, weeklyConsistency: $weeklyConsistency)';
  }
}