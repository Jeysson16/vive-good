import 'package:hive/hive.dart';

import '../../domain/entities/habit_notification.dart';
import '../../domain/entities/notification_schedule.dart';

part 'habit_notification_model.g.dart';

@HiveType(typeId: 2)
class HabitNotificationModel extends HabitNotification {
  @HiveField(0)
  @override
  final String id;
  
  @HiveField(1)
  @override
  final String userHabitId;
  
  @HiveField(2)
  @override
  final String title;
  
  @HiveField(3)
  @override
  final String? message;
  
  @HiveField(4)
  @override
  final bool isEnabled;
  
  @HiveField(5)
  @override
  final String? notificationSound;
  
  @HiveField(6)
  @override
  final List<NotificationSchedule> schedules;
  
  @HiveField(7)
  @override
  final DateTime createdAt;
  
  @HiveField(8)
  @override
  final DateTime updatedAt;
  
  @HiveField(9)
  @override
  final bool isSynced;

  const HabitNotificationModel({
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
  }) : super(
          id: id,
          userHabitId: userHabitId,
          title: title,
          message: message,
          isEnabled: isEnabled,
          notificationSound: notificationSound,
          schedules: schedules,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isSynced: isSynced,
        );

  factory HabitNotificationModel.fromEntity(HabitNotification notification) {
    return HabitNotificationModel(
      id: notification.id,
      userHabitId: notification.userHabitId,
      title: notification.title,
      message: notification.message,
      isEnabled: notification.isEnabled,
      notificationSound: notification.notificationSound,
      schedules: notification.schedules,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
      isSynced: notification.isSynced,
    );
  }

  factory HabitNotificationModel.fromJson(Map<String, dynamic> json) {
    return HabitNotificationModel(
      id: json['id'] as String,
      userHabitId: json['userHabitId'] as String,
      title: json['title'] as String,
      message: json['message'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      notificationSound: json['notificationSound'] as String?,
      schedules: const [], // JSON doesn't include schedules, they're loaded separately
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userHabitId': userHabitId,
      'title': title,
      'message': message,
      'isEnabled': isEnabled,
      'notificationSound': notificationSound,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  @override
  HabitNotificationModel copyWith({
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
    return HabitNotificationModel(
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
}