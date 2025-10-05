import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/usecases/usecase.dart';

import '../../../domain/entities/habit_notification.dart';
import '../../../domain/entities/notification_log.dart' as log;
import '../../../domain/entities/notification_schedule.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../../domain/usecases/notifications/cancel_habit_notification_usecase.dart';
import '../../../domain/usecases/notifications/check_notification_permissions_usecase.dart';
import '../../../domain/usecases/notifications/get_notification_settings_usecase.dart';
import '../../../domain/usecases/notifications/get_pending_notifications_usecase.dart';
import '../../../domain/usecases/notifications/get_schedules_by_notification_id_usecase.dart';
import '../../../domain/usecases/notifications/request_notification_permissions_usecase.dart';
import '../../../domain/usecases/notifications/schedule_habit_notification_usecase.dart';
import '../../../domain/usecases/notifications/snooze_notification_usecase.dart';
import '../../../domain/usecases/notifications/update_habit_notification_usecase.dart';
import '../../../domain/usecases/notifications/update_notification_settings_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ScheduleHabitNotificationUseCase scheduleHabitNotificationUseCase;
  final CancelHabitNotificationUseCase cancelHabitNotificationUseCase;
  final SnoozeNotificationUseCase snoozeNotificationUseCase;
  final GetPendingNotificationsUseCase getPendingNotificationsUseCase;
  final UpdateHabitNotificationUseCase updateHabitNotificationUseCase;
  final GetSchedulesByNotificationIdUseCase getSchedulesByNotificationIdUseCase;
  final GetNotificationSettingsUseCase getNotificationSettingsUseCase;
  final UpdateNotificationSettingsUseCase updateNotificationSettingsUseCase;
  final RequestNotificationPermissionsUseCase
  requestNotificationPermissionsUseCase;
  final CheckNotificationPermissionsUseCase checkNotificationPermissionsUseCase;

  NotificationBloc({
    required this.scheduleHabitNotificationUseCase,
    required this.cancelHabitNotificationUseCase,
    required this.snoozeNotificationUseCase,
    required this.getPendingNotificationsUseCase,
    required this.updateHabitNotificationUseCase,
    required this.getSchedulesByNotificationIdUseCase,
    required this.getNotificationSettingsUseCase,
    required this.updateNotificationSettingsUseCase,
    required this.requestNotificationPermissionsUseCase,
    required this.checkNotificationPermissionsUseCase,
  }) : super(const NotificationState()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<ScheduleNotification>(_onScheduleNotification);
    on<CancelNotification>(_onCancelNotification);
    on<SnoozeNotification>(_onSnoozeNotification);
    on<LoadPendingNotifications>(_onLoadPendingNotifications);
    on<UpdateHabitNotificationEvent>(_onUpdateHabitNotification);
    on<LoadSchedulesByNotification>(_onLoadSchedulesByNotification);
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<RequestNotificationPermissions>(_onRequestNotificationPermissions);
    on<CheckNotificationPermissions>(_onCheckNotificationPermissions);
    on<ClearNotificationErrors>(_onClearNotificationErrors);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      // Check permissions first
      final permissionsResult = await checkNotificationPermissionsUseCase(NoParams());

      await permissionsResult.fold(
        (failure) async {
          emit(
            state.copyWith(
              status: NotificationStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
        (hasPermissions) async {
          if (!hasPermissions) {
            emit(
              state.copyWith(
                status: NotificationStatus.permissionDenied,
                hasPermissions: false,
              ),
            );
            return;
          }

          // Load settings
          final settingsResult = await getNotificationSettingsUseCase(
            GetNotificationSettingsParams(userId: event.userId),
          );

          await settingsResult.fold(
            (failure) async {
              emit(
                state.copyWith(
                  status: NotificationStatus.error,
                  errorMessage: failure.message,
                ),
              );
            },
            (settings) async {
              // Load pending notifications
              final pendingResult = await getPendingNotificationsUseCase();

              await pendingResult.fold(
                (failure) async {
                  emit(
                    state.copyWith(
                      status: NotificationStatus.error,
                      errorMessage: failure.message,
                    ),
                  );
                },
                (pendingSchedules) async {
                  emit(
                    state.copyWith(
                      status: NotificationStatus.loaded,
                      notificationSchedules: pendingSchedules,
                      settings: settings,
                      hasPermissions: true,
                      isInitialized: true,
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to initialize notifications: $e',
        ),
      );
    }
  }

  Future<void> _onScheduleNotification(
    ScheduleNotification event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await scheduleHabitNotificationUseCase(
        ScheduleNotificationParams(
          scheduleId: DateTime.now().millisecondsSinceEpoch.toString(),
          habitNotificationId: event.habitId,
          dayOfWeek: event.daysOfWeek.join(','),
          scheduledTime: event.scheduledTime,
          message: event.body,
          platformNotificationId: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (notification) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            successMessage: 'Notification scheduled successfully',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to schedule notification: $e',
        ),
      );
    }
  }

  Future<void> _onCancelNotification(
    CancelNotification event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await cancelHabitNotificationUseCase(event.notificationId);

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (_) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            successMessage: 'Notification cancelled successfully',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to cancel notification: $e',
        ),
      );
    }
  }

  Future<void> _onSnoozeNotification(
    SnoozeNotification event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await snoozeNotificationUseCase(
        SnoozeNotificationParams(
          notificationId: event.scheduleId,
          snoozeMinutes: event.snoozeMinutes,
        ),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (newSchedule) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            successMessage:
                'Notification snoozed for ${event.snoozeMinutes} minutes',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to snooze notification: $e',
        ),
      );
    }
  }

  Future<void> _onLoadPendingNotifications(
    LoadPendingNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await getPendingNotificationsUseCase();

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (schedules) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            notificationSchedules: schedules,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to load pending notifications: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateHabitNotification(
    UpdateHabitNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await updateHabitNotificationUseCase(
        UpdateHabitNotificationParams(notification: event.notification),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (notification) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            successMessage: 'Notification updated successfully',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to update notification: $e',
        ),
      );
    }
  }

  Future<void> _onLoadSchedulesByNotification(
    LoadSchedulesByNotification event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await getSchedulesByNotificationIdUseCase(
        GetSchedulesByNotificationIdParams(notificationId: event.notificationId),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (schedules) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            notificationSchedules: schedules,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to load schedules: $e',
        ),
      );
    }
  }

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await getNotificationSettingsUseCase(
        GetNotificationSettingsParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (settings) => emit(
          state.copyWith(status: NotificationStatus.loaded, settings: settings),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to load notification settings: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettings event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await updateNotificationSettingsUseCase(
        UpdateNotificationSettingsParams(settings: event.settings),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (settings) => emit(
          state.copyWith(
            status: NotificationStatus.loaded,
            settings: settings,
            successMessage: 'Settings updated successfully',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to update settings: $e',
        ),
      );
    }
  }

  Future<void> _onRequestNotificationPermissions(
    RequestNotificationPermissions event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      final result = await requestNotificationPermissionsUseCase(NoParams());

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (granted) => emit(
          state.copyWith(
            status: granted
                ? NotificationStatus.loaded
                : NotificationStatus.permissionDenied,
            hasPermissions: granted,
            successMessage: granted ? 'Permissions granted' : null,
            errorMessage: granted ? null : 'Permissions denied',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to request permissions: $e',
        ),
      );
    }
  }

  Future<void> _onCheckNotificationPermissions(
    CheckNotificationPermissions event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result = await checkNotificationPermissionsUseCase(NoParams());

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (hasPermissions) => emit(
          state.copyWith(
            hasPermissions: hasPermissions,
            status: hasPermissions
                ? state.status
                : NotificationStatus.permissionDenied,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: 'Failed to check permissions: $e',
        ),
      );
    }
  }

  void _onClearNotificationErrors(
    ClearNotificationErrors event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
