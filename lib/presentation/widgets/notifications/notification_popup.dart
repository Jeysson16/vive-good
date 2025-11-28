import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_event.dart';

class NotificationPopup extends StatelessWidget {
  final String notificationId;
  final String habitName;
  final String message;
  final VoidCallback? onCompleted;
  final VoidCallback? onDismissed;

  const NotificationPopup({
    super.key,
    required this.notificationId,
    required this.habitName,
    required this.message,
    this.onCompleted,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recordatorio de Hábito',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismissed?.call();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habitName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<NotificationBloc>().add(
                              SnoozeNotification(
                                scheduleId: notificationId,
                                snoozeMinutes: 5,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.snooze),
                          label: const Text('Posponer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onCompleted?.call();
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Completado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String notificationId,
    required String habitName,
    required String message,
    VoidCallback? onCompleted,
    VoidCallback? onDismissed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => NotificationPopup(
        notificationId: notificationId,
        habitName: habitName,
        message: message,
        onCompleted: onCompleted,
        onDismissed: onDismissed,
      ),
    );
  }
}