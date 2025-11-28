import 'package:flutter/material.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import 'common/responsive_dimensions.dart';

/// Widget de hábito con diseño basado en Frame 7 (2072_660) y Group 10084
/// Apariencia visual mejorada para la pantalla "Mis hábitos"
class FigmaHabitCard extends StatelessWidget {
  final UserHabit habit;
  final VoidCallback? onEdit;
  final VoidCallback? onViewProgress;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool isCompleted;
  final bool isSelected;

  const FigmaHabitCard({
    super.key,
    required this.habit,
    this.onEdit,
    this.onViewProgress,
    this.onDelete,
    this.onTap,
    this.isCompleted = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4CAF50)
              : isCompleted
              ? const Color(0xFF22C55E).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildHabitIcon(),
                const SizedBox(width: 16),
                Expanded(child: _buildHabitInfo()),
                _buildActionMenu(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitIcon() {
    final iconColor = _getIconColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4CAF50).withOpacity(0.15)
            : isCompleted
            ? const Color(0xFF22C55E).withOpacity(0.15)
            : iconColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : null,
      ),
      child: Icon(
        _getCategoryIcon(),
        color: isSelected
            ? const Color(0xFF4CAF50)
            : isCompleted
            ? const Color(0xFF22C55E)
            : iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildHabitInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          habit.habit?.name ??
              'Incluir vegetales verdes\nal menos una vez al día',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF4CAF50)
                : isCompleted
                ? const Color(0xFF059669)
                : const Color(0xFF111827),
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : isCompleted
                ? const Color(0xFF22C55E)
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isSelected
                ? 'Seleccionado'
                : isCompleted
                ? 'Completado'
                : habit.frequency ?? 'Diario',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: (isSelected || isCompleted)
                  ? Colors.white
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_horiz, color: Color(0xFF6B7280), size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      offset: const Offset(-120, 40),
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          'edit',
          'Editar hábito',
          Icons.edit_outlined,
          const Color(0xFF3B82F6),
        ),
        _buildPopupMenuItem(
          'progress',
          'Ver progreso',
          Icons.trending_up,
          const Color(0xFF10B981),
        ),
        _buildPopupMenuItem(
          'delete',
          'Eliminar hábito',
          Icons.delete_outline,
          const Color(0xFFEF4444),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'progress':
            onViewProgress?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    String text,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor() {
    // Primero intentar obtener el color del hábito
    String? colorString = habit.habit?.iconColor;

    if (colorString == null) return const Color(0xFF6B7280);

    try {
      String cleanColor = colorString.trim();

      // Remove # if present
      if (cleanColor.startsWith('#')) {
        cleanColor = cleanColor.substring(1);
      }

      // Ensure we have a valid hex color (6 or 8 characters)
      if (cleanColor.length == 6) {
        // Add alpha channel for 6-digit hex
        cleanColor = 'FF$cleanColor';
      } else if (cleanColor.length != 8) {
        // Invalid length, use default
        return const Color(0xFF6B7280);
      }

      // Parse as hex and create Color
      final colorValue = int.parse(cleanColor, radix: 16);
      return Color(colorValue);
    } catch (e) {
      // Debug: Error parsing color for troubleshooting
      // debugPrint('Error parsing color $colorString: $e');
      return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon() {
    // Obtener el icono del hábito
    String? iconName = habit.habit?.iconName;

    // Debug: imprimir información del icono

    if (iconName == null) {
      return Icons.star;
    }

    // Map icon names to Flutter icons
    switch (iconName.toLowerCase()) {
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
      case 'local_drink':
        return Icons.local_drink;
      case 'brain':
      case 'psychology':
      case 'mental':
        return Icons.psychology;
      case 'target':
      case 'track_changes':
      case 'productivity':
        return Icons.track_changes;
      // Iconos específicos de la base de datos
      case 'apple':
        return Icons.apple;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'bedtime':
        return Icons.bedtime;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'edit':
        return Icons.edit;
      case 'menu_book':
        return Icons.menu_book;
      case 'event_note':
        return Icons.event_note;
      // Iconos adicionales
      case 'favorite':
        return Icons
            .fitness_center; // Cambiar de corazón a fitness para hábitos generales
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
      case 'general':
        return Icons.track_changes;
      default:
        return Icons.star;
    }
  }
}
