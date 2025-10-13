import 'package:flutter/material.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/category.dart';

class AttachedHabitsWidget extends StatelessWidget {
  final List<UserHabit> attachedHabits;
  final List<Category>? categories;
  final VoidCallback? onRemoveAll;
  final Function(UserHabit)? onRemoveHabit;

  const AttachedHabitsWidget({
    super.key,
    required this.attachedHabits,
    this.categories,
    this.onRemoveAll,
    this.onRemoveHabit,
  });

  @override
  Widget build(BuildContext context) {
    if (attachedHabits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hábitos adjuntados (${attachedHabits.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
              const Spacer(),
              if (onRemoveAll != null)
                GestureDetector(
                  onTap: onRemoveAll,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Habits list
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachedHabits.map((userHabit) {
              return _buildHabitChip(userHabit);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitChip(UserHabit userHabit) {
    // Obtener el nombre del hábito
    String habitName = userHabit.customName ?? 
                      userHabit.habit?.name ?? 
                      'Hábito personalizado';

    // Obtener el color de la categoría si está disponible
    Color chipColor = const Color(0xFF6366F1);
    if (userHabit.habit?.categoryId != null && categories != null) {
      final category = categories!.firstWhere(
        (cat) => cat.id == userHabit.habit!.categoryId,
        orElse: () => Category(
          id: '',
          name: '',
          iconName: 'help_circle',
          color: '#6366F1',
        ),
      );
      chipColor = _parseColor(category.color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono del hábito
          Icon(
            _getHabitIcon(userHabit),
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          
          // Nombre del hábito
          Flexible(
            child: Text(
              habitName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: chipColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Botón de eliminar individual (si está disponible)
          if (onRemoveHabit != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => onRemoveHabit!(userHabit),
              child: Icon(
                Icons.close,
                size: 14,
                color: chipColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getHabitIcon(UserHabit userHabit) {
    // Intentar obtener el icono del hábito
    final iconName = userHabit.habit?.iconName;
    
    if (iconName != null) {
      switch (iconName.toLowerCase()) {
        case 'fitness_center':
        case 'exercise':
          return Icons.fitness_center;
        case 'local_drink':
        case 'water':
          return Icons.local_drink;
        case 'restaurant':
        case 'food':
          return Icons.restaurant;
        case 'bedtime':
        case 'sleep':
          return Icons.bedtime;
        case 'book':
        case 'read':
          return Icons.book;
        case 'self_improvement':
        case 'meditation':
          return Icons.self_improvement;
        case 'work':
        case 'business':
          return Icons.work;
        case 'favorite':
        case 'health':
          return Icons.favorite;
        default:
          return Icons.check_circle_outline;
      }
    }
    
    return Icons.check_circle_outline;
  }

  Color _parseColor(String colorString) {
    try {
      // Remover el # si está presente
      String cleanColor = colorString.replaceAll('#', '');
      
      // Asegurar que tenga 6 caracteres
      if (cleanColor.length == 6) {
        return Color(int.parse('FF$cleanColor', radix: 16));
      }
    } catch (e) {
      // Si hay error al parsear, usar color por defecto
    }
    
    return const Color(0xFF6366F1);
  }
}