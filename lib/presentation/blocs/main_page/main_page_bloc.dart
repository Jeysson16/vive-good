import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class MainPageEvent extends Equatable {
  const MainPageEvent();

  @override
  List<Object?> get props => [];
}

class SelectCategoryInMainPage extends MainPageEvent {
  final String? categoryId;
  final bool shouldScrollToFirst;

  const SelectCategoryInMainPage(
    this.categoryId, {
    this.shouldScrollToFirst = false,
  });

  @override
  List<Object?> get props => [categoryId, shouldScrollToFirst];
}

class ResetMainPageState extends MainPageEvent {
  const ResetMainPageState();
}

// States
abstract class MainPageState extends Equatable {
  const MainPageState();

  @override
  List<Object?> get props => [];
}

class MainPageInitial extends MainPageState {
  const MainPageInitial();
}

class MainPageLoaded extends MainPageState {
  final String? selectedCategoryId;
  final bool shouldScrollToFirst;
  final String? animatedHabitId;

  const MainPageLoaded({
    this.selectedCategoryId,
    this.shouldScrollToFirst = false,
    this.animatedHabitId,
  });

  @override
  List<Object?> get props => [
    selectedCategoryId,
    shouldScrollToFirst,
    animatedHabitId,
  ];

  MainPageLoaded copyWith({
    String? selectedCategoryId,
    bool? shouldScrollToFirst,
    String? animatedHabitId,
    bool resetSelectedCategory = false,
  }) {
    return MainPageLoaded(
      selectedCategoryId: resetSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      shouldScrollToFirst: shouldScrollToFirst ?? this.shouldScrollToFirst,
      animatedHabitId: animatedHabitId ?? this.animatedHabitId,
    );
  }
}

// Bloc
class MainPageBloc extends Bloc<MainPageEvent, MainPageState> {
  MainPageBloc() : super(const MainPageInitial()) {
    on<SelectCategoryInMainPage>(_onSelectCategoryInMainPage);
    on<ResetMainPageState>(_onResetMainPageState);
  }

  void _onSelectCategoryInMainPage(
    SelectCategoryInMainPage event,
    Emitter<MainPageState> emit,
  ) {
    emit(
      MainPageLoaded(
        selectedCategoryId: event.categoryId,
        shouldScrollToFirst: event.shouldScrollToFirst,
      ),
    );
  }

  void _onResetMainPageState(
    ResetMainPageState event,
    Emitter<MainPageState> emit,
  ) {
    emit(const MainPageInitial());
  }
}
