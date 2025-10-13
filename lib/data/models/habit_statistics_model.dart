import 'package:equatable/equatable.dart';
import 'package:vive_good_app/domain/entities/habit_statistics.dart';

class HabitStatisticsModel extends Equatable {
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
  final double averageCompletionTime;
  final int totalLogsThisMonth;
  final int completedLogsThisMonth;
  final double monthlyEfficiency;

  const HabitStatisticsModel({
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
    required this.averageCompletionTime,
    required this.totalLogsThisMonth,
    required this.completedLogsThisMonth,
    required this.monthlyEfficiency,
  });

  factory HabitStatisticsModel.fromJson(Map<String, dynamic> json) {
    return HabitStatisticsModel(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      categoryColor: json['category_color'] ?? '#4CAF50',
      categoryIcon: json['category_icon'] ?? 'star',
      totalHabits: (json['total_habits'] ?? 0).toInt(),
      completedHabits: (json['completed_habits'] ?? 0).toInt(),
      pendingHabits: (json['pending_habits'] ?? 0).toInt(),
      completionPercentage: (json['completion_percentage'] ?? 0.0).toDouble(),
      currentStreak: (json['current_streak'] ?? 0).toInt(),
      bestStreak: (json['best_streak'] ?? 0).toInt(),
      bestDayOfWeek: json['best_day_of_week'] ?? 'Monday',
      weeklyConsistency: (json['weekly_consistency'] ?? 0.0).toDouble(),
      averageCompletionTime: (json['average_completion_time'] ?? 0.0).toDouble(),
      totalLogsThisMonth: (json['total_logs_this_month'] ?? 0).toInt(),
      completedLogsThisMonth: (json['completed_logs_this_month'] ?? 0).toInt(),
      monthlyEfficiency: (json['monthly_efficiency'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': (categoryId?.isNotEmpty == true) ? categoryId : null,
      'category_name': categoryName,
      'category_color': categoryColor,
      'category_icon': categoryIcon,
      'total_habits': totalHabits,
      'completed_habits': completedHabits,
      'pending_habits': pendingHabits,
      'completion_percentage': completionPercentage,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'best_day_of_week': bestDayOfWeek,
      'weekly_consistency': weeklyConsistency,
      'average_completion_time': averageCompletionTime,
      'total_logs_this_month': totalLogsThisMonth,
      'completed_logs_this_month': completedLogsThisMonth,
      'monthly_efficiency': monthlyEfficiency,
    };
  }

  HabitStatistics toEntity() {
    return HabitStatistics(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      totalHabits: totalHabits,
      completedHabits: completedHabits,
      pendingHabits: pendingHabits,
      completionPercentage: completionPercentage,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      bestDayOfWeek: bestDayOfWeek,
      weeklyConsistency: weeklyConsistency,
      daysThisWeek: 7, // Valor por defecto
      completedDaysThisWeek: (weeklyConsistency * 7).round(),
      averageCompletionTime: averageCompletionTime,
      totalLogs: totalLogsThisMonth,
      completedLogs: completedLogsThisMonth,
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
        pendingHabits,
        completionPercentage,
        currentStreak,
        bestStreak,
        bestDayOfWeek,
        weeklyConsistency,
        averageCompletionTime,
        totalLogsThisMonth,
        completedLogsThisMonth,
        monthlyEfficiency,
      ];

  @override
  String toString() {
    return 'HabitStatisticsModel(categoryId: $categoryId, categoryName: $categoryName, totalHabits: $totalHabits, completionPercentage: $completionPercentage, currentStreak: $currentStreak)';
  }
}