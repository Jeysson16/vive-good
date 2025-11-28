import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../pages/habits/new_habit_screen.dart';

class AutoCreatedHabitsWidget extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback? onHabitsUpdated;
  
  const AutoCreatedHabitsWidget({
    super.key,
    required this.habits,
    this.onHabitsUpdated,
  });

  @override
  State<AutoCreatedHabitsWidget> createState() => _AutoCreatedHabitsWidgetState();
}

class _AutoCreatedHabitsWidgetState extends State<AutoCreatedHabitsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Header del desplegable
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hábitos sugeridos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.habits.length} hábito${widget.habits.length != 1 ? 's' : ''} encontrado${widget.habits.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido expandible
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Lista de hábitos
                  ...widget.habits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final habit = entry.value;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      curve: Curves.easeOutBack,
                      child: _buildHabitCard(context, habit, index),
                    );
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Botón para personalizar todos
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToCreateHabits(context),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Personalizar hábitos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHabitCard(BuildContext context, Habit habit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _navigateToEditHabit(context, habit),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icono del hábito
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: habit.iconColor != null 
                    ? Color(int.parse(habit.iconColor!.replaceFirst('#', '0xFF'))) 
                    : Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getIconData(habit.iconName ?? 'star'),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Información del hábito
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        'Categoría: ${habit.categoryId ?? 'General'}',
                        Colors.blue.shade100,
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        'Creado: ${_formatDate(habit.createdAt)}',
                        Colors.orange.shade100,
                        Colors.orange.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Flecha indicadora
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  void _navigateToCreateHabits(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewHabitScreen(),
      ),
    ).then((_) {
      widget.onHabitsUpdated?.call();
    });
  }
  
  void _navigateToEditHabit(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewHabitScreen(
          // habitToEdit: habit,
          // isEditing: true,
        ),
      ),
    ).then((_) {
      widget.onHabitsUpdated?.call();
    });
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'utensils':
        return Icons.restaurant;
      case 'heart':
        return Icons.favorite;
      case 'activity':
        return Icons.fitness_center;
      case 'brain':
        return Icons.psychology;
      case 'water_drop':
        return Icons.water_drop;
      case 'bed':
        return Icons.bed;
      case 'book':
        return Icons.book;
      case 'meditation':
        return Icons.self_improvement;
      default:
        return Icons.track_changes;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}