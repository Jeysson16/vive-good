import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';

/// Página para seleccionar actividades pendientes y adjuntarlas al chat
class PendingActivitiesSelectionPage extends StatefulWidget {
  const PendingActivitiesSelectionPage({super.key});

  @override
  State<PendingActivitiesSelectionPage> createState() => _PendingActivitiesSelectionPageState();
}

class _PendingActivitiesSelectionPageState extends State<PendingActivitiesSelectionPage> {
  final Set<String> _selectedHabits = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Actividades Pendientes',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        actions: [
          if (_selectedHabits.isNotEmpty)
            TextButton(
              onPressed: _attachSelectedHabits,
              child: Text(
                'Adjuntar (${_selectedHabits.length})',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar actividades',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DashboardBloc>().add(
                      LoadDashboardData(
                        userId: 'current_user', // Se debe obtener del AuthBloc
                        date: DateTime.now(),
                      ),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            final pendingHabits = _getPendingHabits(
              state.userHabits,
              state.habits,
              state.categories,
            );

            if (pendingHabits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Excelente!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No tienes actividades pendientes para hoy',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header con información
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona las actividades que quieres mencionar en el chat',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pendingHabits.length} actividades pendientes para hoy',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de hábitos pendientes
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingHabits.length,
                    itemBuilder: (context, index) {
                      final habitData = pendingHabits[index];
                      final userHabit = habitData['userHabit'] as UserHabit;
                      final habit = habitData['habit'] as Habit?;
                      final category = habitData['category'] as Category?;
                      
                      final habitName = habit?.name ?? userHabit.customName ?? 'Hábito personalizado';
                      final isSelected = _selectedHabits.contains(userHabit.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _toggleHabitSelection(userHabit.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icono de categoría
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(category).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    color: _getCategoryColor(category),
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
                                        habitName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      if (category != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                      if (userHabit.scheduledTime != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatScheduledTime(userHabit.scheduledTime!),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Checkbox
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) => _toggleHabitSelection(userHabit.id),
                                  activeColor: const Color(0xFF2E7D32),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Obtiene los hábitos pendientes para hoy
  List<Map<String, dynamic>> _getPendingHabits(
    List<UserHabit> userHabits,
    List<Habit> habits,
    List<Category> categories,
  ) {
    final today = DateTime.now();
    final pendingHabits = <Map<String, dynamic>>[];

    for (final userHabit in userHabits) {
      // Solo incluir hábitos activos y no completados hoy
      if (!userHabit.isActive || userHabit.isCompletedToday) {
        continue;
      }

      // Verificar si el hábito debe estar activo hoy según su frecuencia
      if (!_shouldHabitBeActiveToday(userHabit, today)) {
        continue;
      }

      // Buscar el hábito y categoría correspondientes
      final habit = habits.firstWhere(
        (h) => h.id == userHabit.habitId,
        orElse: () => Habit(
          id: '',
          name: '',
          description: '',
          categoryId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final category = categories.firstWhere(
        (c) => c.id == habit.categoryId,
        orElse: () => Category(
          id: '',
          name: 'General',
          description: '',
          iconName: 'star',
          color: '#6366F1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      pendingHabits.add({
        'userHabit': userHabit,
        'habit': habit.id.isNotEmpty ? habit : null,
        'category': category,
      });
    }

    // Ordenar por hora programada
    pendingHabits.sort((a, b) {
      final timeA = (a['userHabit'] as UserHabit).scheduledTime;
      final timeB = (b['userHabit'] as UserHabit).scheduledTime;
      
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      
      return timeA.compareTo(timeB);
    });

    return pendingHabits;
  }

  /// Verifica si el hábito debe estar activo hoy según su frecuencia
  bool _shouldHabitBeActiveToday(UserHabit userHabit, DateTime today) {
    switch (userHabit.frequency.toLowerCase()) {
      case 'daily':
      case 'diario':
        return true;
      case 'weekly':
      case 'semanal':
        if (userHabit.frequencyDetails != null &&
            userHabit.frequencyDetails!.containsKey('days_of_week')) {
          final selectedDays = userHabit.frequencyDetails!['days_of_week'] as List<dynamic>?;
          if (selectedDays != null && selectedDays.isNotEmpty) {
            final todayWeekday = today.weekday; // 1=Lunes .. 7=Domingo
            return selectedDays.contains(todayWeekday);
          }
        }
        return true;
      case 'monthly':
      case 'mensual':
        if (userHabit.frequencyDetails != null &&
            userHabit.frequencyDetails!.containsKey('day_of_month')) {
          final targetDay = userHabit.frequencyDetails!['day_of_month'] as int?;
          if (targetDay != null) {
            return today.day == targetDay;
          }
        }
        return today.day == 1;
      default:
        return true;
    }
  }

  /// Alterna la selección de un hábito
  void _toggleHabitSelection(String habitId) {
    setState(() {
      if (_selectedHabits.contains(habitId)) {
        _selectedHabits.remove(habitId);
      } else {
        _selectedHabits.add(habitId);
      }
    });
  }

  /// Adjunta los hábitos seleccionados al chat
  void _attachSelectedHabits() {
    if (_selectedHabits.isEmpty) return;

    final dashboardState = context.read<DashboardBloc>().state;
    if (dashboardState is! DashboardLoaded) return;

    // Crear mensaje con los hábitos seleccionados
    final selectedHabitsData = <Map<String, dynamic>>[];
    
    for (final habitId in _selectedHabits) {
      final userHabit = dashboardState.userHabits.firstWhere(
        (uh) => uh.id == habitId,
        orElse: () => UserHabit(
          id: '',
          userId: '',
          habitId: '',
          frequency: '',
          notificationsEnabled: false,
          startDate: DateTime.now(),
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (userHabit.id.isEmpty) continue;

      final habit = dashboardState.habits.firstWhere(
        (h) => h.id == userHabit.habitId,
        orElse: () => Habit(
          id: '',
          name: '',
          description: '',
          categoryId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final habitName = habit.name.isNotEmpty ? habit.name : userHabit.customName ?? 'Hábito personalizado';
      
      selectedHabitsData.add({
        'id': userHabit.id,
        'name': habitName,
        'scheduled_time': userHabit.scheduledTime?.toString(),
        'frequency': userHabit.frequency,
      });
    }

    // Crear mensaje formateado
    final habitsList = selectedHabitsData
        .map((habit) => '• ${habit['name']}${habit['scheduled_time'] != null ? ' (${_formatTime(TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 ${habit['scheduled_time']}')))}' : ''}')
        .join('\n');

    final message = 'Quiero hablar sobre estas actividades pendientes de hoy:\n\n$habitsList\n\n¿Puedes ayudarme con consejos o motivación para completarlas?';

    // Retornar el mensaje al chat
    Navigator.of(context).pop(message);
  }

  /// Obtiene el color de la categoría
  Color _getCategoryColor(Category? category) {
    if (category == null) return const Color(0xFF6366F1);
    
    try {
      final colorString = category.color.replaceAll('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  /// Obtiene el icono de la categoría
  IconData _getCategoryIcon(Category? category) {
    if (category == null) return Icons.star;
    
    switch (category.iconName.toLowerCase()) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'psychology':
        return Icons.psychology;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      default:
        return Icons.star;
    }
  }

  /// Formatea la hora programada desde string
  String _formatScheduledTime(String timeString) {
    try {
      // Asumiendo formato HH:mm
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  /// Formatea la hora para mostrar
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}