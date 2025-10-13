import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/domain/usecases/get_monthly_habits_breakdown.dart';
import 'habit_breakdown_event.dart';
import 'habit_breakdown_state.dart';

class HabitBreakdownBloc
    extends Bloc<HabitBreakdownEvent, HabitBreakdownState> {
  final GetMonthlyHabitsBreakdown getMonthlyHabitsBreakdown;

  HabitBreakdownBloc({required this.getMonthlyHabitsBreakdown})
    : super(HabitBreakdownInitial()) {
    on<LoadMonthlyHabitsBreakdown>(_onLoadMonthlyHabitsBreakdown);
  }

  Future<void> _onLoadMonthlyHabitsBreakdown(
    LoadMonthlyHabitsBreakdown event,
    Emitter<HabitBreakdownState> emit,
  ) async {
    emit(HabitBreakdownLoading());

    final result = await getMonthlyHabitsBreakdown(
      GetMonthlyHabitsBreakdownParams(
        userId: event.userId,
        year: event.year,
        month: event.month,
      ),
    );

    result.fold(
      (failure) => emit(HabitBreakdownError(failure.toString())),
      (breakdown) => emit(HabitBreakdownLoaded(breakdown)),
    );
  }
}
