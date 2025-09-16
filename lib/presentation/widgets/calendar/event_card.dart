import 'package:flutter/material.dart';

import '../../../domain/entities/calendar_event.dart';

class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: event.isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Event status indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: event.isCompleted
                            ? Colors.green
                            : _getEventTypeColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Event title
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: event.isCompleted
                              ? Colors.grey[600]
                              : Colors.black87,
                          decoration: event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!event.isCompleted && onComplete != null)
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 20,
                            ),
                            onPressed: onComplete,
                            tooltip: 'Marcar como completado',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: onDelete,
                            tooltip: 'Eliminar evento',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (event.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Event details row
                Row(
                  children: [
                    // Time
                    if (event.startTime != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimeOfDay.fromDateTime(
                          event.startTime!,
                        ).format(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    // Recurrence indicator
                    if (event.recurrenceType != null &&
                        event.recurrenceType != 'none') ...[
                      Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _getRecurrenceText(event.recurrenceType!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    // Notification indicator
                    if (event.notificationEnabled) ...[
                      Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.notificationMinutes ?? 15} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.isCompleted ? 'Completado' : 'Pendiente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: event.isCompleted
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventTypeColor() {
    // You can customize colors based on event type or habit category
    if (event.habitId != null) {
      return const Color(0xFF4CAF50); // Green for habit events
    }
    return const Color(0xFF2196F3); // Blue for regular events
  }

  String _getRecurrenceText(String recurrenceType) {
    switch (recurrenceType.toLowerCase()) {
      case 'daily':
      case 'diario':
        return 'Diario';
      case 'weekly':
      case 'semanal':
        return 'Semanal';
      case 'monthly':
      case 'mensual':
        return 'Mensual';
      default:
        return recurrenceType;
    }
  }
}
