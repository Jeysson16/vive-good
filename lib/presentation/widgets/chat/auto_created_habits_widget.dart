import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/habit.dart';
import '../../blocs/habit/habit_bloc.dart';

import '../../pages/habits/new_habit_screen.dart';

class AutoCreatedHabitsWidget extends StatelessWidget {
  final List<Habit> habits;
  final VoidCallback? onHabitsUpdated;
  
  const AutoCreatedHabitsWidget({
    super.key,
    required this.habits,
    this.onHabitsUpdated,
  });
  
  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hábitos sugeridos automáticamente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...habits.map((habit) => _buildHabitCard(context, habit)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showAllHabits(context),
                icon: const Icon(Icons.list, size: 16),
                label: const Text('Ver todos'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHabitCard(BuildContext context, Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: habit.iconColor != null ? Color(int.parse(habit.iconColor!.replaceFirst('#', '0xFF'))) : Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                    _getIconData(habit.iconName ?? 'star'),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      habit.categoryId ?? 'General',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleHabitAction(context, habit, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Personalizar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            habit.description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('Frecuencia: Diario'),
              const SizedBox(width: 8),
              _buildInfoChip('0 recordatorios'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      ),
    );
  }
  
  void _handleHabitAction(BuildContext context, Habit habit, String action) {
    switch (action) {
      case 'edit':
        _editHabit(context, habit);
        break;
      case 'delete':
        _deleteHabit(context, habit);
        break;
    }
  }
  
  void _editHabit(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewHabitScreen(
          // habitToEdit: habit,
          // isEditing: true,
        ),
      ),
    ).then((_) {
      onHabitsUpdated?.call();
    });
  }
  
  void _deleteHabit(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text('¿Estás seguro de que quieres eliminar "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar eliminación de hábito
      // context.read<HabitBloc>().add(DeleteUserHabitEvent(habit.id));
              Navigator.of(context).pop();
              onHabitsUpdated?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  
  void _showAllHabits(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hábitos sugeridos (${habits.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: habits.length,
                  itemBuilder: (context, index) => _buildHabitCard(context, habits[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      default:
        return Icons.track_changes;
    }
  }
  
  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekdays':
        return 'Entre semana';
      case 'weekends':
        return 'Fines de semana';
      case 'weekly':
        return 'Semanal';
      default:
        return frequency;
    }
  }
}