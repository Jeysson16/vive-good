import 'package:equatable/equatable.dart';
import 'package:vive_good_app/domain/entities/habit_breakdown.dart';

abstract class HabitBreakdownState extends Equatable {
  const HabitBreakdownState();

  @override
  List<Object> get props => [];
}

class HabitBreakdownInitial extends HabitBreakdownState {}

class HabitBreakdownLoading extends HabitBreakdownState {}

class HabitBreakdownLoaded extends HabitBreakdownState {
  final List<HabitBreakdown> breakdown;

  const HabitBreakdownLoaded(this.breakdown);

  @override
  List<Object> get props => [breakdown];
}

class HabitBreakdownError extends HabitBreakdownState {
  final String message;

  const HabitBreakdownError(this.message);

  @override
  List<Object> get props => [message];
}