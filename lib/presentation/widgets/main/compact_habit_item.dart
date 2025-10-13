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
    print(
      '🔍 COMPACT HABIT ITEM - habit.iconName: ${habit.iconName}, habit.iconColor: ${habit.iconColor}',
    );
    final habitName = habit.name.isNotEmpty
        ? habit.name
        : (userHabit.customName ?? 'Hábito');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981)
              : const Color(0xFFE5E7EB),
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
                // Habit icon (usando icono específico del hábito)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Builder(
                    builder: (context) {
                      // Priorizar icono de categoría sobre icono individual (igual que habit_item.dart)
                      final categoryIconName = category.iconName;
                      final habitIconName = habit.iconName;
                      final finalIconName =
                          categoryIconName ?? habitIconName ?? 'star';

                      print(
                        '🔍 DEBUG COMPACT HABIT ITEM - habit.name: "${habit.name}"',
                      ); // CATEGORY PRIORITY FIXED
                      print(
                        '🔍 DEBUG COMPACT HABIT ITEM - category.iconName: "$categoryIconName"',
                      );
                      print(
                        '🔍 DEBUG COMPACT HABIT ITEM - habit.iconName: "$habitIconName"',
                      );
                      print(
                        '🔍 DEBUG COMPACT HABIT ITEM - finalIconName usado: "$finalIconName"',
                      );

                      final iconData = _getIconData(finalIconName);
                      print(
                        '🔍 DEBUG COMPACT HABIT ITEM - iconData result: $iconData',
                      );
                      return Icon(
                        iconData,
                        color: _getCategoryColor(),
                        size: 20,
                      );
                    },
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
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF1F2937),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
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
                if (onEdit != null ||
                    onViewProgress != null ||
                    onDelete != null)
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
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
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
                              Icon(
                                Icons.analytics,
                                size: 18,
                                color: Color(0xFF3B82F6),
                              ),
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
                              Icon(
                                Icons.delete,
                                size: 18,
                                color: Color(0xFFEF4444),
                              ),
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

  Color _getCategoryColor() {
    try {
      return Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Flutter icons - prioritizing category icons
    switch (iconName.toLowerCase()) {
      // Iconos de las categorías principales
      case 'utensils':
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'activity':
      case 'fitness_center':
      case 'exercise':
        return Icons.fitness_center;
      case 'moon':
      case 'bed':
      case 'sleep':
      case 'bedtime':
        return Icons.bedtime;
      case 'droplet':
      case 'water_drop':
      case 'water':
      case 'local_drink':
        return Icons.local_drink; // Usar local_drink específicamente
      // Iconos específicos de la base de datos
      case 'apple':
        return Icons.apple;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'edit':
        return Icons.edit;
      case 'menu_book':
        return Icons.menu_book;
      case 'event_note':
        return Icons.event_note;
      case 'brain':
      case 'psychology':
      case 'mental':
        return Icons.psychology;
      case 'target':
      case 'track_changes':
      case 'productivity':
        return Icons.track_changes;
      // Iconos adicionales
      case 'book':
        return Icons.book;
      case 'work':
      case 'business':
        return Icons.work;
      case 'school':
      case 'education':
        return Icons.school;
      case 'person':
      case 'personal':
        return Icons.person;
      case 'home':
      case 'house':
        return Icons.home;
      case 'people':
      case 'social':
        return Icons.people;
      case 'palette':
      case 'creative':
        return Icons.palette;
      case 'spiritual':
        return Icons.self_improvement;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'attach_money':
      case 'money':
      case 'finance':
        return Icons.attach_money;
      case 'fastfood':
        return Icons.fastfood;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'favorite':
      case 'heart':
        return Icons.favorite;
      case 'general':
        return Icons.track_changes;
      default:
        return Icons.star; // Cambiar de check_circle_outline a star
    }
  }
}
