import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/domain/entities/category.dart';

import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit_notification.dart';
import '../../../domain/usecases/habit/add_habit_usecase.dart';
import '../../../domain/usecases/habit/delete_habit_usecase.dart';
import '../../../domain/usecases/habit/delete_user_habit_usecase.dart';
import '../../../domain/usecases/habit/get_categories_usecase.dart';
import '../../../domain/usecases/habit/get_dashboard_habits_usecase.dart';
import '../../../domain/usecases/habit/get_habit_suggestions_usecase.dart';
import '../../../domain/usecases/habit/get_user_habit_by_id_usecase.dart';
import '../../../domain/usecases/habit/get_user_habits_usecase.dart';
import '../../../domain/usecases/habit/log_habit_completion_usecase.dart';
import '../../../domain/usecases/habit/update_user_habit_usecase.dart';
import '../../../domain/usecases/notifications/schedule_habit_notification_usecase.dart';
import '../../../domain/usecases/notifications/cancel_habit_notification_usecase.dart';
import '../../../domain/usecases/notifications/manage_habit_notification_usecase.dart';
import 'habit_event.dart';
import 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final GetUserHabitsUseCase getUserHabitsUseCase;
  final GetUserHabitByIdUseCase getUserHabitByIdUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final LogHabitCompletionUseCase logHabitCompletionUseCase;
  final GetHabitSuggestionsUseCase getHabitSuggestionsUseCase;
  final GetDashboardHabitsUseCase getDashboardHabitsUseCase;
  final AddHabitUseCase addHabitUseCase;
  final DeleteHabitUseCase deleteHabitUseCase;
  final UpdateUserHabitUseCase updateUserHabitUseCase;
  final DeleteUserHabitUseCase deleteUserHabitUseCase;
  
  // Notification use cases
  final ScheduleHabitNotificationUseCase scheduleHabitNotificationUseCase;
  final CancelHabitNotificationUseCase cancelHabitNotificationUseCase;
  final CancelAllNotificationsForHabitUseCase cancelAllNotificationsForHabitUseCase;
  final CreateHabitNotificationUseCase createHabitNotificationUseCase;
  final UpdateHabitNotificationUseCase updateHabitNotificationUseCase;
  final DeleteHabitNotificationUseCase deleteHabitNotificationUseCase;

  // Set to track habits currently being processed to prevent double counting
  final Set<String> _processingHabits = <String>{};

  HabitBloc({
    required this.getUserHabitsUseCase,
    required this.getUserHabitByIdUseCase,
    required this.getCategoriesUseCase,
    required this.logHabitCompletionUseCase,
    required this.getHabitSuggestionsUseCase,
    required this.getDashboardHabitsUseCase,
    required this.addHabitUseCase,
    required this.deleteHabitUseCase,
    required this.updateUserHabitUseCase,
    required this.deleteUserHabitUseCase,
    required this.scheduleHabitNotificationUseCase,
    required this.cancelHabitNotificationUseCase,
    required this.cancelAllNotificationsForHabitUseCase,
    required this.createHabitNotificationUseCase,
    required this.updateHabitNotificationUseCase,
    required this.deleteHabitNotificationUseCase,
  }) : super(const HabitInitial()) {
    on<LoadUserHabits>(_onLoadUserHabits);
    on<RefreshUserHabits>(_onRefreshUserHabits);
    on<LoadCategories>(_onLoadCategories);
    on<ToggleHabitCompletion>(_onToggleHabitCompletion);
    on<FilterHabitsByCategory>(_onFilterHabitsByCategory);
    on<FilterHabitsAdvanced>(_onFilterHabitsAdvanced);
    on<ScrollToFirstHabitOfCategory>(_onScrollToFirstHabitOfCategory);
    on<LoadHabitSuggestions>(_onLoadHabitSuggestions);
    on<LoadDashboardHabits>(_onLoadDashboardHabits);
    on<AddHabit>(_onAddHabit);
    on<DeleteHabit>(_onDeleteHabit);
    on<LoadUserHabitById>(_onLoadUserHabitById);
    on<UpdateUserHabit>(_onUpdateUserHabit);
    on<DeleteUserHabit>(_onDeleteUserHabit);
    
    // Notification event handlers
    on<SetupHabitNotifications>(_onSetupHabitNotifications);
    on<ToggleHabitNotifications>(_onToggleHabitNotifications);
    on<UpdateHabitNotificationTime>(_onUpdateHabitNotificationTime);
    on<RemoveHabitNotifications>(_onRemoveHabitNotifications);
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
    // Avoid loading if data is already loaded for the same user
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      if (currentState.userHabits.isNotEmpty) {
        return;
      }
    }

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

        emit(newState);
      });
    });
  }

  Future<void> _onRefreshUserHabits(
    RefreshUserHabits event,
    Emitter<HabitState> emit,
  ) async {
    // Force reload by emitting loading state first
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

        emit(newState);
      });
    });
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<HabitState> emit,
  ) async {
    // Avoid loading if categories are already loaded
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      if (currentState.categories.isNotEmpty) {
        return;
      }
    }

    final result = await getCategoriesUseCase(const NoParams());
    result.fold(
      (failure) {
        emit(HabitError(failure.toString()));
      },
      (categories) {
        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          emit(currentState.copyWith(categories: categories));
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
        }
      },
    );
  }

  Future<void> _onToggleHabitCompletion(
    ToggleHabitCompletion event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;

      // Check if this habit is already being processed to prevent double counting
      if (_processingHabits.contains(event.habitId)) {
        return; // Exit early if already processing this habit
      }

      // Add habit to processing set
      _processingHabits.add(event.habitId);

      try {
        // First, update the local state immediately for better UX
        final updatedUserHabits = currentState.userHabits.map((userHabit) {
          if (userHabit.id == event.habitId) {
            return userHabit.copyWith(
              isCompletedToday: event.isCompleted,
              completionCountToday: event.isCompleted ? 1 : 0,
              lastCompletedAt: event.isCompleted ? DateTime.now() : userHabit.lastCompletedAt,
            );
          }
          return userHabit;
        }).toList();

        // Calculate new counts
        final newPendingCount = updatedUserHabits.where((uh) => !uh.isCompletedToday).length;
        final newCompletedCount = updatedUserHabits.where((uh) => uh.isCompletedToday).length;

        // Emit the updated state immediately
        emit(
          currentState.copyWith(
            userHabits: updatedUserHabits,
            pendingCount: newPendingCount,
            completedCount: newCompletedCount,
          ),
        );

        // Then, perform the backend operation
        if (event.isCompleted) {
          final result = await logHabitCompletionUseCase(
            LogHabitCompletionParams(habitId: event.habitId, date: event.date),
          );
          result.fold(
            (failure) {
              // Revert the local state if backend operation fails
              emit(
                currentState.copyWith(
                  userHabits: currentState.userHabits,
                  pendingCount: currentState.pendingCount,
                  completedCount: currentState.completedCount,
                ),
              );
              emit(HabitError(failure.toString()));
            },
            (_) {
              // Backend operation successful, update logs if needed
              final log = HabitLog(
                userHabitId: event.habitId,
                id: event.habitId,
                completedAt: DateTime.now(),
                createdAt: DateTime.now(),
              );
              
              final updatedLogs = Map<String, List<HabitLog>>.from(
                currentState.habitLogs,
              );
              updatedLogs[event.habitId] = [
                ...updatedLogs[event.habitId] ?? [],
                log,
              ];

              // Update the current state with the new logs
              if (state is HabitLoaded) {
                final latestState = state as HabitLoaded;
                emit(latestState.copyWith(habitLogs: updatedLogs));
              }
            },
          );
        } else {
          // Handle uncompleting a habit (if needed)
          // For now, we'll just keep the local state update
        }
      } finally {
        // Always remove habit from processing set when done
        _processingHabits.remove(event.habitId);
      }
    }
  }

  void _onFilterHabitsByCategory(
    FilterHabitsByCategory event,
    Emitter<HabitState> emit,
  ) {
    final currentState = state;
    if (currentState is HabitLoaded) {
      // Find category name for debugging
      String categoryName = 'Todos';
      if (event.categoryId != null) {
        final category = currentState.categories.firstWhere(
          (cat) => cat.id == event.categoryId,
          orElse: () => Category(
            id: '',
            name: 'Unknown',
            description: '',
            iconName: '',
            color: 'gray',
          ),
        );
        categoryName = category.name;
      }

      final newState = currentState.copyWith(
        selectedCategoryId: event.categoryId,
        resetSelectedCategory: event.categoryId == null,
      );

      // If should scroll to first habit, trigger animation
      if (event.shouldScrollToFirst &&
          event.categoryId != null &&
          newState.filteredHabits.isNotEmpty) {
        final firstHabitId = newState.filteredHabits.first.id;
        emit(
          newState.copyWith(
            animationState: AnimationState.categoryChanged,
            animatedHabitId: firstHabitId,
            shouldAnimateList: true,
          ),
        );
      } else {
        emit(newState);
      }
    }
  }

  void _onFilterHabitsAdvanced(
    FilterHabitsAdvanced event,
    Emitter<HabitState> emit,
  ) {
    final currentState = state;
    if (currentState is HabitLoaded) {
      // Por ahora, solo aplicamos el filtro de categoría usando el método existente
      // Los otros filtros se pueden implementar en el futuro extendiendo el estado
      final newState = currentState.copyWith(
        selectedCategoryId: event.categoryId,
        resetSelectedCategory: event.categoryId == null,
      );

      // Si debe hacer scroll al primer hábito, activar animación
      if (event.shouldScrollToFirst && 
          event.categoryId != null &&
          newState.filteredHabits.isNotEmpty) {
        final firstHabitId = newState.filteredHabits.first.id;
        emit(
          newState.copyWith(
            animationState: AnimationState.categoryChanged,
            animatedHabitId: firstHabitId,
            shouldAnimateList: true,
          ),
        );
      } else {
        emit(newState);
      }
    }
  }

  void _onScrollToFirstHabitOfCategory(
    ScrollToFirstHabitOfCategory event,
    Emitter<HabitState> emit,
  ) {
    final currentState = state;
    if (currentState is HabitLoaded) {
      // Find the first habit of the specified category
      final categoryHabits = currentState.userHabits.where((userHabit) {
        final habit = currentState.habits.firstWhere(
          (h) => h.id == userHabit.habitId,
        );
        return habit.categoryId == event.categoryId;
      }).toList();

      if (categoryHabits.isNotEmpty) {
        final firstHabitId = categoryHabits.first.id;
        emit(
          currentState.copyWith(
            animationState: AnimationState.categoryChanged,
            animatedHabitId: firstHabitId,
            shouldAnimateList: true,
          ),
        );
      }
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

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          emit(
            currentState.copyWith(
              habitSuggestions: [],
              animationState: AnimationState.idle,
            ),
          );
        } else {
          emit(HabitError(failure.toString()));
        }
      },
      (suggestions) {

        if (state is HabitLoaded) {
          final currentState = state as HabitLoaded;
          emit(
            currentState.copyWith(
              habitSuggestions: suggestions,
              animationState: AnimationState.idle,
            ),
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
    // Avoid loading if data is already loaded for the same user
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      if (currentState.userHabits.isNotEmpty) {
        return;
      }
    }

    emit(const HabitLoading());

    final params = GetDashboardHabitsParams(userId: event.userId);
    final dashboardResult = await getDashboardHabitsUseCase(params);
    final categoriesResult = await getCategoriesUseCase(const NoParams());

    dashboardResult.fold(
      (failure) {
        emit(HabitError(failure.toString()));
      },
      (dashboardHabits) {
        categoriesResult.fold(
          (failure) {
            emit(HabitError(failure.toString()));
          },
          (categories) {

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
          },
        );
      },
    );
  }

  Future<void> _onLoadUserHabitById(
    LoadUserHabitById event,
    Emitter<HabitState> emit,
  ) async {
    emit(const UserHabitDetailLoading());

    final result = await getUserHabitByIdUseCase(event.userHabitId);

    result.fold(
      (failure) {
        emit(HabitError(failure.toString()));
      },
      (userHabit) {
        emit(UserHabitDetailLoaded(userHabit));
      },
    );
  }

  Future<void> _onUpdateUserHabit(
    UpdateUserHabit event,
    Emitter<HabitState> emit,
  ) async {
    emit(const UserHabitUpdating());

    final result = await updateUserHabitUseCase(
      UpdateUserHabitParams(
        userHabitId: event.userHabitId,
        updates: event.updates,
      ),
    );

    result.fold(
      (failure) {
        emit(HabitError(failure.toString()));
      },
      (_) {
        emit(const UserHabitUpdated());
        // Note: Manual reload may be needed after update
      },
    );
  }

  Future<void> _onDeleteUserHabit(
    DeleteUserHabit event,
    Emitter<HabitState> emit,
  ) async {
    emit(const UserHabitDeleting());

    final result = await deleteUserHabitUseCase(event.userHabitId);

    result.fold(
      (failure) {
        emit(HabitError(failure.toString()));
      },
      (_) {
        emit(const UserHabitDeleted());
        // Note: Manual reload may be needed after deletion
      },
    );
  }

  Future<void> _onSetupHabitNotifications(
    SetupHabitNotifications event,
    Emitter<HabitState> emit,
  ) async {
    try {
      // Create a habit notification
      final notification = HabitNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userHabitId: event.userHabitId,
        title: 'Recordatorio de hábito',
        message: '¡Es hora de completar tu hábito!',
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createResult = await createHabitNotificationUseCase(notification);
      
      await createResult.fold(
        (failure) async {
          emit(HabitError('Error al crear notificación: ${failure.message}'));
        },
        (createdNotification) async {
          // Schedule notifications for each day of the week
          for (final dayOfWeek in event.daysOfWeek) {
            final scheduleParams = ScheduleNotificationParams(
              scheduleId: '${createdNotification.id}_$dayOfWeek',
              habitNotificationId: createdNotification.id,
              dayOfWeek: dayOfWeek.toString(),
              scheduledTime: event.reminderTime.toString(),
              platformNotificationId: DateTime.now().millisecondsSinceEpoch,
            );

            await scheduleHabitNotificationUseCase(scheduleParams);
          }
        },
      );
    } catch (e) {
      emit(HabitError('Error al configurar notificaciones: ${e.toString()}'));
    }
  }

  Future<void> _onToggleHabitNotifications(
    ToggleHabitNotifications event,
    Emitter<HabitState> emit,
  ) async {
    try {
      if (event.enabled) {
        // If enabling, we need to create and schedule notifications
        // This would typically require more information like reminder time and days
        // For now, we'll just enable existing notifications
      } else {
        // If disabling, cancel all notifications for this habit
        await cancelAllNotificationsForHabitUseCase(event.userHabitId);
      }
    } catch (e) {
      emit(HabitError('Error al cambiar estado de notificaciones: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHabitNotificationTime(
    UpdateHabitNotificationTime event,
    Emitter<HabitState> emit,
  ) async {
    try {
      // Cancel existing notifications for this habit
      await cancelAllNotificationsForHabitUseCase(event.userHabitId);
      
      // Reschedule with new time
      // This would require getting the existing notification configuration
      // For now, we'll just show a success message
    } catch (e) {
      emit(HabitError('Error al actualizar hora de notificación: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveHabitNotifications(
    RemoveHabitNotifications event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await cancelAllNotificationsForHabitUseCase(event.userHabitId);
    } catch (e) {
      emit(HabitError('Error al eliminar notificaciones: ${e.toString()}'));
    }
  }
}
