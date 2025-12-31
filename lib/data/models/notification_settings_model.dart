import 'package:hive/hive.dart';

import '../../domain/entities/notification_settings.dart';

part 'notification_settings_model.g.dart';

@HiveType(typeId: 4)
class NotificationSettingsModel extends NotificationSettings {
  @HiveField(0)
  @override
  final String userId;
  
  @HiveField(1)
  @override
  final bool globalNotificationsEnabled;
  
  @HiveField(2)
  @override
  final bool permissionsGranted;
  
  @HiveField(3)
  @override
  final String? quietHoursStart;
  
  @HiveField(4)
  @override
  final String? quietHoursEnd;
  
  @HiveField(5)
  @override
  final int defaultSnoozeMinutes;
  
  @HiveField(6)
  @override
  final int maxSnoozeCount;
  
  @HiveField(7)
  @override
  final String defaultNotificationSound;
  
  @HiveField(8)
  @override
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.userId,
    this.globalNotificationsEnabled = true,
    this.permissionsGranted = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.defaultSnoozeMinutes = 15,
    this.maxSnoozeCount = 3,
    this.defaultNotificationSound = 'default',
    required this.updatedAt,
  }) : super(
          userId: userId,
          globalNotificationsEnabled: globalNotificationsEnabled,
          permissionsGranted: permissionsGranted,
          quietHoursStart: quietHoursStart,
          quietHoursEnd: quietHoursEnd,
          defaultSnoozeMinutes: defaultSnoozeMinutes,
          maxSnoozeCount: maxSnoozeCount,
          defaultNotificationSound: defaultNotificationSound,
          updatedAt: updatedAt,
        );

  factory NotificationSettingsModel.fromEntity(NotificationSettings settings) {
    return NotificationSettingsModel(
      userId: settings.userId,
      globalNotificationsEnabled: settings.globalNotificationsEnabled,
      permissionsGranted: settings.permissionsGranted,
      quietHoursStart: settings.quietHoursStart,
      quietHoursEnd: settings.quietHoursEnd,
      defaultSnoozeMinutes: settings.defaultSnoozeMinutes,
      maxSnoozeCount: settings.maxSnoozeCount,
      defaultNotificationSound: settings.defaultNotificationSound,
      updatedAt: settings.updatedAt,
    );
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      userId: json['userId'] as String,
      globalNotificationsEnabled: json['globalNotificationsEnabled'] as bool? ?? true,
      permissionsGranted: json['permissionsGranted'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String?,
      quietHoursEnd: json['quietHoursEnd'] as String?,
      defaultSnoozeMinutes: json['defaultSnoozeMinutes'] as int? ?? 15,
      maxSnoozeCount: json['maxSnoozeCount'] as int? ?? 3,
      defaultNotificationSound: json['defaultNotificationSound'] as String? ?? 'default',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'globalNotificationsEnabled': globalNotificationsEnabled,
      'permissionsGranted': permissionsGranted,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'defaultSnoozeMinutes': defaultSnoozeMinutes,
      'maxSnoozeCount': maxSnoozeCount,
      'defaultNotificationSound': defaultNotificationSound,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  NotificationSettingsModel copyWith({
    String? userId,
    bool? globalNotificationsEnabled,
    bool? permissionsGranted,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? defaultSnoozeMinutes,
    int? maxSnoozeCount,
    String? defaultNotificationSound,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      globalNotificationsEnabled: globalNotificationsEnabled ?? this.globalNotificationsEnabled,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      defaultNotificationSound: defaultNotificationSound ?? this.defaultNotificationSound,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        globalNotificationsEnabled,
        permissionsGranted,
        quietHoursStart,
        quietHoursEnd,
        defaultSnoozeMinutes,
        maxSnoozeCount,
        defaultNotificationSound,
        updatedAt,
      ];
}