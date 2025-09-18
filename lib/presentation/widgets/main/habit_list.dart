import 'package:flutter/material.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../../domain/entities/category.dart';
import 'habit_item.dart';

class HabitList extends StatelessWidget {
  final List<UserHabit> userHabits;
  final List<Habit> habits;
  final List<Category> categories;
  final Map<String, List<HabitLog>> habitLogs;
  final Function(String, bool) onHabitToggle;
  final Set<String> selectedHabits;
  final Function(String, bool) onHabitSelected;
  final String? selectedCategoryId;

  const HabitList({
    super.key,
    required this.userHabits,
    required this.habits,
    required this.categories,
    required this.habitLogs,
    required this.onHabitToggle,
    required this.selectedHabits,
    required this.onHabitSelected,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Print received data
    print('🔍 HABIT_LIST DEBUG: userHabits.length = ${userHabits.length}');
    print('🔍 HABIT_LIST DEBUG: habits.length = ${habits.length}');
    print('🔍 HABIT_LIST DEBUG: categories.length = ${categories.length}');
    print('🔍 HABIT_LIST DEBUG: habitLogs.length = ${habitLogs.length}');
    print('🔍 HABIT_LIST DEBUG: selectedCategoryId = $selectedCategoryId');
    
    // Filter habits to show only today's incomplete habits
    final todayIncompleteHabits = _getTodayIncompleteHabits();
    print('🔍 HABIT_LIST DEBUG: todayIncompleteHabits.length = ${todayIncompleteHabits.length}');
    
    if (userHabits.isEmpty) {
      print('🔍 HABIT_LIST DEBUG: Showing empty state - no userHabits');
      return SliverFillRemaining(child: _buildEmptyState(context));
    }
    
    if (todayIncompleteHabits.isEmpty) {
      print('🔍 HABIT_LIST DEBUG: Showing all completed state - no incomplete habits');
      return SliverFillRemaining(child: _buildAllCompletedState(context));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0, // Ratio más equilibrado para evitar overflow
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final userHabit = todayIncompleteHabits[index];
            
            // Find the corresponding habit
            final habit = habits.firstWhere(
              (h) => h.id == userHabit.habitId,
            );
            
            // Find the corresponding category with better fallback
            Category? category;
            try {
              category = categories.firstWhere(
                (c) => c.id == habit.categoryId,
              );
            } catch (e) {
              // Create a default category if not found
              category = Category(
                id: 'default',
                name: 'General',
                iconName: 'star',
                color: '6B7280',
              );
            }
            
            return HabitItem(
              userHabit: userHabit,
              habit: habit,
              category: category,
              isCompleted: false, // Always false since we're showing incomplete habits
              isSelected: selectedHabits.contains(userHabit.id),
              onTap: () {
                onHabitToggle(userHabit.id, true);
              },
              onSelectionChanged: onHabitSelected,
            );
          },
          childCount: todayIncompleteHabits.length,
        ),
      ),
    );
  }
  
  List<UserHabit> _getTodayIncompleteHabits() {
    final today = DateTime.now();
    print('🔍 HABIT_LIST DEBUG: Filtering habits for today: $today');
    
    return userHabits.where((userHabit) {
      print('🔍 HABIT_LIST DEBUG: Checking userHabit ${userHabit.id}');
      
      // Check if the habit is active for today based on frequency
      final isActiveToday = _isHabitActiveToday(userHabit, today);
      print('🔍 HABIT_LIST DEBUG: isActiveToday = $isActiveToday');
      if (!isActiveToday) {
        return false;
      }
      
      // Filter by category if selectedCategoryId is not null
      if (selectedCategoryId != null) {
        final habit = habits.firstWhere((h) => h.id == userHabit.habitId);
        print('🔍 HABIT_LIST DEBUG: Filtering by category. habit.categoryId = ${habit.categoryId}, selectedCategoryId = $selectedCategoryId');
        if (habit.categoryId != selectedCategoryId) {
          return false;
        }
      }
      
      // Use UserHabit's isCompletedToday property instead of habitLogs
      final isCompletedToday = userHabit.isCompletedToday;
      print('🔍 HABIT_LIST DEBUG: isCompletedToday from UserHabit = $isCompletedToday');
      final shouldInclude = !isCompletedToday;
      print('🔍 HABIT_LIST DEBUG: shouldInclude = $shouldInclude');
      return shouldInclude; // Only return habits not completed today
    }).toList();
  }
  
  bool _isHabitActiveToday(UserHabit userHabit, DateTime today) {
    final startDate = userHabit.startDate;
    print('🔍 HABIT_LIST DEBUG: userHabit.frequency = "${userHabit.frequency}"');
    print('🔍 HABIT_LIST DEBUG: userHabit.startDate = $startDate');
    print('🔍 HABIT_LIST DEBUG: today = $today');
    
    // Check if today is after or equal to start date
    if (today.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      print('🔍 HABIT_LIST DEBUG: Today is before start date, returning false');
      return false;
    }
    
    // For daily habits, always active
    if (userHabit.frequency == 'daily') {
      print('🔍 HABIT_LIST DEBUG: Daily habit, returning true');
      return true;
    }
    
    // For weekly habits, assume they are active every day for now
    // TODO: Implement proper weekly schedule logic with habit_schedules table
    if (userHabit.frequency == 'weekly') {
      print('🔍 HABIT_LIST DEBUG: Weekly habit, returning true');
      return true; // Temporarily allow all weekly habits to be active
    }
    
    // For now, let's make all habits active regardless of frequency
    // This is a temporary fix to show the habits
    print('🔍 HABIT_LIST DEBUG: Unknown frequency "${userHabit.frequency}", returning true (temporary fix)');
    return true;
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

}