import "package:equatable/equatable.dart";

/// Entidad para progreso diario
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

  @override
  String toString() {
    return "DailyProgress(date: $date, completionPercentage: $completionPercentage, completedHabits: $completedHabits, totalHabits: $totalHabits, dayOfWeek: $dayOfWeek)";
  }
}