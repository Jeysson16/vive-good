import 'package:equatable/equatable.dart';

abstract class HabitStatisticsEvent extends Equatable {
  const HabitStatisticsEvent();

  @override
  List<Object> get props => [];
}

class LoadHabitStatistics extends HabitStatisticsEvent {
  final String userId;
  final int year;
  final int month;

  const LoadHabitStatistics({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [userId, year, month];
}

class RefreshHabitStatistics extends HabitStatisticsEvent {
  final String userId;
  final int year;
  final int month;

  const RefreshHabitStatistics({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [userId, year, month];
}