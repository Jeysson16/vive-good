import 'package:equatable/equatable.dart';

import '../../../domain/entities/notification_schedule.dart';
import '../../../domain/entities/notification_settings.dart';

enum NotificationStatus { initial, loading, loaded, error, permissionDenied }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationSchedule> notificationSchedules;
  final NotificationSettings? settings;
  final bool hasPermissions;
  final bool isInitialized;
  final String? errorMessage;
  final String? successMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notificationSchedules = const [],
    this.settings,
    this.hasPermissions = false,
    this.isInitialized = false,
    this.errorMessage,
    this.successMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationSchedule>? notificationSchedules,
    NotificationSettings? settings,
    bool? hasPermissions,
    bool? isInitialized,
    String? errorMessage,
    String? successMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notificationSchedules:
          notificationSchedules ?? this.notificationSchedules,
      settings: settings ?? this.settings,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    notificationSchedules,
    settings,
    hasPermissions,
    isInitialized,
    errorMessage,
    successMessage,
  ];
}
