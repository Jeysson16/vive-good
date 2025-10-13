import 'package:equatable/equatable.dart';
import 'package:vive_good_app/domain/entities/habit_statistics.dart';

abstract class HabitStatisticsState extends Equatable {
  const HabitStatisticsState();

  @override
  List<Object> get props => [];
}

class HabitStatisticsInitial extends HabitStatisticsState {}

class HabitStatisticsLoading extends HabitStatisticsState {}

class HabitStatisticsLoaded extends HabitStatisticsState {
  final List<HabitStatistics> statistics;

  const HabitStatisticsLoaded(this.statistics);

  @override
  List<Object> get props => [statistics];
}

class HabitStatisticsError extends HabitStatisticsState {
  final String message;

  const HabitStatisticsError(this.message);

  @override
  List<Object> get props => [message];
}

class HabitStatisticsRefreshing extends HabitStatisticsState {
  final List<HabitStatistics> currentStatistics;

  const HabitStatisticsRefreshing(this.currentStatistics);

  @override
  List<Object> get props => [currentStatistics];
}