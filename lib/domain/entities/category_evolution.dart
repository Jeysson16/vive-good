import 'package:equatable/equatable.dart';

/// Entidad para análisis temporal de evolución por categoría
/// Siguiendo Clean Architecture - Domain Layer
class CategoryEvolution extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final List<DailyProgress> dailyProgress;
  final double monthlyAverage;
  final double previousMonthAverage;
  final double monthlyTrend; // Positivo = mejorando, Negativo = empeorando
  final String trendDirection; // 'improving', 'stable', 'declining'
  final double predictedEndOfMonth;
  final List<String> bestDaysOfWeek;
  final List<String> worstDaysOfWeek;
  final int totalDaysInMonth;
  final int completedDays;
  final int consistentDays;
  final double improvementRate;

  const CategoryEvolution({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.dailyProgress,
    required this.monthlyAverage,
    required this.previousMonthAverage,
    required this.monthlyTrend,
    required this.trendDirection,
    required this.predictedEndOfMonth,
    required this.bestDaysOfWeek,
    required this.worstDaysOfWeek,
    required this.totalDaysInMonth,
    required this.completedDays,
    required this.consistentDays,
    required this.improvementRate,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryColor,
        categoryIcon,
        dailyProgress,
        monthlyAverage,
        previousMonthAverage,
        monthlyTrend,
        trendDirection,
        predictedEndOfMonth,
        bestDaysOfWeek,
        worstDaysOfWeek,
        totalDaysInMonth,
        completedDays,
        consistentDays,
        improvementRate,
      ];

  CategoryEvolution copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    List<DailyProgress>? dailyProgress,
    double? monthlyAverage,
    double? previousMonthAverage,
    double? monthlyTrend,
    String? trendDirection,
    double? predictedEndOfMonth,
    List<String>? bestDaysOfWeek,
    List<String>? worstDaysOfWeek,
    int? totalDaysInMonth,
    int? completedDays,
    int? consistentDays,
    double? improvementRate,
  }) {
    return CategoryEvolution(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      monthlyAverage: monthlyAverage ?? this.monthlyAverage,
      previousMonthAverage: previousMonthAverage ?? this.previousMonthAverage,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      trendDirection: trendDirection ?? this.trendDirection,
      predictedEndOfMonth: predictedEndOfMonth ?? this.predictedEndOfMonth,
      bestDaysOfWeek: bestDaysOfWeek ?? this.bestDaysOfWeek,
      worstDaysOfWeek: worstDaysOfWeek ?? this.worstDaysOfWeek,
      totalDaysInMonth: totalDaysInMonth ?? this.totalDaysInMonth,
      completedDays: completedDays ?? this.completedDays,
      consistentDays: consistentDays ?? this.consistentDays,
      improvementRate: improvementRate ?? this.improvementRate,
    );
  }

  @override
  String toString() {
    return 'CategoryEvolution(categoryId: $categoryId, categoryName: $categoryName, monthlyAverage: $monthlyAverage, trendDirection: $trendDirection, predictedEndOfMonth: $predictedEndOfMonth)';
  }
}

/// Entidad para progreso diario dentro de CategoryEvolution
class DailyProgress extends Equatable {
  final DateTime date;
  final double completionPercentage;
  final int completedHabits;
  final int totalHabits;
  final String dayOfWeek;

  const DailyProgress({
    required this.date,
    required this.completionPercentage,
    required this.completedHabits,
    required this.totalHabits,
    required this.dayOfWeek,
  });

  @override
  List<Object?> get props => [
        date,
        completionPercentage,
        completedHabits,
        totalHabits,
        dayOfWeek,
      ];

  DailyProgress copyWith({
    DateTime? date,
    double? completionPercentage,
    int? completedHabits,
    int? totalHabits,
    String? dayOfWeek,
  }) {
    return DailyProgress(
      date: date ?? this.date,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      completedHabits: completedHabits ?? this.completedHabits,
      totalHabits: totalHabits ?? this.totalHabits,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    );
  }

  @override
  String toString() {
    return 'DailyProgress(date: $date, completionPercentage: $completionPercentage, completedHabits: $completedHabits, totalHabits: $totalHabits)';
  }
}