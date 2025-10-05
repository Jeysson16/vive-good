import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/habit_notification.dart';

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
  final String message;
  
  @HiveField(4)
  @override
  final bool isEnabled;
  
  @HiveField(5)
  @override
  final DateTime createdAt;
  
  @HiveField(6)
  @override
  final DateTime updatedAt;

  const HabitNotificationModel({
    required this.id,
    required this.userHabitId,
    required this.title,
    required this.message,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          id: id,
          userHabitId: userHabitId,
          title: title,
          message: message,
          isEnabled: isEnabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory HabitNotificationModel.fromEntity(HabitNotification notification) {
    return HabitNotificationModel(
      id: notification.id,
      userHabitId: notification.userHabitId,
      title: notification.title,
      message: notification.message,
      isEnabled: notification.isEnabled,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
    );
  }

  factory HabitNotificationModel.fromJson(Map<String, dynamic> json) {
    return HabitNotificationModel(
      id: json['id'] as String,
      userHabitId: json['userHabitId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isEnabled: json['isEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userHabitId': userHabitId,
      'title': title,
      'message': message,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  HabitNotificationModel copyWith({
    String? id,
    String? userHabitId,
    String? title,
    String? message,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitNotificationModel(
      id: id ?? this.id,
      userHabitId: userHabitId ?? this.userHabitId,
      title: title ?? this.title,
      message: message ?? this.message,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userHabitId,
        title,
        message,
        isEnabled,
        createdAt,
        updatedAt,
      ];
}