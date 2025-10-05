import 'package:equatable/equatable.dart';

import '../../../domain/entities/habit_notification.dart';
import '../../../domain/entities/notification_settings.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

// Initialization Events
class InitializeNotifications extends NotificationEvent {
  final String userId;

  const InitializeNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Schedule Events
class ScheduleNotification extends NotificationEvent {
  final String habitId;
  final String title;
  final String body;
  final String scheduledTime; // Format: "HH:mm"
  final List<int> daysOfWeek; // 1-7 (Monday-Sunday)
  final bool isEnabled;

  const ScheduleNotification({
    required this.habitId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  @override
  List<Object?> get props => [
    habitId,
    title,
    body,
    scheduledTime,
    daysOfWeek,
    isEnabled,
  ];
}

class CancelNotification extends NotificationEvent {
  final String notificationId;

  const CancelNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ScheduleHabitNotification extends NotificationEvent {
  final String habitId;
  final DateTime scheduledTime;
  final List<int> daysOfWeek;
  final String message;

  const ScheduleHabitNotification({
    required this.habitId,
    required this.scheduledTime,
    required this.daysOfWeek,
    required this.message,
  });

  @override
  List<Object?> get props => [habitId, scheduledTime, daysOfWeek, message];
}

class CancelHabitNotification extends NotificationEvent {
  final String notificationId;

  const CancelHabitNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class SnoozeNotification extends NotificationEvent {
  final String scheduleId;
  final int snoozeMinutes;

  const SnoozeNotification({
    required this.scheduleId,
    required this.snoozeMinutes,
  });

  @override
  List<Object?> get props => [scheduleId, snoozeMinutes];
}

class LoadPendingNotifications extends NotificationEvent {}

// Habit Notification Events
class UpdateHabitNotificationEvent extends NotificationEvent {
  final HabitNotification notification;

  const UpdateHabitNotificationEvent(this.notification);

  @override
  List<Object?> get props => [notification];
}

class LoadSchedulesByNotification extends NotificationEvent {
  final String notificationId;

  const LoadSchedulesByNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// Settings Events
class LoadNotificationSettings extends NotificationEvent {
  final String userId;

  const LoadNotificationSettings(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateNotificationSettings extends NotificationEvent {
  final NotificationSettings settings;

  const UpdateNotificationSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

// Permission Events
class RequestNotificationPermissions extends NotificationEvent {}

class CheckNotificationPermissions extends NotificationEvent {}

// Utility Events
class ClearNotificationErrors extends NotificationEvent {}
