import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/calendar_event.dart';
import '../../../core/theme/app_colors.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CalendarEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getEventColor().withOpacity(0.1),
                  _getEventColor().withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: _getEventColor().withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getEventColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          decoration: event.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ),
                    _buildTimeChip(context),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                      decoration: event.isCompleted 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.access_time,
                      label: _formatEventTime(context),
                      color: AppColors.info,
                    ),
                    if (event.location != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.location_on,
                        label: event.location!,
                        color: AppColors.secondaryOrange,
                      ),
                    ],
                    const Spacer(),
                    _buildStatusChip(),
                  ],
                ),
                if (_hasActions()) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context) {
    final timeText = _formatEventTime(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getEventColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        timeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String chipText;
    IconData chipIcon;

    if (event.isCompleted) {
      chipColor = AppColors.success;
      chipText = 'Completado';
      chipIcon = Icons.check_circle;
    } else {
      // Verificar si el evento ya pasó
      final now = DateTime.now();
      final eventDateTime = event.startTime != null 
          ? DateTime(
              event.startDate.year,
              event.startDate.month,
              event.startDate.day,
              event.startTime!.hour,
              event.startTime!.minute,
            )
          : event.startDate;
      
      if (eventDateTime.isBefore(now)) {
        chipColor = AppColors.error;
        chipText = 'Vencido';
        chipIcon = Icons.schedule_outlined;
      } else {
        chipColor = AppColors.warning;
        chipText = 'Pendiente';
        chipIcon = Icons.schedule;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onComplete != null && !event.isCompleted)
          _buildActionButton(
            icon: Icons.check,
            label: 'Completar',
            color: AppColors.success,
            onPressed: onComplete!,
          ),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.edit,
            label: 'Editar',
            color: AppColors.info,
            onPressed: onEdit!,
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.delete,
            label: 'Eliminar',
            color: AppColors.error,
            onPressed: onDelete!,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEventTime(BuildContext context) {
    if (event.startTime != null && event.endTime != null) {
      final startTime = TimeOfDay.fromDateTime(event.startTime!).format(context);
      final endTime = TimeOfDay.fromDateTime(event.endTime!).format(context);
      return '$startTime - $endTime';
    } else if (event.startTime != null) {
      return TimeOfDay.fromDateTime(event.startTime!).format(context);
    } else {
      return 'Todo el día';
    }
  }

  Color _getEventColor() {
    switch (event.eventType) {
      case 'work':
        return AppColors.secondaryBlue;
      case 'personal':
        return AppColors.primary;
      case 'health':
        return AppColors.success;
      case 'social':
        return AppColors.secondaryPurple;
      case 'education':
        return AppColors.secondaryOrange;
      default:
        return AppColors.primary;
    }
  }

  bool _hasActions() {
    return onComplete != null || onEdit != null || onDelete != null;
  }
}