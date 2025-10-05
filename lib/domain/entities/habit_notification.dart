import 'package:equatable/equatable.dart';
import 'notification_schedule.dart';

class HabitNotification extends Equatable {
  final String id;
  final String userHabitId;
  final String title;
  final String? message;
  final bool isEnabled;
  final String? notificationSound;
  final List<NotificationSchedule> schedules;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const HabitNotification({
    required this.id,
    required this.userHabitId,
    required this.title,
    this.message,
    this.isEnabled = true,
    this.notificationSound,
    this.schedules = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
        id,
        userHabitId,
        title,
        message,
        isEnabled,
        notificationSound,
        schedules,
        createdAt,
        updatedAt,
        isSynced,
      ];

  HabitNotification copyWith({
    String? id,
    String? userHabitId,
    String? title,
    String? message,
    bool? isEnabled,
    String? notificationSound,
    List<NotificationSchedule>? schedules,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return HabitNotification(
      id: id ?? this.id,
      userHabitId: userHabitId ?? this.userHabitId,
      title: title ?? this.title,
      message: message ?? this.message,
      isEnabled: isEnabled ?? this.isEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      schedules: schedules ?? this.schedules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'HabitNotification(id: $id, userHabitId: $userHabitId, title: $title, isEnabled: $isEnabled)';
  }
}