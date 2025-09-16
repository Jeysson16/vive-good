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

  const ProgressLoaded({required this.progress, this.dailyProgress});

  @override
  List<Object?> get props => [progress, dailyProgress];
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