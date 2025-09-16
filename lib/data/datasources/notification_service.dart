import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  Future<bool> requestPermissions();
}

class NotificationServiceImpl implements NotificationService {
  static final NotificationServiceImpl _instance = NotificationServiceImpl._internal();
  factory NotificationServiceImpl() => _instance;
  NotificationServiceImpl._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    print('Notification tapped: ${notificationResponse.payload}');
  }

  @override
  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'habit_reminders',
        'Recordatorios de Hábitos',
        channelDescription: 'Notificaciones para recordar tus hábitos',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required DateTime reminderTime,
    int minutesBefore = 15,
  }) async {
    final notificationTime = reminderTime.subtract(Duration(minutes: minutesBefore));
    
    // Use habit ID hash as notification ID to ensure uniqueness
    final notificationId = habitId.hashCode;
    
    await scheduleNotification(
      id: notificationId,
      title: '¡Es hora de tu hábito!',
      body: 'Recordatorio: $habitName en $minutesBefore minutos',
      scheduledDate: notificationTime,
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    final notificationId = habitId.hashCode;
    await cancelNotification(notificationId);
  }
}