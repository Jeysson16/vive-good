import 'package:flutter/material.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import 'habit_item.dart';

class HabitList extends StatelessWidget {
  final List<UserHabit> userHabits;
  final List<Habit> habits;
  final Map<String, List<HabitLog>> habitLogs;
  final Function(String, bool) onHabitToggle;

  const HabitList({
    super.key,
    required this.userHabits,
    required this.habits,
    required this.habitLogs,
    required this.onHabitToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Filter habits to show only today's incomplete habits
    final todayIncompleteHabits = _getTodayIncompleteHabits();
    
    if (userHabits.isEmpty) {
      return _buildEmptyState(context);
    }
    
    if (todayIncompleteHabits.isEmpty) {
      return _buildAllCompletedState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: todayIncompleteHabits.length,
      itemBuilder: (context, index) {
        final userHabit = todayIncompleteHabits[index];
        
        // Find the corresponding habit
        final habit = habits.firstWhere(
          (h) => h.id == userHabit.habitId,
          orElse: () => _createMockHabit(userHabit.habitId, index),
        );
        
        return HabitItem(
          userHabit: userHabit,
          habit: habit,
          isCompleted: false, // Always false since we're showing incomplete habits
          onToggle: (isCompleted) {
            onHabitToggle(userHabit.id, isCompleted);
          },
        );
      },
    );
  }
  
  List<UserHabit> _getTodayIncompleteHabits() {
    final today = DateTime.now();
    
    return userHabits.where((userHabit) {
      final logs = habitLogs[userHabit.id] ?? [];
      final isCompletedToday = logs.any((log) {
        final logDate = log.completedAt;
        return logDate.year == today.year &&
               logDate.month == today.month &&
               logDate.day == today.day;
      });
      return !isCompletedToday; // Only return habits not completed today
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.track_changes,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes hábitos aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu primer hábito para\ncomenzar tu viaje de bienestar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/habits');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Ir a Hábitos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAllCompletedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 40,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Felicidades!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Has completado todos tus\nhábitos de hoy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/habits');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Ver todos los hábitos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mock habit data for demonstration
  Habit _createMockHabit(String habitId, int index) {
    final mockHabits = [
      {
        'name': 'Beber agua',
        'description': '250 ml de agua',
        'icon': Icons.local_drink,
        'color': '0xFF4FC3F7',
      },
      {
        'name': 'Almuerzo',
        'description': '12 pm',
        'icon': Icons.restaurant,
        'color': '0xFF66BB6A',
      },
      {
        'name': 'Comer frutas',
        'description': 'en la mañana',
        'icon': Icons.apple,
        'color': '0xFFFF7043',
      },
      {
        'name': 'Ejercicio',
        'description': '30 minutos',
        'icon': Icons.fitness_center,
        'color': '0xFF42A5F5',
      },
    ];
    
    final mockData = mockHabits[index % mockHabits.length];
    
    return Habit(
      id: habitId,
      name: mockData['name'] as String,
      description: mockData['description'] as String,
      categoryId: '1',
      iconName: (mockData['icon'] as IconData).codePoint.toString(),
      iconColor: mockData['color'] as String,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}