import 'package:flutter/material.dart';
import '../../services/habits_service.dart';
import '../../services/symptoms_service.dart';
import '../../services/calendar_service.dart';

class DailyProgressPage extends StatefulWidget {
  const DailyProgressPage({super.key});

  @override
  State<DailyProgressPage> createState() => _DailyProgressPageState();
}

class _DailyProgressPageState extends State<DailyProgressPage> {
  Map<String, dynamic> _progressData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDailyProgress();
  }

  Future<void> _loadDailyProgress() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final today = DateTime.now();
      
      // Cargar datos en paralelo
      final results = await Future.wait([
        HabitsService.getTodayCompletedHabits(),
        HabitsService.getHabitsStats(),
        CalendarService.getTodayActivities(),
        SymptomsService.getTodaySymptoms(),
      ]);

      setState(() {
        _progressData = {
          'completedHabits': results[0],
          'habitsStats': results[1],
          'todayActivities': results[2],
          'todaySymptoms': results[3],
          'date': today,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsProgress() {
    final completedHabits = _progressData['completedHabits'] as List? ?? [];
    final habitsStats = _progressData['habitsStats'] as Map? ?? {};
    
    final totalHabits = habitsStats['total_active_habits'] ?? 0;
    final completedCount = completedHabits.length;
    final progressPercentage = totalHabits > 0 ? (completedCount / totalHabits) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Progreso de Hábitos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Barra de progreso
            LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 8),
            
            Text(
              '$completedCount de $totalHabits hábitos completados',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            if (completedHabits.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Hábitos completados hoy:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...completedHabits.take(3).map((habit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habit['habit_name'] ?? 'Hábito sin nombre',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
              if (completedHabits.length > 3)
                Text(
                  'y ${completedHabits.length - 3} más...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = '${today.day}/${today.month}/${today.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso de Hoy'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDailyProgress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _error != null
              ? Center(
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
                        'Error al cargar progreso',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDailyProgress,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDailyProgress,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado con fecha
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.today,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Resumen del día',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Progreso de hábitos
                        _buildHabitsProgress(),
                        const SizedBox(height: 16),

                        // Tarjetas de estadísticas
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildProgressCard(
                              title: 'Actividades',
                              value: '${(_progressData['todayActivities'] as List?)?.length ?? 0}',
                              subtitle: 'Programadas para hoy',
                              icon: Icons.event,
                              color: Colors.blue,
                            ),
                            _buildProgressCard(
                              title: 'Síntomas',
                              value: '${(_progressData['todaySymptoms'] as List?)?.length ?? 0}',
                              subtitle: 'Registrados hoy',
                              icon: Icons.health_and_safety,
                              color: Colors.orange,
                            ),
                            _buildProgressCard(
                              title: 'Racha',
                              value: '${(_progressData['habitsStats'] as Map?)?['current_streak'] ?? 0}',
                              subtitle: 'Días consecutivos',
                              icon: Icons.local_fire_department,
                              color: Colors.red,
                            ),
                            _buildProgressCard(
                              title: 'Total Hábitos',
                              value: '${(_progressData['habitsStats'] as Map?)?['total_active_habits'] ?? 0}',
                              subtitle: 'Hábitos activos',
                              icon: Icons.list_alt,
                              color: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}