import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_schedule.dart';

part 'notification_schedule_model.g.dart';

@HiveType(typeId: 3)
class NotificationScheduleModel extends NotificationSchedule {
  @HiveField(0)
  @override
  final String id;
  
  @HiveField(1)
  @override
  final String habitNotificationId;
  
  @HiveField(2)
  @override
  final String dayOfWeek;
  
  @HiveField(3)
  @override
  final String scheduledTime;
  
  @HiveField(4)
  @override
  final bool isActive;
  
  @HiveField(5)
  @override
  final int snoozeCount;
  
  @HiveField(6)
  @override
  final int platformNotificationId;

  const NotificationScheduleModel({
    required this.id,
    required this.habitNotificationId,
    required this.dayOfWeek,
    required this.scheduledTime,
    required this.isActive,
    required this.snoozeCount,
    required this.platformNotificationId,
  }) : super(
          id: id,
          habitNotificationId: habitNotificationId,
          dayOfWeek: dayOfWeek,
          scheduledTime: scheduledTime,
          isActive: isActive,
          snoozeCount: snoozeCount,
          platformNotificationId: platformNotificationId,
        );

  factory NotificationScheduleModel.fromEntity(NotificationSchedule schedule) {
    return NotificationScheduleModel(
      id: schedule.id,
      habitNotificationId: schedule.habitNotificationId,
      dayOfWeek: schedule.dayOfWeek,
      scheduledTime: schedule.scheduledTime,
      isActive: schedule.isActive,
      snoozeCount: schedule.snoozeCount,
      platformNotificationId: schedule.platformNotificationId,
    );
  }

  factory NotificationScheduleModel.fromJson(Map<String, dynamic> json) {
    return NotificationScheduleModel(
      id: json['id'] as String,
      habitNotificationId: json['habitNotificationId'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      scheduledTime: json['scheduledTime'] as String,
      isActive: json['isActive'] as bool,
      snoozeCount: json['snoozeCount'] as int,
      platformNotificationId: json['platformNotificationId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitNotificationId': habitNotificationId,
      'dayOfWeek': dayOfWeek,
      'scheduledTime': scheduledTime,
      'isActive': isActive,
      'snoozeCount': snoozeCount,
      'platformNotificationId': platformNotificationId,
    };
  }

  NotificationScheduleModel copyWith({
    String? id,
    String? habitNotificationId,
    String? dayOfWeek,
    String? scheduledTime,
    bool? isActive,
    int? snoozeCount,
    int? platformNotificationId,
  }) {
    return NotificationScheduleModel(
      id: id ?? this.id,
      habitNotificationId: habitNotificationId ?? this.habitNotificationId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      platformNotificationId: platformNotificationId ?? this.platformNotificationId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        habitNotificationId,
        dayOfWeek,
        scheduledTime,
        isActive,
        snoozeCount,
        platformNotificationId,
      ];
}