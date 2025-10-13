import 'package:equatable/equatable.dart';
import '../../../domain/entities/progress.dart';

abstract class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final Progress progress;
  final Map<String, double>? dailyProgress;
  final int? userStreak;
  // Nuevos campos para evolución mensual
  final List<Progress>? monthlyProgress; // lista por semanas del mes
  final Map<String, String>? monthlyIndicators; // mejor día, hábito consistente, área de mejora

  const ProgressLoaded({
    required this.progress,
    this.dailyProgress,
    this.userStreak,
    this.monthlyProgress,
    this.monthlyIndicators,
  });

  @override
  List<Object?> get props => [
    progress,
    dailyProgress,
    userStreak,
    monthlyProgress,
    monthlyIndicators,
  ];
}

class ProgressError extends ProgressState {
  final String message;

  const ProgressError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProgressRefreshing extends ProgressState {
  final Progress progress;
  final Map<String, double>? dailyProgress;
  final int? userStreak;
  final List<Progress>? monthlyProgress;
  final Map<String, String>? monthlyIndicators;

  const ProgressRefreshing({
    required this.progress,
    this.dailyProgress,
    this.userStreak,
    this.monthlyProgress,
    this.monthlyIndicators,
  });

  @override
  List<Object?> get props => [
    progress,
    dailyProgress,
    userStreak,
    monthlyProgress,
    monthlyIndicators,
  ];
}