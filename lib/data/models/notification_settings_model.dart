import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_settings.dart';

part 'notification_settings_model.g.dart';

@HiveType(typeId: 4)
class NotificationSettingsModel extends NotificationSettings {
  @HiveField(0)
  @override
  final String id;
  
  @HiveField(1)
  @override
  final String userId;
  
  @HiveField(2)
  @override
  final bool globalNotificationsEnabled;
  
  @HiveField(3)
  @override
  final bool quietHoursEnabled;
  
  @HiveField(4)
  @override
  final DateTime quietHoursStart;
  
  @HiveField(5)
  @override
  final DateTime quietHoursEnd;
  
  @HiveField(6)
  @override
  final int snoozeMinutes;
  
  @HiveField(7)
  @override
  final int maxSnoozeCount;
  
  @HiveField(8)
  @override
  final String defaultSound;
  
  @HiveField(9)
  @override
  final bool vibrationEnabled;
  
  @HiveField(10)
  @override
  final int defaultPriority;
  
  @HiveField(11)
  @override
  final DateTime createdAt;
  
  @HiveField(12)
  @override
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    required this.globalNotificationsEnabled,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.snoozeMinutes,
    required this.maxSnoozeCount,
    required this.defaultSound,
    required this.vibrationEnabled,
    required this.defaultPriority,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          id: id,
          userId: userId,
          globalNotificationsEnabled: globalNotificationsEnabled,
          quietHoursEnabled: quietHoursEnabled,
          quietHoursStart: quietHoursStart,
          quietHoursEnd: quietHoursEnd,
          snoozeMinutes: snoozeMinutes,
          maxSnoozeCount: maxSnoozeCount,
          defaultSound: defaultSound,
          vibrationEnabled: vibrationEnabled,
          defaultPriority: defaultPriority,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory NotificationSettingsModel.fromEntity(NotificationSettings settings) {
    return NotificationSettingsModel(
      id: settings.id,
      userId: settings.userId,
      globalNotificationsEnabled: settings.globalNotificationsEnabled,
      quietHoursEnabled: settings.quietHoursEnabled,
      quietHoursStart: settings.quietHoursStart,
      quietHoursEnd: settings.quietHoursEnd,
      snoozeMinutes: settings.snoozeMinutes,
      maxSnoozeCount: settings.maxSnoozeCount,
      defaultSound: settings.defaultSound,
      vibrationEnabled: settings.vibrationEnabled,
      defaultPriority: settings.defaultPriority,
      createdAt: settings.createdAt,
      updatedAt: settings.updatedAt,
    );
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      globalNotificationsEnabled: json['globalNotificationsEnabled'] as bool,
      quietHoursEnabled: json['quietHoursEnabled'] as bool,
      quietHoursStart: DateTime.parse(json['quietHoursStart'] as String),
      quietHoursEnd: DateTime.parse(json['quietHoursEnd'] as String),
      snoozeMinutes: json['snoozeMinutes'] as int,
      maxSnoozeCount: json['maxSnoozeCount'] as int,
      defaultSound: json['defaultSound'] as String,
      vibrationEnabled: json['vibrationEnabled'] as bool,
      defaultPriority: json['defaultPriority'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'globalNotificationsEnabled': globalNotificationsEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart.toIso8601String(),
      'quietHoursEnd': quietHoursEnd.toIso8601String(),
      'snoozeMinutes': snoozeMinutes,
      'maxSnoozeCount': maxSnoozeCount,
      'defaultSound': defaultSound,
      'vibrationEnabled': vibrationEnabled,
      'defaultPriority': defaultPriority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    bool? globalNotificationsEnabled,
    bool? quietHoursEnabled,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
    int? snoozeMinutes,
    int? maxSnoozeCount,
    String? defaultSound,
    bool? vibrationEnabled,
    int? defaultPriority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      globalNotificationsEnabled: globalNotificationsEnabled ?? this.globalNotificationsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      defaultSound: defaultSound ?? this.defaultSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        globalNotificationsEnabled,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
        snoozeMinutes,
        maxSnoozeCount,
        defaultSound,
        vibrationEnabled,
        defaultPriority,
        createdAt,
        updatedAt,
      ];
}