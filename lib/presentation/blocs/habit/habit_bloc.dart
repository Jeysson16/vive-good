import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../../domain/usecases/habit/add_habit_usecase.dart';
import '../../../domain/usecases/habit/delete_habit_usecase.dart';
import '../../../domain/usecases/habit/get_categories_usecase.dart';
import '../../../domain/usecases/habit/get_dashboard_habits_usecase.dart';
import '../../../domain/usecases/habit/get_habit_suggestions_usecase.dart';
import '../../../domain/usecases/habit/get_user_habits_usecase.dart';
import '../../../domain/usecases/habit/log_habit_completion_usecase.dart';
import 'habit_event.dart';
import 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final GetUserHabitsUseCase getUserHabitsUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final LogHabitCompletionUseCase logHabitCompletionUseCase;
  final GetHabitSuggestionsUseCase getHabitSuggestionsUseCase;
  final GetDashboardHabitsUseCase getDashboardHabitsUseCase;
  final AddHabitUseCase addHabitUseCase;
  final DeleteHabitUseCase deleteHabitUseCase;

  HabitBloc({
    required this.getUserHabitsUseCase,
    required this.getCategoriesUseCase,
    required this.logHabitCompletionUseCase,
    required this.getHabitSuggestionsUseCase,
    required this.getDashboardHabitsUseCase,
    required this.addHabitUseCase,
    required this.deleteHabitUseCase,
  }) : super(const HabitInitial()) {
    on<LoadUserHabits>(_onLoadUserHabits);
    on<LoadCategories>(_onLoadCategories);
    on<ToggleHabitCompletion>(_onToggleHabitCompletion);
    on<FilterHabitsByCategory>(_onFilterHabitsByCategory);
    on<LoadHabitSuggestions>(_onLoadHabitSuggestions);
    on<LoadDashboardHabits>(_onLoadDashboardHabits);
    on<AddHabit>(_onAddHabit);
    on<DeleteHabit>(_onDeleteHabit);
  }

  Future<void> _onAddHabit(AddHabit event, Emitter<HabitState> emit) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      final result = await addHabitUseCase(event.habit);
      result.fold((failure) => emit(HabitError(failure.toString())), (
        newHabit,
      ) {
        final updatedUserHabits = [...currentState.userHabits, newHabit];
        emit(
          currentState.copyWith(
            userHabits: List<UserHabit>.from(updatedUserHabits),
          ),
        );
      });
    }
  }

  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      final result = await deleteHabitUseCase(event.habitId);
      result.fold((failure) => emit(HabitError(failure.toString())), (_) {
        final updatedUserHabits = currentState.userHabits
            .where((habit) => habit.id != event.habitId)
            .toList();
        emit(currentState.copyWith(userHabits: updatedUserHabits));
      });
    }
  }

  Future<void> _onLoadUserHabits(
    LoadUserHabits event,
    Emitter<HabitState> emit,
  ) async {
    emit(const HabitLoading());

    final userHabitsResult = await getUserHabitsUseCase(event.userId);
    final categoriesResult = await getCategoriesUseCase(const NoParams());

    userHabitsResult.fold((failure) => emit(HabitError(failure.toString())), (
      userHabits,
    ) {
      categoriesResult.fold((failure) => emit(HabitError(failure.toString())), (
        categories,
      ) {
        // Extract habits from userHabits
        final habits = userHabits
            .where((uh) => uh.habit != null)
            .map((uh) => uh.habit!)
            .toList();

        // Calculate pending and completed counts based on UserHabit properties
        final pendingCount = userHabits
            .where((uh) => !uh.isCompletedToday)
            .length;
        final completedCount = userHabits
            .where((uh) => uh.isCompletedToday)
            .length;

        List<Habit> currentHabitSuggestions = [];
        AnimationState currentAnimationState = AnimationState.idle;

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          currentHabitSuggestions = currentState.habitSuggestions;
          currentAnimationState = currentState.animationState;
        }

        final newState = HabitLoaded(
          userHabits: userHabits,
          categories: categories,
          habits: habits,
          habitLogs:
              const <
                String,
                List<HabitLog>
              >{}, // Empty map for now, will be loaded separately if needed
          pendingCount: pendingCount,
          completedCount: completedCount,
          habitSuggestions: currentHabitSuggestions,
          animationState: currentAnimationState,
        );
        
        print('🔍 BLOC DEBUG: Emitting HabitLoaded state with ${newState.userHabits.length} userHabits');
        emit(newState);
      });
    });
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<HabitState> emit,
  ) async {
    print('🔍 DEBUG: LoadCategories event triggered');
    final result = await getCategoriesUseCase(const NoParams());
    result.fold((failure) {
      print('❌ DEBUG: Error loading categories: $failure');
      emit(HabitError(failure.toString()));
    }, (
      categories,
    ) {
      print('🔍 DEBUG: Loaded ${categories.length} categories from database:');
      for (var category in categories) {
        print('  - ID: ${category.id}, Name: "${category.name}"');
      }
      
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(categories: categories));
        print('🔍 DEBUG: Updated HabitLoaded state with categories');
      } else {
        // If state is not HabitLoaded, emit a basic HabitLoaded state with categories
        emit(
          HabitLoaded(
            userHabits: [],
            categories: categories,
            habits: [],
            habitLogs: const {},
            pendingCount: 0,
            completedCount: 0,
            habitSuggestions: [],
            animationState: AnimationState.idle,
          ),
        );
        print('🔍 DEBUG: Created new HabitLoaded state with categories');
      }
    });
  }

  Future<void> _onToggleHabitCompletion(
    ToggleHabitCompletion event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;

      if (event.isCompleted) {
        // Create a habit log
        final log = HabitLog(
          userHabitId: event.habitId,
          id: event.habitId,
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final result = await logHabitCompletionUseCase(
          LogHabitCompletionParams(habitId: event.habitId, date: event.date),
        );
        result.fold((failure) => emit(HabitError(failure.toString())), (_) {
          final updatedLogs = Map<String, List<HabitLog>>.from(
            currentState.habitLogs,
          );
          updatedLogs[event.habitId] = [
            ...updatedLogs[event.habitId] ?? [],
            log,
          ];

          emit(
            currentState.copyWith(
              habitLogs: updatedLogs,
              completedCount: currentState.completedCount + 1,
              pendingCount: currentState.pendingCount - 1,
            ),
          );
        });
      } else {
        // Remove the most recent log for this habit
        final updatedLogs = Map<String, List<HabitLog>>.from(
          currentState.habitLogs,
        );
        final logs = updatedLogs[event.habitId] ?? [];
        if (logs.isNotEmpty) {
          logs.removeLast();
          updatedLogs[event.habitId] = logs;

          emit(
            currentState.copyWith(
              habitLogs: updatedLogs,
              completedCount: currentState.completedCount - 1,
              pendingCount: currentState.pendingCount + 1,
            ),
          );
        }
      }
    }
  }

  void _onFilterHabitsByCategory(
    FilterHabitsByCategory event,
    Emitter<HabitState> emit,
  ) {
    final currentState = state;
    if (currentState is HabitLoaded) {
      emit(currentState.copyWith(
        selectedCategoryId: event.categoryId,
        resetSelectedCategory: event.categoryId == null,
      ));
    }
  }

  Future<void> _onLoadHabitSuggestions(
    LoadHabitSuggestions event,
    Emitter<HabitState> emit,
  ) async {
    String? currentCategoryId;
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      currentCategoryId = currentState.selectedCategoryId;
      emit(currentState.copyWith(animationState: AnimationState.loading));
    } else {
      emit(const HabitLoading());
    }

    final result = await getHabitSuggestionsUseCase(
      GetHabitSuggestionsParams(
        userId: event.userId,
        categoryId: event.categoryId ?? currentCategoryId,
        limit: event.limit ?? 10,
      ),
    );

    result.fold(
      (failure) {
        print('❌ BLOC ERROR: Failed to load habit suggestions: $failure');

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          emit(
            currentState.copyWith(
              habitSuggestions: [],
              animationState: AnimationState.idle,
            ),
          );
          print('🔍 BLOC DEBUG: Emitted empty suggestions due to error');
        } else {
          emit(HabitError(failure.toString()));
        }
      },
      (suggestions) {
        print(
          '🔍 BLOC DEBUG: Received ${suggestions.length} suggestions from Supabase',
        );
        // suggestions.forEach(
        //   (habit) => print('  - ${habit.name} (${habit.categoryId})'),
        // );

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          emit(
            currentState.copyWith(
              habitSuggestions: suggestions,
              animationState: AnimationState.idle,
            ),
          );
          print(
            '🔍 BLOC DEBUG: Emitted HabitLoaded state with ${suggestions.length} suggestions',
          );
        } else {
          // If not HabitLoaded, and we got suggestions, we need to transition to HabitLoaded
          // This case is tricky, as we don't have userHabits, categories, etc.
          // For now, let's assume we always transition from HabitLoaded or HabitInitial/Loading
          // If we are in HabitInitial/Loading, we should probably load everything first.
          // For now, I will just emit HabitLoaded with suggestions and empty other fields.
          emit(
            HabitLoaded(
              userHabits: [],
              categories: [],
              habits: [],
              habitLogs: const {},
              pendingCount: 0,
              completedCount: 0,
              habitSuggestions: suggestions,
              animationState: AnimationState.idle,
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadDashboardHabits(
    LoadDashboardHabits event,
    Emitter<HabitState> emit,
  ) async {
    print('🔍 BLOC DEBUG: Loading dashboard habits for user: ${event.userId}');
    emit(const HabitLoading());

    final params = GetDashboardHabitsParams(userId: event.userId);
    final dashboardResult = await getDashboardHabitsUseCase(params);
    final categoriesResult = await getCategoriesUseCase(const NoParams());
    
    print('🔍 BLOC DEBUG: Dashboard result type: ${dashboardResult.runtimeType}');
    print('🔍 BLOC DEBUG: Categories result type: ${categoriesResult.runtimeType}');

    dashboardResult.fold((failure) {
      print('❌ BLOC ERROR: Dashboard habits failed: $failure');
      emit(HabitError(failure.toString()));
    }, (
      dashboardHabits,
    ) {
      print('🔍 BLOC DEBUG: Received ${dashboardHabits.length} dashboard habits');
      // dashboardHabits.forEach((uh) => print('  - UserHabit: ${uh.id}, Habit: ${uh.habit?.name}, Completed: ${uh.isCompletedToday}'));
      
      categoriesResult.fold((failure) {
        print('❌ BLOC ERROR: Categories failed: $failure');
        emit(HabitError(failure.toString()));
      }, (
        categories,
      ) {
        print('🔍 BLOC DEBUG: Received ${categories.length} categories');
        
        // dashboardHabits is already List<UserHabit>
        final userHabits = dashboardHabits;

        // Extract habits from userHabits
        final habits = userHabits
            .where((uh) => uh.habit != null)
            .map((uh) => uh.habit!)
            .toList();

        // Calculate pending and completed counts based on UserHabit properties
        final pendingCount = userHabits
            .where((uh) => !uh.isCompletedToday)
            .length;
        final completedCount = userHabits
            .where((uh) => uh.isCompletedToday)
            .length;
            
        print('🔍 BLOC DEBUG: Extracted ${habits.length} habits, pending: $pendingCount, completed: $completedCount');

        List<Habit> currentHabitSuggestions = [];
        AnimationState currentAnimationState = AnimationState.idle;

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          currentHabitSuggestions = currentState.habitSuggestions;
          currentAnimationState = currentState.animationState;
        }

        emit(
          HabitLoaded(
            userHabits: userHabits,
            categories: categories,
            habits: habits,
            habitLogs:
                const <
                  String,
                  List<HabitLog>
                >{}, // Empty map for now, will be loaded separately if needed
            pendingCount: pendingCount,
            completedCount: completedCount,
            habitSuggestions: currentHabitSuggestions,
            animationState: currentAnimationState,
          ),
        );
      });
    });
  }
}
