import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/usecases/habit/get_dashboard_habits_usecase.dart';
import '../../../domain/usecases/habit/get_categories_usecase.dart';

import '../habit/habit_state.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardHabitsUseCase getDashboardHabitsUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;

  DashboardBloc({
    required this.getDashboardHabitsUseCase,
    required this.getCategoriesUseCase,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<ToggleDashboardHabitCompletion>(_onToggleDashboardHabitCompletion);
    on<ToggleDashboardHabitsCompletionBulk>(_onToggleDashboardHabitsCompletionBulk);
    on<FilterDashboardByCategory>(_onFilterDashboardByCategory);
    on<RefreshDashboardData>(_onRefreshDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // Debug: Check current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      print('🔍 [DEBUG] Current user: ${currentUser?.id ?? "No user authenticated"}');
      if (currentUser != null) {
        print('   - Email: ${currentUser.email}');
        print('   - Created: ${currentUser.createdAt}');
      }

      // Load dashboard habits
      final dashboardResult = await getDashboardHabitsUseCase(
        GetDashboardHabitsParams(
          userId: event.userId,
          limit: 50,
          includeCompletionStatus: true,
        ),
      );
      final categoriesResult = await getCategoriesUseCase(NoParams());
      print('🔍 [DEBUG] Dashboard - Categories result: $categoriesResult');

      dashboardResult.fold(
        (failure) {
          emit(DashboardError(failure.message));
        },
        (userHabits) async {
          categoriesResult.fold(
            (failure) {
              print('❌ [DEBUG] Dashboard - Categories error: ${failure.message}');
              emit(DashboardError(failure.message));
            },
            (categories) {
              print('✅ [DEBUG] Dashboard - Categories loaded: ${categories.length} categories');
              for (var category in categories) {
                print('   - ${category.name} (${category.id})');
              }
              print('✅ [DEBUG] Dashboard - UserHabits loaded: ${userHabits.length} userHabits');
              for (var userHabit in userHabits) {
                print('   - UserHabit ${userHabit.id} -> habitId: ${userHabit.habitId}');
              }
              // Create habit objects from user habits
              final habits = userHabits
                  .map(
                    (userHabit) => Habit(
                      id: userHabit.habitId ?? userHabit.id,
                      name: userHabit.customName ??
                          userHabit.habit?.name ??
                          'Hábito personalizado',
                      description: userHabit.customDescription ??
                          userHabit.habit?.description ??
                          '',
                      categoryId: userHabit.habit?.categoryId ?? 'fallback',
                      iconName: userHabit.habit?.iconName ?? 'star',
                      iconColor: userHabit.habit?.iconColor ?? '#4CAF50',
                      createdAt: userHabit.createdAt,
                      updatedAt: userHabit.updatedAt,
                    ),
                  )
                  .toList();

              // Calculate pending and completed counts
              print('🔍 [DEBUG] DashboardBloc - Calculating pending count from ${userHabits.length} userHabits');
              final today = DateTime.now();
              
              final pendingHabits = userHabits.where((habit) {
                final isNotCompleted = !habit.isCompletedToday;
                final shouldBeActiveToday = _shouldHabitBeActiveToday(habit, today);
                print('  - Habit ${habit.id}: isCompletedToday=${habit.isCompletedToday}, isActive=${habit.isActive}, frequency=${habit.frequency}, shouldBeActiveToday=$shouldBeActiveToday');
                return isNotCompleted && shouldBeActiveToday;
              }).toList();
              
              final completedHabits = userHabits.where((habit) {
                final isCompleted = habit.isCompletedToday;
                final shouldBeActiveToday = _shouldHabitBeActiveToday(habit, today);
                return isCompleted && shouldBeActiveToday;
              }).toList();
              
              print('📊 [DEBUG] DashboardBloc - Pending habits: ${pendingHabits.length}, Completed habits: ${completedHabits.length}');
              
              final pendingCount = pendingHabits.length;
              final completedCount = completedHabits.length;

              print('✅ [DEBUG] DashboardBloc - Emitting DashboardLoaded state with pendingCount=$pendingCount, completedCount=$completedCount');

              emit(
                DashboardLoaded(
                  userHabits: userHabits,
                  filteredHabits: userHabits,
                  habits: habits,
                  categories: categories,
                  habitLogs: const {},
                  pendingCount: pendingCount,
                  completedCount: completedCount,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      emit(DashboardError('Error loading dashboard data: ${e.toString()}'));
    }
  }

  Future<void> _onToggleDashboardHabitCompletion(
    ToggleDashboardHabitCompletion event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      // Find the habit to update
      final habitIndex = currentState.userHabits.indexWhere(
        (uh) => uh.id == event.habitId,
      );
      
      if (habitIndex == -1) return;
      
      final originalHabit = currentState.userHabits[habitIndex];
      
      // If marking as completed, handle animation first
      if (event.isCompleted && !originalHabit.isCompletedToday) {
        // First emit state with animation but WITHOUT updating isCompletedToday yet
        // This keeps the habit visible during animation
        emit(currentState.copyWith(
          animatedHabitId: event.habitId,
          animationState: AnimationState.habitToggled,
        ));
        
        // Wait for animation to complete (2 seconds total animation time)
        await Future.delayed(const Duration(milliseconds: 2000));
        
        // Now create the updated habit with completion status
        final updatedHabit = UserHabit(
          id: originalHabit.id,
          userId: originalHabit.userId,
          habitId: originalHabit.habitId,
          frequency: originalHabit.frequency,
          scheduledTime: originalHabit.scheduledTime,
          notificationsEnabled: originalHabit.notificationsEnabled,
          startDate: originalHabit.startDate,
          endDate: originalHabit.endDate,
          isActive: originalHabit.isActive,
          createdAt: originalHabit.createdAt,
          updatedAt: originalHabit.updatedAt,
          customName: originalHabit.customName,
          customDescription: originalHabit.customDescription,
          isCompletedToday: true,
          completionCountToday: 1,
          lastCompletedAt: DateTime.now(),
          streakCount: originalHabit.streakCount,
          totalCompletions: originalHabit.totalCompletions,
          habit: originalHabit.habit,
        );
        
        // Update the lists
        final updatedUserHabits = List<UserHabit>.from(currentState.userHabits);
        updatedUserHabits[habitIndex] = updatedHabit;
        
        final updatedFilteredHabits = List<UserHabit>.from(currentState.filteredHabits);
        final filteredIndex = updatedFilteredHabits.indexWhere((uh) => uh.id == event.habitId);
        if (filteredIndex != -1) {
          updatedFilteredHabits[filteredIndex] = updatedHabit;
        }
        
        // Update counts - only consider habits that should be active today
        final today = DateTime.now();
        final newPendingCount = updatedUserHabits.where((habit) {
          final isNotCompleted = !habit.isCompletedToday;
          final shouldBeActiveToday = _shouldHabitBeActiveToday(habit, today);
          return isNotCompleted && shouldBeActiveToday;
        }).length;
        final newCompletedCount = updatedUserHabits.where((habit) {
          final isCompleted = habit.isCompletedToday;
          final shouldBeActiveToday = _shouldHabitBeActiveToday(habit, today);
          return isCompleted && shouldBeActiveToday;
        }).length;
        
        // Emit final state with updated habit and no animation
        emit(currentState.copyWith(
          userHabits: updatedUserHabits,
          filteredHabits: updatedFilteredHabits,
          pendingCount: newPendingCount,
          completedCount: newCompletedCount,
          animatedHabitId: null,
          animationState: AnimationState.idle,
        ));
      } else {
        // For uncompleting or other cases, update immediately
        final updatedHabit = UserHabit(
          id: originalHabit.id,
          userId: originalHabit.userId,
          habitId: originalHabit.habitId,
          frequency: originalHabit.frequency,
          scheduledTime: originalHabit.scheduledTime,
          notificationsEnabled: originalHabit.notificationsEnabled,
          startDate: originalHabit.startDate,
          endDate: originalHabit.endDate,
          isActive: originalHabit.isActive,
          createdAt: originalHabit.createdAt,
          updatedAt: originalHabit.updatedAt,
          customName: originalHabit.customName,
          customDescription: originalHabit.customDescription,
          isCompletedToday: event.isCompleted,
          completionCountToday: event.isCompleted ? 1 : 0,
          lastCompletedAt: event.isCompleted ? DateTime.now() : originalHabit.lastCompletedAt,
          streakCount: originalHabit.streakCount,
          totalCompletions: originalHabit.totalCompletions,
          habit: originalHabit.habit,
        );
        
        // Update the lists
        final updatedUserHabits = List<UserHabit>.from(currentState.userHabits);
        updatedUserHabits[habitIndex] = updatedHabit;
        
        final updatedFilteredHabits = List<UserHabit>.from(currentState.filteredHabits);
        final filteredIndex = updatedFilteredHabits.indexWhere((uh) => uh.id == event.habitId);
        if (filteredIndex != -1) {
          updatedFilteredHabits[filteredIndex] = updatedHabit;
        }
        
        // Update counts - only consider habits that should be active today
        final today = DateTime.now();
        final newPendingCount = updatedUserHabits.where((habit) {
          final isNotCompleted = !habit.isCompletedToday;
          final shouldBeActiveToday = _shouldHabitBeActiveToday(habit, today);
          return isNotCompleted && shouldBeActiveToday;
        }).length;
        final newCompletedCount = updatedUserHabits.where((habit) {
          final isCompleted = habit.isCompletedToday;
          final shouldBeActiveToday = _shouldHabitBeActiveToday(habit, today);
          return isCompleted && shouldBeActiveToday;
        }).length;
        
        emit(currentState.copyWith(
          userHabits: updatedUserHabits,
          filteredHabits: updatedFilteredHabits,
          pendingCount: newPendingCount,
          completedCount: newCompletedCount,
          animatedHabitId: null,
          animationState: AnimationState.idle,
        ));
      }
      
      // Note: Backend sync is handled by HabitBloc via ToggleHabitCompletion event
      // DashboardBloc only handles UI state and animations
    }
  }

  Future<void> _onToggleDashboardHabitsCompletionBulk(
    ToggleDashboardHabitsCompletionBulk event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final currentState = state as DashboardLoaded;

    // Determinar hábitos válidos para completar hoy (no completados y activos)
    final today = DateTime.now();
    final idsToComplete = event.habitIds.where((id) {
      final idx = currentState.userHabits.indexWhere((uh) => uh.id == id);
      if (idx == -1) return false;
      final uh = currentState.userHabits[idx];
      final isNotCompleted = !uh.isCompletedToday;
      final isActiveToday = _shouldHabitBeActiveToday(uh, today);
      return isNotCompleted && isActiveToday;
    }).toList();

    if (idsToComplete.isEmpty) {
      return; // Nada para completar
    }

    // Emitir un estado de animación simultánea (sin animatedHabitId específico)
    emit(currentState.copyWith(
      animatedHabitId: null,
      animationState: AnimationState.habitToggled,
    ));

    // Esperar la duración de la animación una sola vez para todos
    await Future.delayed(const Duration(milliseconds: 2000));

    // Aplicar actualización de completado a todos los seleccionados
    final updatedUserHabits = List<UserHabit>.from(currentState.userHabits);
    final updatedFilteredHabits = List<UserHabit>.from(currentState.filteredHabits);

    for (final id in idsToComplete) {
      final idx = updatedUserHabits.indexWhere((uh) => uh.id == id);
      if (idx == -1) continue;
      final original = updatedUserHabits[idx];
      final updated = UserHabit(
        id: original.id,
        userId: original.userId,
        habitId: original.habitId,
        frequency: original.frequency,
        scheduledTime: original.scheduledTime,
        notificationsEnabled: original.notificationsEnabled,
        startDate: original.startDate,
        endDate: original.endDate,
        isActive: original.isActive,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
        customName: original.customName,
        customDescription: original.customDescription,
        isCompletedToday: true,
        completionCountToday: 1,
        lastCompletedAt: DateTime.now(),
        streakCount: original.streakCount,
        totalCompletions: original.totalCompletions,
        habit: original.habit,
      );
      updatedUserHabits[idx] = updated;

      final fIdx = updatedFilteredHabits.indexWhere((uh) => uh.id == id);
      if (fIdx != -1) {
        updatedFilteredHabits[fIdx] = updated;
      }
    }

    // Recalcular contadores considerando solo hábitos activos hoy
    final newPendingCount = updatedUserHabits.where((habit) {
      final isNotCompleted = !habit.isCompletedToday;
      final isActiveToday = _shouldHabitBeActiveToday(habit, today);
      return isNotCompleted && isActiveToday;
    }).length;
    final newCompletedCount = updatedUserHabits.where((habit) {
      final isCompleted = habit.isCompletedToday;
      final isActiveToday = _shouldHabitBeActiveToday(habit, today);
      return isCompleted && isActiveToday;
    }).length;

    emit(currentState.copyWith(
      userHabits: updatedUserHabits,
      filteredHabits: updatedFilteredHabits,
      pendingCount: newPendingCount,
      completedCount: newCompletedCount,
      animatedHabitId: null,
      animationState: AnimationState.idle,
    ));

    // Note: Backend sync for bulk completion should be handled by individual 
    // ToggleHabitCompletion events dispatched to HabitBloc for each habit
  }

  Future<void> _onFilterDashboardByCategory(
    FilterDashboardByCategory event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;

      // Siempre mostramos todos los hábitos en la grilla;
      // el cambio de categoría solo debe resaltar el primero de esa categoría.
      final filteredHabits = currentState.userHabits;

      // If filtering by category and there are habits, highlight the first incomplete habit
      String? firstHabitId;
      if (event.categoryId != null && filteredHabits.isNotEmpty) {
        // Find the first incomplete habit in the filtered list
        final today = DateTime.now();
        final incompleteHabits = filteredHabits.where((userHabit) {
          final isNotCompleted = !userHabit.isCompletedToday;
          final shouldBeActiveToday = _shouldHabitBeActiveToday(userHabit, today);
          // Solo dentro de la categoría seleccionada
          final habit = currentState.habits.firstWhere(
            (h) => h.id == userHabit.habitId,
            orElse: () => Habit(
              id: 'fallback',
              name: 'Hábito no encontrado',
              description: '',
              categoryId: 'fallback',
              iconName: 'star',
              iconColor: '#4CAF50',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final inSelectedCategory = habit.categoryId == event.categoryId;
          return isNotCompleted && shouldBeActiveToday && inSelectedCategory;
        }).toList();
        
        if (incompleteHabits.isNotEmpty) {
          firstHabitId = incompleteHabits.first.id;
        }
      }

      emit(
        currentState.copyWith(
          filteredHabits: filteredHabits,
          selectedCategoryId: event.categoryId,
          animatedHabitId: firstHabitId,
          animationState: firstHabitId != null ? AnimationState.categoryChanged : AnimationState.idle,
        ),
      );

      // Clear animation state after the highlight animation completes, while still inside handler
      if (firstHabitId != null) {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (emit.isDone) return;
        if (state is DashboardLoaded) {
          final latestState = state as DashboardLoaded;
          emit(latestState.copyWith(
            animatedHabitId: null,
            animationState: AnimationState.idle,
          ));
        }
      }
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      print('🔄 [DEBUG] DashboardBloc._onRefreshDashboardData - Starting refresh');
      
      // Show loading state briefly to indicate refresh is happening
      emit(DashboardLoading());
      
      // Add timeout to prevent hanging
      await Future.any([
        _onLoadDashboardData(
          LoadDashboardData(userId: event.userId, date: event.date),
          emit,
        ),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException('Refresh timeout after 5 seconds');
        }),
      ]);
      
      print('🔄 [DEBUG] DashboardBloc._onRefreshDashboardData - Refresh completed successfully');
    } catch (e) {
      print('🚨 [ERROR] DashboardBloc._onRefreshDashboardData - Refresh failed: $e');
      emit(DashboardSyncError(
        'Error al sincronizar datos. Reintentando...',
        shouldAutoRefresh: false, // Avoid infinite refresh loops
      ));
    }
  }

  /// Check if a habit should be active today based on its frequency
  bool _shouldHabitBeActiveToday(UserHabit userHabit, DateTime today) {
    print('🔍 [DEBUG] DashboardBloc._shouldHabitBeActiveToday - Habit ${userHabit.id}: isActive=${userHabit.isActive}, frequency=${userHabit.frequency}');
    
    if (!userHabit.isActive) {
      print('  -> Habit is not active, returning false');
      return false;
    }
    
    switch (userHabit.frequency.toLowerCase()) {
      case 'daily':
      case 'diario':
        print('  -> Daily habit, returning true');
        return true;
      case 'weekly':
      case 'semanal':
        // Check if today is one of the selected days for weekly habits
        if (userHabit.frequencyDetails != null && 
            userHabit.frequencyDetails!.containsKey('days_of_week')) {
          final selectedDays = userHabit.frequencyDetails!['days_of_week'] as List<dynamic>?;
          if (selectedDays != null && selectedDays.isNotEmpty) {
            // Convert today's weekday (1=Monday, 7=Sunday) to match the stored format
            final todayWeekday = today.weekday;
            final result = selectedDays.contains(todayWeekday);
            print('  -> Weekly habit with specific days: $selectedDays, today=$todayWeekday, result=$result');
            return result;
          }
        }
        // If no specific days are set, default to all days
        print('  -> Weekly habit with no specific days, returning true');
        return true;
      case 'monthly':
      case 'mensual':
        // For monthly habits, check if today matches the target day
        if (userHabit.frequencyDetails != null && 
            userHabit.frequencyDetails!.containsKey('day_of_month')) {
          final targetDay = userHabit.frequencyDetails!['day_of_month'] as int?;
          if (targetDay != null) {
            final result = today.day == targetDay;
            print('  -> Monthly habit with target day $targetDay, today=${today.day}, result=$result');
            return result;
          }
        }
        // If no specific day is set, default to first day of month
        final result = today.day == 1;
        print('  -> Monthly habit with no specific day, today=${today.day}, result=$result');
        return result;
      default:
        print('  -> Unknown frequency, returning true');
        return true; // Default to active for unknown frequencies
    }
  }
}
