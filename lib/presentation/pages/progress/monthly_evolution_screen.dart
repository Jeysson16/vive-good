import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_event.dart';
import '../../blocs/progress/progress_state.dart';
import '../../blocs/habit_breakdown/habit_breakdown_bloc.dart';
import '../../blocs/habit_breakdown/habit_breakdown_event.dart';
import '../../blocs/habit_breakdown/habit_breakdown_state.dart';

class MonthlyEvolutionScreen extends StatefulWidget {
  const MonthlyEvolutionScreen({super.key});

  @override
  State<MonthlyEvolutionScreen> createState() => _MonthlyEvolutionScreenState();
}

class _MonthlyEvolutionScreenState extends State<MonthlyEvolutionScreen> {
  
  // Helper method to get current user ID
  String? _getCurrentUserId() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
      return currentUser.id;
    }
    return null;
  }

  // Helper method to handle user ID validation and error
  void _handleUserIdError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: Usuario no autenticado. Por favor, inicia sesión nuevamente.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Cargar datos mensuales
    final userId = _getCurrentUserId();
    if (userId != null) {
      context.read<ProgressBloc>().add(LoadUserProgress(userId: userId));
      // Cargar desglose de hábitos para el mes actual
      final now = DateTime.now();
      context.read<HabitBreakdownBloc>().add(
        LoadMonthlyHabitsBreakdown(
          userId: userId,
          year: now.year,
          month: now.month,
        ),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUserIdError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Evolución Mensual',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          if (state is ProgressLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            );
          }

          if (state is ProgressError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar datos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final userId = _getCurrentUserId();
                      if (userId != null) {
                        context.read<ProgressBloc>().add(LoadUserProgress(userId: userId));
                      } else {
                        _handleUserIdError();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is ProgressLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthlyOverview(state),
                  const SizedBox(height: 24),
                  _buildMonthlyChart(state),
                  const SizedBox(height: 24),
                  _buildHabitsBreakdown(state),
                ],
              ),
            );
          }

          return const Center(
            child: Text('No hay datos disponibles'),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyOverview(ProgressLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Mes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Progreso Total',
                  '${((state.progress.weeklyProgressPercentage * 100).isFinite ? (state.progress.weeklyProgressPercentage * 100).toInt() : 0)}%',
                  const Color(0xFF4CAF50),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Días Activos',
                  '${state.progress.weeklyCompletedHabits}',
                  const Color(0xFF2196F3),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(ProgressLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso Semanal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildWeeklyProgressChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart() {
    final weeks = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    final progress = [0.7, 0.8, 0.6, 0.9]; // Datos de ejemplo

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(weeks.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${((progress[index] * 100).isFinite ? (progress[index] * 100).toInt() : 0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: progress[index] * 150,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              weeks[index],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHabitsBreakdown(ProgressLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desglose de Hábitos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<HabitBreakdownBloc, HabitBreakdownState>(
            builder: (context, breakdownState) {
              if (breakdownState is HabitBreakdownLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                );
              }
              
              if (breakdownState is HabitBreakdownError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar desglose',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (breakdownState is HabitBreakdownLoaded) {
                if (breakdownState.breakdown.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay datos de hábitos disponibles',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: breakdownState.breakdown.map((breakdown) {
                    return _buildHabitItem(
                      breakdown.categoryName,
                      breakdown.completionPercentage / 100,
                      _getCategoryIcon(breakdown.categoryName),
                    );
                  }).toList(),
                );
              }
              
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No hay datos disponibles',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(String name, double progress, IconData icon) {
    final iconColor = _getCategoryColor(name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${((progress * 100).isFinite ? (progress * 100).toInt() : 0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ejercicio':
      case 'fitness':
      case 'deporte':
        return Icons.fitness_center;
      case 'meditación':
      case 'mindfulness':
      case 'relajación':
        return Icons.self_improvement;
      case 'lectura':
      case 'estudio':
      case 'aprendizaje':
        return Icons.book;
      case 'agua':
      case 'hidratación':
        return Icons.local_drink;
      case 'alimentación':
      case 'nutrición':
      case 'comida':
        return Icons.restaurant;
      case 'sueño':
      case 'descanso':
        return Icons.bedtime;
      case 'trabajo':
      case 'productividad':
        return Icons.work;
      case 'social':
      case 'familia':
      case 'amigos':
        return Icons.people;
      case 'creatividad':
      case 'arte':
        return Icons.palette;
      case 'finanzas':
      case 'dinero':
        return Icons.attach_money;
      default:
        return Icons.track_changes;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ejercicio':
      case 'fitness':
      case 'deporte':
        return const Color(0xFFE91E63); // Rosa
      case 'meditación':
      case 'mindfulness':
      case 'relajación':
        return const Color(0xFF9C27B0); // Púrpura
      case 'lectura':
      case 'estudio':
      case 'aprendizaje':
        return const Color(0xFF3F51B5); // Índigo
      case 'agua':
      case 'hidratación':
        return const Color(0xFF2196F3); // Azul
      case 'alimentación':
      case 'nutrición':
      case 'comida':
        return const Color(0xFF4CAF50); // Verde
      case 'sueño':
      case 'descanso':
        return const Color(0xFF673AB7); // Púrpura profundo
      case 'trabajo':
      case 'productividad':
        return const Color(0xFF795548); // Marrón
      case 'social':
      case 'familia':
      case 'amigos':
        return const Color(0xFFFF9800); // Naranja
      case 'creatividad':
      case 'arte':
        return const Color(0xFFFF5722); // Naranja profundo
      case 'finanzas':
      case 'dinero':
        return const Color(0xFF607D8B); // Azul gris
      default:
        return const Color(0xFF4CAF50); // Verde por defecto
    }
  }
}