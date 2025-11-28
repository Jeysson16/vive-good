import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/habit_notification.dart';

abstract class NotificationRemoteDataSource {
  Future<void> createHabitNotification(HabitNotification notification, String userId);
  Future<void> updateHabitNotification(HabitNotification notification, String userId);
  Future<void> deleteHabitNotification(String notificationId);
  Future<List<HabitNotification>> getHabitNotifications(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  NotificationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> createHabitNotification(HabitNotification notification, String userId) async {
    try {
      await supabaseClient.from('notifications').insert({
        'id': notification.id,
        'user_id': userId,
        'title': notification.title,
        'body': notification.message,
        'type': 'habit_reminder',
        'related_id': notification.userHabitId,
        'data': {
          'user_habit_id': notification.userHabitId,
          'is_enabled': notification.isEnabled,
          'notification_sound': notification.notificationSound,
        },
        'is_read': false,
        'created_at': notification.createdAt.toIso8601String(),
        'updated_at': notification.updatedAt.toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Error al crear notificación en Supabase: $e');
    }
  }

  @override
  Future<void> updateHabitNotification(HabitNotification notification, String userId) async {
    try {
      await supabaseClient.from('notifications').update({
        'title': notification.title,
        'body': notification.message,
        'data': {
          'user_habit_id': notification.userHabitId,
          'is_enabled': notification.isEnabled,
          'notification_sound': notification.notificationSound,
        },
        'updated_at': notification.updatedAt.toIso8601String(),
      }).eq('id', notification.id);
    } catch (e) {
      throw ServerException('Error al actualizar notificación en Supabase: $e');
    }
  }

  @override
  Future<void> deleteHabitNotification(String notificationId) async {
    try {
      await supabaseClient
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException('Error al eliminar notificación en Supabase: $e');
    }
  }

  @override
  Future<List<HabitNotification>> getHabitNotifications(String userId) async {
    try {
      final response = await supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', 'habit_reminder');

      return response.map<HabitNotification>((json) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        return HabitNotification(
          id: json['id'],
          userHabitId: data['user_habit_id'] ?? json['related_id'],
          title: json['title'],
          message: json['body'] ?? '',
          isEnabled: data['is_enabled'] ?? true,
          notificationSound: data['notification_sound'],
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
    } catch (e) {
      throw ServerException('Error al obtener notificaciones de Supabase: $e');
    }
  }
}