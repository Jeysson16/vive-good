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
  final DateTime? lastTriggered;
  
  @HiveField(7)
  @override
  final int platformNotificationId;

  const NotificationScheduleModel({
    required this.id,
    required this.habitNotificationId,
    required this.dayOfWeek,
    required this.scheduledTime,
    this.isActive = true,
    this.snoozeCount = 0,
    this.lastTriggered,
    required this.platformNotificationId,
  }) : super(
          id: id,
          habitNotificationId: habitNotificationId,
          dayOfWeek: dayOfWeek,
          scheduledTime: scheduledTime,
          isActive: isActive,
          snoozeCount: snoozeCount,
          lastTriggered: lastTriggered,
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
      lastTriggered: schedule.lastTriggered,
      platformNotificationId: schedule.platformNotificationId,
    );
  }

  factory NotificationScheduleModel.fromJson(Map<String, dynamic> json) {
    return NotificationScheduleModel(
      id: json['id'] as String,
      habitNotificationId: json['habitNotificationId'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      scheduledTime: json['scheduledTime'] as String,
      isActive: json['isActive'] as bool? ?? true,
      snoozeCount: json['snoozeCount'] as int? ?? 0,
      lastTriggered: json['lastTriggered'] != null 
        ? DateTime.parse(json['lastTriggered'] as String) 
        : null,
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
      'lastTriggered': lastTriggered?.toIso8601String(),
      'platformNotificationId': platformNotificationId,
    };
  }

  @override
  NotificationScheduleModel copyWith({
    String? id,
    String? habitNotificationId,
    String? dayOfWeek,
    String? scheduledTime,
    bool? isActive,
    int? snoozeCount,
    DateTime? lastTriggered,
    int? platformNotificationId,
  }) {
    return NotificationScheduleModel(
      id: id ?? this.id,
      habitNotificationId: habitNotificationId ?? this.habitNotificationId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastTriggered: lastTriggered ?? this.lastTriggered,
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
        lastTriggered,
        platformNotificationId,
      ];
}