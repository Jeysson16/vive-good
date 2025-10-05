import 'package:flutter/material.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/category.dart';

class CompactHabitItem extends StatelessWidget {
  final UserHabit userHabit;
  final Habit habit;
  final Category category;
  final bool isCompleted;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onHighlightComplete;
  final Function(UserHabit)? onEdit;
  final Function(UserHabit)? onViewProgress;
  final Function(UserHabit)? onDelete;

  const CompactHabitItem({
    Key? key,
    required this.userHabit,
    required this.habit,
    required this.category,
    required this.isCompleted,
    this.isHighlighted = false,
    this.onTap,
    this.onHighlightComplete,
    this.onEdit,
    this.onViewProgress,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final habitName = habit.name.isNotEmpty ? habit.name : (userHabit.customName ?? 'Hábito');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getIconColor(category.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconData(category.iconName),
                    color: _getIconColor(category.color),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habitName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF1F2937),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (habit.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Completion status
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ),
                
                // Action menu (three dots)
                if (onEdit != null || onViewProgress != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onSelected: (String action) {
                      switch (action) {
                        case 'edit':
                          onEdit?.call(userHabit);
                          break;
                        case 'progress':
                          onViewProgress?.call(userHabit);
                          break;
                        case 'delete':
                          onDelete?.call(userHabit);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (onEdit != null)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Color(0xFF6B7280)),
                              SizedBox(width: 12),
                              Text('Editar hábito'),
                            ],
                          ),
                        ),
                      if (onViewProgress != null)
                        const PopupMenuItem<String>(
                          value: 'progress',
                          child: Row(
                            children: [
                              Icon(Icons.analytics, size: 18, color: Color(0xFF3B82F6)),
                              SizedBox(width: 12),
                              Text('Ver progreso'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 12),
                              Text('Eliminar hábito'),
                            ],
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

  Color _getIconColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_drink':
        return Icons.local_drink;
      case 'bedtime':
        return Icons.bedtime;
      case 'book':
        return Icons.book;
      case 'work':
        return Icons.work;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'psychology':
        return Icons.psychology;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.check_circle_outline;
    }
  }
}