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