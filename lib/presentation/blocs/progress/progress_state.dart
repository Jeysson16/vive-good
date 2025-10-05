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

  const ProgressLoaded({required this.progress, this.dailyProgress, this.userStreak});

  @override
  List<Object?> get props => [progress, dailyProgress, userStreak];
}

class ProgressError extends ProgressState {
  final String message;

  const ProgressError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProgressRefreshing extends ProgressState {
  final Progress progress;

  const ProgressRefreshing({required this.progress});

  @override
  List<Object?> get props => [progress];
}