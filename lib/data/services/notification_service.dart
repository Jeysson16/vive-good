import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/calendar_event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
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

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Maneja cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navegar a la pantalla correspondiente
    print('Notificación tocada: ${response.payload}');
  }

  /// Solicita permisos de notificación
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation
          .requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }

    return false;
  }

  /// Programa una notificación para un evento
  Future<void> scheduleEventNotification(
    CalendarEvent event, {
    Duration? reminderBefore,
  }) async {
    if (!_isInitialized) await initialize();

    final reminderTime = reminderBefore ?? const Duration(minutes: 15);
    final notificationTime = _getEventDateTime(event).subtract(reminderTime);

    // No programar notificaciones para eventos pasados
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'calendar_events',
      'Eventos de Calendario',
      channelDescription: 'Recordatorios de eventos y actividades',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      event.id.hashCode,
      _getNotificationTitle(event),
      _getNotificationBody(event, reminderTime),
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: event.id,
    );

    // Guardar notificación en la base de datos
    await _saveNotificationToDatabase(
      event.id,
      event.userId,
      _getNotificationTitle(event),
      _getNotificationBody(event, reminderTime),
      notificationTime,
    );
  }

  /// Programa notificaciones para eventos recurrentes
  Future<void> scheduleRecurringNotifications(
    CalendarEvent event, {
    Duration? reminderBefore,
    int maxOccurrences = 50,
  }) async {
    if (event.recurrenceType == 'none') {
      await scheduleEventNotification(event, reminderBefore: reminderBefore);
      return;
    }

    final reminderTime = reminderBefore ?? const Duration(minutes: 15);
    var currentDate = event.startDate;
    var occurrences = 0;
    final endDate = event.recurrenceEndDate ?? 
        DateTime.now().add(const Duration(days: 365));

    while (currentDate.isBefore(endDate) && occurrences < maxOccurrences) {
      final eventDateTime = _getEventDateTimeForDate(event, currentDate);
      final notificationTime = eventDateTime.subtract(reminderTime);

      if (notificationTime.isAfter(DateTime.now())) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'recurring_events',
          'Eventos Recurrentes',
          channelDescription: 'Recordatorios de eventos recurrentes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.zonedSchedule(
          '${event.id}_$occurrences'.hashCode,
          _getNotificationTitle(event),
          _getNotificationBody(event, reminderTime),
          tz.TZDateTime.from(notificationTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: event.id,
        );

        // Guardar notificación en la base de datos
        await _saveNotificationToDatabase(
          '${event.id}_$occurrences',
          event.userId,
          _getNotificationTitle(event),
          _getNotificationBody(event, reminderTime),
          notificationTime,
        );
      }

      // Calcular siguiente fecha
      currentDate = _getNextRecurrenceDate(event, currentDate);
      occurrences++;
    }
  }

  /// Cancela una notificación específica
  Future<void> cancelNotification(String eventId) async {
    await _notifications.cancel(eventId.hashCode);
    
    // Eliminar de la base de datos
    await _supabase
        .from('notifications')
        .delete()
        .eq('event_id', eventId);
  }

  /// Cancela todas las notificaciones de un evento recurrente
  Future<void> cancelRecurringNotifications(String eventId) async {
    // Cancelar notificaciones locales (aproximación)
    for (int i = 0; i < 50; i++) {
      await _notifications.cancel('${eventId}_$i'.hashCode);
    }
    
    // Eliminar de la base de datos
    await _supabase
        .from('notifications')
        .delete()
        .like('notification_id', '$eventId%');
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    
    // Eliminar todas las notificaciones del usuario de la base de datos
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    }
  }

  /// Muestra una notificación inmediata
  Future<void> showImmediateNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'immediate',
      'Notificaciones Inmediatas',
      channelDescription: 'Notificaciones que se muestran inmediatamente',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Obtiene las notificaciones activas
  Future<List<ActiveNotification>> getActiveNotifications() async {
    return await _notifications.getActiveNotifications();
  }

  /// Obtiene notificaciones de la base de datos
  Future<List<Map<String, dynamic>>> getNotificationsFromDatabase(
    String userId, {
    bool? isRead,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (startDate != null) {
        query = query.gte('scheduled_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('scheduled_at', endDate.toIso8601String());
      }

      final response = await query.order('scheduled_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ServerException('Error al obtener notificaciones de la base de datos: $e');
    }
  }

  /// Marca una notificación como leída
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException('Error al marcar notificación como leída: $e');
    }
  }

  /// Métodos auxiliares privados
  
  DateTime _getEventDateTime(CalendarEvent event) {
    if (event.startTime != null) {
      return event.startTime!;
    }
    
    return event.startDate;
  }

  DateTime _getEventDateTimeForDate(CalendarEvent event, DateTime date) {
    if (event.startTime != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        event.startTime!.hour,
        event.startTime!.minute,
      );
    }
    
    return date;
  }

  DateTime _getNextRecurrenceDate(CalendarEvent event, DateTime currentDate) {
    switch (event.recurrenceType) {
      case 'daily':
        return currentDate.add(const Duration(days: 1));
      case 'weekly':
        return currentDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          currentDate.month == 12 ? currentDate.year + 1 : currentDate.year,
          currentDate.month == 12 ? 1 : currentDate.month + 1,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      case 'yearly':
        return DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      default:
        return currentDate;
    }
  }

  String _getNotificationTitle(CalendarEvent event) {
    switch (event.eventType) {
      case 'habit':
        return '🔄 Recordatorio de Hábito';
      case 'activity':
        return '📅 Actividad Programada';
      case 'reminder':
        return '⏰ Recordatorio';
      case 'appointment':
        return '📋 Cita Programada';
      default:
        return '📌 Evento';
    }
  }

  String _getNotificationBody(CalendarEvent event, Duration reminderTime) {
    final timeText = _formatReminderTime(reminderTime);
    return '${event.title} - Comienza en $timeText';
  }

  String _formatReminderTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} día${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hora${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  Future<void> _saveNotificationToDatabase(
    String notificationId,
    String userId,
    String title,
    String body,
    DateTime scheduledAt,
  ) async {
    try {
      await _supabase.from('notifications').insert({
        'id': notificationId,
        'user_id': userId,
        'event_id': notificationId.split('_')[0],
        'title': title,
        'body': body,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking notification scheduling
      print('Error al guardar notificación en base de datos: $e');
    }
  }
}