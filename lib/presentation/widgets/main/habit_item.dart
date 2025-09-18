import 'package:flutter/material.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/category.dart';
import '../common/responsive_dimensions.dart';

class HabitItem extends StatelessWidget {
  final UserHabit userHabit;
  final Habit habit;
  final Category? category;
  final bool isCompleted;
  final bool isSelected;
  final VoidCallback? onTap;
  final Function(String, bool)? onSelectionChanged;

  const HabitItem({
    super.key,
    required this.userHabit,
    required this.habit,
    required this.category,
    required this.isCompleted,
    this.isSelected = false,
    this.onTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF3F4F6),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onSelectionChanged != null) {
              onSelectionChanged!(userHabit.id, !isSelected);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row with checkbox and completion status
                Row(
                  children: [
                    // Custom checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),

                    const Spacer(),

                    // Completion status
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                          size: 16,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category icon (centered)
                if (category != null)
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getIconColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(),
                        color: _getIconColor(),
                        size: 20,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Habit content (centered)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF111827),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category?.name != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getIconColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category!.name!,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getIconColor(),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor() {
    if (category?.color != null) {
      try {
        String colorString = category!.color!.trim();
        
        // Remove # if present
        if (colorString.startsWith('#')) {
          colorString = colorString.substring(1);
        }
        
        // Ensure we have a valid hex color (6 or 8 characters)
        if (colorString.length == 6) {
          // Add alpha channel for 6-digit hex
          colorString = 'FF$colorString';
        } else if (colorString.length != 8) {
          // Invalid length, use default
          return const Color(0xFF6B7280);
        }
        
        // Parse as hex with 0xFF prefix
        final colorValue = int.parse(colorString, radix: 16);
        return Color(0xFF000000 | colorValue);
      } catch (e) {
        // Debug: print error for troubleshooting
        debugPrint('Error parsing color ${category!.color}: $e');
        return const Color(0xFF6B7280);
      }
    }
    return const Color(0xFF6B7280);
  }

  IconData _getCategoryIcon() {
    if (category?.iconName == null) return Icons.star;

    // Map icon names to Flutter icons
    switch (category!.iconName.toLowerCase()) {
      // Iconos de las categorías de la base de datos
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
        return Icons.bedtime;
      case 'droplet':
      case 'water_drop':
      case 'water':
        return Icons.water_drop;
      case 'brain':
      case 'psychology':
      case 'mental':
        return Icons.psychology;
      case 'target':
      case 'track_changes':
      case 'productivity':
        return Icons.track_changes;
      // Iconos adicionales
      case 'favorite':
      case 'heart':
        return Icons.favorite;
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
      case 'self_improvement':
      case 'spiritual':
        return Icons.self_improvement;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'attach_money':
      case 'money':
      case 'finance':
        return Icons.attach_money;
      case 'general':
        return Icons.track_changes;
      default:
        return Icons.star;
    }
  }
}
