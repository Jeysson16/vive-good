import 'package:flutter/material.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';

class HabitItem extends StatelessWidget {
  final UserHabit userHabit;
  final Habit habit;
  final bool isCompleted;
  final Function(bool) onToggle;

  const HabitItem({
    super.key,
    required this.userHabit,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Habit Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getIconColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(_getHabitIcon(), color: _getIconColor(), size: 24),
          ),
          const SizedBox(width: 16),

          // Habit Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151),
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  habit.description ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Completado' : 'Pendiente',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Checkbox
          GestureDetector(
            onTap: () => onToggle(!isCompleted),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHabitIcon() {
    // Parse icon from habit.iconName or use default icons
    switch (habit.name.toLowerCase()) {
      case 'beber agua':
      case 'agua':
        return Icons.local_drink;
      case 'almuerzo':
      case 'comida':
        return Icons.restaurant;
      case 'comer frutas':
      case 'frutas':
        return Icons.apple;
      case 'ejercicio':
      case 'deporte':
        return Icons.fitness_center;
      case 'dormir':
      case 'sueño':
        return Icons.bedtime;
      case 'meditar':
      case 'meditación':
        return Icons.self_improvement;
      default:
        return Icons.track_changes;
    }
  }

  Color _getIconColor() {
    // Parse color from habit.iconColor or use default colors
    try {
      if (habit.iconColor != null && habit.iconColor!.startsWith('0x')) {
        return Color(int.parse(habit.iconColor!));
      }
    } catch (e) {
      // Fallback to default colors
    }

    switch (habit.name.toLowerCase()) {
      case 'beber agua':
      case 'agua':
        return const Color(0xFF4FC3F7);
      case 'almuerzo':
      case 'comida':
        return const Color(0xFF66BB6A);
      case 'comer frutas':
      case 'frutas':
        return const Color(0xFFFF7043);
      case 'ejercicio':
      case 'deporte':
        return const Color(0xFF42A5F5);
      case 'dormir':
      case 'sueño':
        return const Color(0xFF9C27B0);
      case 'meditar':
      case 'meditación':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
