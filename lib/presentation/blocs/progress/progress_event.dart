import 'package:equatable/equatable.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProgress extends ProgressEvent {
  final String userId;

  const LoadUserProgress({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class RefreshUserProgress extends ProgressEvent {
  final String userId;

  const RefreshUserProgress({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProgress extends ProgressEvent {
  final String userId;

  const UpdateUserProgress({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadDailyWeekProgress extends ProgressEvent {
  final String userId;

  const LoadDailyWeekProgress({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadUserStreak extends ProgressEvent {
  final String userId;

  const LoadUserStreak({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Cargar datos de evolución mensual (series y indicadores)
class LoadMonthlyProgress extends ProgressEvent {
  final String userId;

  const LoadMonthlyProgress({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Cargar datos de evolución mensual para un mes específico
class LoadMonthlyProgressForDate extends ProgressEvent {
  final String userId;
  final int year;
  final int month;

  const LoadMonthlyProgressForDate({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [userId, year, month];
}