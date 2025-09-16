import 'package:equatable/equatable.dart';

abstract class HabitBreakdownEvent extends Equatable {
  const HabitBreakdownEvent();

  @override
  List<Object> get props => [];
}

class LoadMonthlyHabitsBreakdown extends HabitBreakdownEvent {
  final String userId;
  final int year;
  final int month;

  const LoadMonthlyHabitsBreakdown({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [userId, year, month];
}