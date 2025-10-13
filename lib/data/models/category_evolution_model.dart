import 'package:equatable/equatable.dart';
import 'package:vive_good_app/domain/entities/category_evolution.dart';

class DailyProgressModel extends Equatable {
  final DateTime date;
  final double completionPercentage;
  final int completedHabits;
  final int totalHabits;

  const DailyProgressModel({
    required this.date,
    required this.completionPercentage,
    required this.completedHabits,
    required this.totalHabits,
  });

  factory DailyProgressModel.fromJson(Map<String, dynamic> json) {
    return DailyProgressModel(
      date: DateTime.parse(json['date']),
      completionPercentage: (json['completion_percentage'] ?? 0.0).toDouble(),
      completedHabits: (json['completed_habits'] ?? 0).toInt(),
      totalHabits: (json['total_habits'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completion_percentage': completionPercentage,
      'completed_habits': completedHabits,
      'total_habits': totalHabits,
    };
  }

  DailyProgress toEntity() {
    return DailyProgress(
      date: date,
      completionPercentage: completionPercentage,
      completedHabits: completedHabits,
      totalHabits: totalHabits,
      dayOfWeek: _getDayOfWeekName(date.weekday),
    );
  }

  String _getDayOfWeekName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  @override
  List<Object?> get props => [date, completionPercentage, completedHabits, totalHabits];
}

class CategoryEvolutionModel extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final List<DailyProgressModel> dailyProgress;
  final double monthlyAverage;
  final String monthlyTrend;
  final double predictedEndOfMonth;
  final List<String> bestDaysOfWeek;
  final List<String> worstDaysOfWeek;
  final double improvementRate;
  final int totalDaysTracked;
  final int consistentDays;

  const CategoryEvolutionModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.dailyProgress,
    required this.monthlyAverage,
    required this.monthlyTrend,
    required this.predictedEndOfMonth,
    required this.bestDaysOfWeek,
    required this.worstDaysOfWeek,
    required this.improvementRate,
    required this.totalDaysTracked,
    required this.consistentDays,
  });

  factory CategoryEvolutionModel.fromJson(Map<String, dynamic> json) {
    return CategoryEvolutionModel(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      categoryColor: json['category_color'] ?? '#4CAF50',
      categoryIcon: json['category_icon'] ?? 'star',
      // Soportar múltiples formatos de respuesta del backend
      dailyProgress: (
                json['daily_progress'] as List<dynamic>?
              )?.map((item) => DailyProgressModel.fromJson(item as Map<String, dynamic>)).toList()
              ?? (
                (json['daily_progress_data'] is Map<String, dynamic>)
                  ? ((json['daily_progress_data']['sample_days'] as List<dynamic>?)
                      ?.map((item) => DailyProgressModel.fromJson({
                            'date': (item as Map<String, dynamic>)['date'],
                            'completion_percentage': (item)['completion_percentage'],
                            'completed_habits': (item)['completed_habits'] ?? 0,
                            'total_habits': (item)['total_habits'] ?? 0,
                          }))
                      .toList())
                  : null
              )
              ?? [],
      monthlyAverage: (json['monthly_average'] ?? json['monthlyAverage'] ?? 0.0).toDouble(),
      monthlyTrend: json['monthly_trend'] ?? json['trend'] ?? 'stable',
      predictedEndOfMonth: (json['predicted_end_of_month'] ?? json['prediction'] ?? 0.0).toDouble(),
      bestDaysOfWeek: List<String>.from(json['best_days_of_week'] ?? json['best_days'] ?? []),
      worstDaysOfWeek: List<String>.from(json['worst_days_of_week'] ?? json['worst_days'] ?? []),
      improvementRate: (json['improvement_rate'] ?? json['improvementRate'] ?? 0.0).toDouble(),
      totalDaysTracked: (json['total_days_tracked'] ?? json['total_tracked_days'] ?? 0).toInt(),
      consistentDays: (json['consistent_days'] ?? json['consistent_days'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'category_icon': categoryIcon,
      'daily_progress': dailyProgress.map((item) => item.toJson()).toList(),
      'monthly_average': monthlyAverage,
      'monthly_trend': monthlyTrend,
      'predicted_end_of_month': predictedEndOfMonth,
      'best_days_of_week': bestDaysOfWeek,
      'worst_days_of_week': worstDaysOfWeek,
      'improvement_rate': improvementRate,
      'total_days_tracked': totalDaysTracked,
      'consistent_days': consistentDays,
    };
  }

  CategoryEvolution toEntity() {
    return CategoryEvolution(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      dailyProgress: dailyProgress.map((item) => item.toEntity()).toList(),
      monthlyAverage: monthlyAverage,
      previousMonthAverage: 0.0, // Valor por defecto, se puede calcular después
      monthlyTrend: improvementRate, // Usar improvementRate como monthlyTrend
      trendDirection: _getTrendDirection(improvementRate),
      predictedEndOfMonth: predictedEndOfMonth,
      bestDaysOfWeek: bestDaysOfWeek,
      worstDaysOfWeek: worstDaysOfWeek,
      totalDaysInMonth: totalDaysTracked,
      completedDays: consistentDays,
      consistentDays: consistentDays,
      improvementRate: improvementRate,
    );
  }

  String _getTrendDirection(double improvementRate) {
    if (improvementRate > 0.1) return 'improving';
    if (improvementRate < -0.1) return 'declining';
    return 'stable';
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryColor,
        categoryIcon,
        dailyProgress,
        monthlyAverage,
        monthlyTrend,
        predictedEndOfMonth,
        bestDaysOfWeek,
        worstDaysOfWeek,
        improvementRate,
        totalDaysTracked,
        consistentDays,
      ];

  @override
  String toString() {
    return 'CategoryEvolutionModel(categoryId: $categoryId, categoryName: $categoryName, monthlyAverage: $monthlyAverage, monthlyTrend: $monthlyTrend)';
  }
}