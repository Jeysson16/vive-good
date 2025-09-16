import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'category_scroll_event.dart';
import 'category_scroll_state.dart';

class CategoryScrollBloc
    extends Bloc<CategoryScrollEvent, CategoryScrollState> {
  Timer? _bounceTimer;

  CategoryScrollBloc() : super(CategoryScrollInitial()) {
    on<InitializeCategoryScroll>(_onInitializeCategoryScroll);
    on<ScrollToCategory>(_onScrollToCategory);
    on<UpdateScrollPosition>(_onUpdateScrollPosition);
    on<TriggerCategoryBounce>(_onTriggerCategoryBounce);
  }

  @override
  Future<void> close() {
    _bounceTimer?.cancel();
    return super.close();
  }

  void _onInitializeCategoryScroll(
    InitializeCategoryScroll event,
    Emitter<CategoryScrollState> emit,
  ) {
    emit(
      CategoryScrollLoaded(
        activeCategoryId: null,
        activeCategoryIndex: 0,
        scrollOffset: 0.0,
        categoryBounceStates: <String, bool>{},
        categoryIds: <String>[],
      ),
    );
  }

  void _onScrollToCategory(
    ScrollToCategory event,
    Emitter<CategoryScrollState> emit,
  ) {
    if (state is CategoryScrollLoaded) {
      final currentState = state as CategoryScrollLoaded;

      if (event.animate) {
        emit(
          CategoryScrollAnimating(
            targetCategoryId: event.categoryId ?? '',
            targetCategoryIndex: event.categoryIndex,
          ),
        );
      }

      emit(
        currentState.copyWith(
          activeCategoryId: event.categoryId,
          activeCategoryIndex: event.categoryIndex,
        ),
      );
    }
  }

  void _onUpdateScrollPosition(
    UpdateScrollPosition event,
    Emitter<CategoryScrollState> emit,
  ) {
    if (state is CategoryScrollLoaded) {
      final currentState = state as CategoryScrollLoaded;

      emit(
        currentState.copyWith(
          scrollOffset: event.scrollOffset,
          activeCategoryId: event.visibleCategoryId,
        ),
      );
    }
  }

  void _onTriggerCategoryBounce(
    TriggerCategoryBounce event,
    Emitter<CategoryScrollState> emit,
  ) {
    if (state is CategoryScrollLoaded) {
      final currentState = state as CategoryScrollLoaded;
      final newBounceStates = Map<String, bool>.from(
        currentState.categoryBounceStates,
      );

      // Activar el rebote para la categoría específica
      newBounceStates[event.categoryId] = true;

      emit(currentState.copyWith(categoryBounceStates: newBounceStates));

      // Desactivar el rebote después de la animación
      _bounceTimer?.cancel();
      _bounceTimer = Timer(const Duration(milliseconds: 600), () {
        if (state is CategoryScrollLoaded) {
          final currentState = state as CategoryScrollLoaded;
          final resetBounceStates = Map<String, bool>.from(
            currentState.categoryBounceStates,
          );
          resetBounceStates[event.categoryId] = false;

          emit(currentState.copyWith(categoryBounceStates: resetBounceStates));
        }
      });
    }
  }
}
