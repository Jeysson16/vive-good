import 'package:hive/hive.dart';

import '../models/habit_notification_model.dart';
import '../models/notification_log_model.dart';
import '../models/notification_schedule_model.dart';
import '../models/notification_settings_model.dart';

abstract class NotificationLocalDataSource {
  // Habit Notifications
  Future<void> saveHabitNotification(HabitNotificationModel notification);
  Future<HabitNotificationModel?> getHabitNotification(String id);
  Future<List<HabitNotificationModel>> getAllHabitNotifications();
  Future<List<HabitNotificationModel>> getHabitNotificationsByUserHabitId(
    String userHabitId,
  );
  Future<void> deleteHabitNotification(String id);
  Future<void> updateHabitNotification(HabitNotificationModel notification);

  // Notification Schedules
  Future<void> saveNotificationSchedule(NotificationScheduleModel schedule);
  Future<NotificationScheduleModel?> getNotificationSchedule(String id);
  Future<List<NotificationScheduleModel>> getAllNotificationSchedules();
  Future<List<NotificationScheduleModel>> getSchedulesByNotificationId(
    String notificationId,
  );
  Future<List<NotificationScheduleModel>> getActiveSchedules();
  Future<void> deleteNotificationSchedule(String id);
  Future<void> updateNotificationSchedule(NotificationScheduleModel schedule);

  // Notification Logs
  Future<void> saveNotificationLog(NotificationLogModel log);
  Future<List<NotificationLogModel>> getAllNotificationLogs();
  Future<List<NotificationLogModel>> getLogsByNotificationId(
    String notificationId,
  );
  Future<void> deleteNotificationLog(String id);
  Future<void> clearAllLogs();

  // Notification Settings
  Future<void> saveNotificationSettings(NotificationSettingsModel settings);
  Future<NotificationSettingsModel?> getNotificationSettings(String userId);
  Future<void> updateNotificationSettings(NotificationSettingsModel settings);
  Future<void> deleteNotificationSettings(String userId);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  static const String _habitNotificationsBox = 'habit_notifications';
  static const String _notificationSchedulesBox = 'notification_schedules';
  static const String _notificationLogsBox = 'notification_logs';
  static const String _notificationSettingsBox = 'notification_settings';

  // Habit Notifications
  @override
  Future<void> saveHabitNotification(
    HabitNotificationModel notification,
  ) async {
    final box = await Hive.openBox<HabitNotificationModel>(
      _habitNotificationsBox,
    );
    await box.put(notification.id, notification);
  }

  @override
  Future<HabitNotificationModel?> getHabitNotification(String id) async {
    final box = await Hive.openBox<HabitNotificationModel>(
      _habitNotificationsBox,
    );
    return box.get(id);
  }

  @override
  Future<List<HabitNotificationModel>> getAllHabitNotifications() async {
    final box = await Hive.openBox<HabitNotificationModel>(
      _habitNotificationsBox,
    );
    return box.values.toList();
  }

  @override
  Future<List<HabitNotificationModel>> getHabitNotificationsByUserHabitId(
    String userHabitId,
  ) async {
    final box = await Hive.openBox<HabitNotificationModel>(
      _habitNotificationsBox,
    );
    return box.values
        .where((notification) => notification.userHabitId == userHabitId)
        .toList();
  }

  @override
  Future<void> deleteHabitNotification(String id) async {
    final box = await Hive.openBox<HabitNotificationModel>(
      _habitNotificationsBox,
    );
    await box.delete(id);
  }

  @override
  Future<void> updateHabitNotification(
    HabitNotificationModel notification,
  ) async {
    final box = await Hive.openBox<HabitNotificationModel>(
      _habitNotificationsBox,
    );
    await box.put(notification.id, notification);
  }

  // Notification Schedules
  @override
  Future<void> saveNotificationSchedule(
    NotificationScheduleModel schedule,
  ) async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    await box.put(schedule.id, schedule);
  }

  @override
  Future<NotificationScheduleModel?> getNotificationSchedule(String id) async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    return box.get(id);
  }

  @override
  Future<List<NotificationScheduleModel>> getAllNotificationSchedules() async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    return box.values.toList();
  }

  @override
  Future<List<NotificationScheduleModel>> getSchedulesByNotificationId(
    String notificationId,
  ) async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    return box.values
        .where((schedule) => schedule.habitNotificationId == notificationId)
        .toList();
  }

  @override
  Future<List<NotificationScheduleModel>> getActiveSchedules() async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    return box.values.where((schedule) => schedule.isActive).toList();
  }

  @override
  Future<void> deleteNotificationSchedule(String id) async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    await box.delete(id);
  }

  @override
  Future<void> updateNotificationSchedule(
    NotificationScheduleModel schedule,
  ) async {
    final box = await Hive.openBox<NotificationScheduleModel>(
      _notificationSchedulesBox,
    );
    await box.put(schedule.id, schedule);
  }

  // Notification Logs
  @override
  Future<void> saveNotificationLog(NotificationLogModel log) async {
    final box = await Hive.openBox<NotificationLogModel>(_notificationLogsBox);
    await box.put(log.id, log);
  }

  @override
  Future<List<NotificationLogModel>> getAllNotificationLogs() async {
    final box = await Hive.openBox<NotificationLogModel>(_notificationLogsBox);
    return box.values.toList();
  }

  @override
  Future<List<NotificationLogModel>> getLogsByNotificationId(
    String notificationId,
  ) async {
    final box = await Hive.openBox<NotificationLogModel>(_notificationLogsBox);
    return box.values
        .where((log) => log.notificationId == notificationId)
        .toList();
  }

  @override
  Future<void> deleteNotificationLog(String id) async {
    final box = await Hive.openBox<NotificationLogModel>(_notificationLogsBox);
    await box.delete(id);
  }

  @override
  Future<void> clearAllLogs() async {
    final box = await Hive.openBox<NotificationLogModel>(_notificationLogsBox);
    await box.clear();
  }

  // Notification Settings
  @override
  Future<void> saveNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    final box = await Hive.openBox<NotificationSettingsModel>(
      _notificationSettingsBox,
    );
    await box.put(settings.userId, settings);
  }

  @override
  Future<NotificationSettingsModel?> getNotificationSettings(
    String userId,
  ) async {
    final box = await Hive.openBox<NotificationSettingsModel>(
      _notificationSettingsBox,
    );
    return box.get(userId);
  }

  @override
  Future<void> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    final box = await Hive.openBox<NotificationSettingsModel>(
      _notificationSettingsBox,
    );
    await box.put(settings.userId, settings);
  }

  @override
  Future<void> deleteNotificationSettings(String userId) async {
    final box = await Hive.openBox<NotificationSettingsModel>(
      _notificationSettingsBox,
    );
    await box.delete(userId);
  }
}
