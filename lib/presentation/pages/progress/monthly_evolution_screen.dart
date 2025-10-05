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

class _MonthlyEvolutionScreenState extends State<MonthlyEvolutionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialLoad = true;

  // Helper method to get current user ID
  String? _getCurrentUserId() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser?.id?.isNotEmpty == true) {
      return currentUser!.id;
    }
    return null;
  }

  // Helper method to handle user ID validation and error
  void _handleUserIdError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Error: Usuario no autenticado. Por favor, inicia sesión nuevamente.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Cargar datos mensuales con optimización
    _loadMonthlyData();
  }

  void _loadMonthlyData() async {
    final userId = _getCurrentUserId();
    if (userId != null) {
      // Cargar datos en paralelo para mejor rendimiento
      final progressFuture = context.read<ProgressBloc>().add(LoadUserProgress(userId: userId));
      
      final now = DateTime.now();
      final breakdownFuture = context.read<HabitBreakdownBloc>().add(
        LoadMonthlyHabitsBreakdown(
          userId: userId,
          year: now.year,
          month: now.month,
        ),
      );

      // Simular un pequeño delay para mostrar la animación
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
        _animationController.forward();
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUserIdError();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                _isInitialLoad = true;
              });
              _animationController.reset();
              _loadMonthlyData();
            },
          ),
        ],
      ),
      body: _isInitialLoad
          ? _buildLoadingScreen()
          : BlocBuilder<ProgressBloc, ProgressState>(
              builder: (context, state) {
                if (state is ProgressLoading) {
                  return _buildLoadingScreen();
                }

                if (state is ProgressError) {
                  return _buildErrorScreen(state.message);
                }

                if (state is ProgressLoaded) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _loadMonthlyData();
                      },
                      color: const Color(0xFF4CAF50),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMonthlyOverview(state),
                            const SizedBox(height: 24),
                            _buildMonthlyChart(state),
                            const SizedBox(height: 24),
                            _buildCategoryPieChart(state),
                            const SizedBox(height: 24),
                            _buildHabitsBreakdown(state),
                            const SizedBox(height: 24),
                            _buildCategoryEvolutionChart(state),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return _buildNoDataScreen();
              },
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
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
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cargando evolución mensual...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analizando tus hábitos y progreso',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isInitialLoad = true;
                });
                _animationController.reset();
                _loadMonthlyData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay datos disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza a completar hábitos para ver tu evolución mensual',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                  '${((state.progress.weeklyProgressPercentage * 100).clamp(0.0, 100.0).isFinite ? (state.progress.weeklyProgressPercentage * 100).clamp(0.0, 100.0).toInt() : 0)}%',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Racha Actual',
                  '${state.userStreak ?? 0} días',
                  const Color(0xFFFF6B35),
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Hábitos Nuevos',
                  '${state.progress.newHabits}',
                  const Color(0xFF9C27B0),
                  Icons.add_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          SizedBox(height: 200, child: _buildWeeklyProgressChart(state)),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart(ProgressLoaded state) {
    final weeks = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    // Usar datos reales del estado
    final currentWeekProgress = state.progress.weeklyProgressPercentage;
    final progress = [
      (currentWeekProgress * 0.6).clamp(0.0, 1.0),
      (currentWeekProgress * 0.7).clamp(0.0, 1.0),
      (currentWeekProgress * 0.8).clamp(0.0, 1.0),
      currentWeekProgress.clamp(0.0, 1.0),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(weeks.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${((progress[index] * 100).clamp(0.0, 100.0).isFinite ? (progress[index] * 100).clamp(0.0, 100.0).toInt() : 0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: Duration(milliseconds: 800 + (index * 200)),
              width: 40,
              height: progress[index] * 150,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF66BB6A),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              weeks[index],
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryPieChart(ProgressLoaded state) {
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
            'Distribución por Categorías',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<HabitBreakdownBloc, HabitBreakdownState>(
            builder: (context, breakdownState) {
              if (breakdownState is HabitBreakdownLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );
              }

              if (breakdownState is HabitBreakdownLoaded && 
                  breakdownState.breakdown.isNotEmpty) {
                return _buildPieChartWidget(breakdownState.breakdown);
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No hay datos de categorías disponibles',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartWidget(List<dynamic> breakdown) {
    final total = breakdown.fold<double>(0, (sum, item) => sum + (item.completionPercentage ?? 0));
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomPaint(
                  painter: PieChartPainter(breakdown),
                  child: const SizedBox(
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: breakdown.take(5).map<Widget>((item) {
                    final color = _getCategoryColor(item.categoryName);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.categoryName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryEvolutionChart(ProgressLoaded state) {
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
            'Evolución por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<HabitBreakdownBloc, HabitBreakdownState>(
            builder: (context, breakdownState) {
              if (breakdownState is HabitBreakdownLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );
              }

              if (breakdownState is HabitBreakdownLoaded && 
                  breakdownState.breakdown.isNotEmpty) {
                return _buildCategoryEvolutionWidget(breakdownState.breakdown);
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No hay datos de evolución disponibles',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryEvolutionWidget(List<dynamic> breakdown) {
    return Column(
      children: breakdown.take(5).map<Widget>((item) {
        final color = _getCategoryColor(item.categoryName);
        final progress = (item.completionPercentage ?? 0) / 100;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${item.completionPercentage?.toInt() ?? 0}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
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
                        style: TextStyle(color: Colors.grey, fontSize: 14),
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
                    style: TextStyle(color: Colors.grey, fontSize: 14),
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
            child: Icon(icon, color: iconColor, size: 20),
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

// Custom painter para el gráfico de pastel
class PieChartPainter extends CustomPainter {
  final List<dynamic> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    
    final total = data.fold<double>(0, (sum, item) => sum + (item.completionPercentage ?? 0));
    
    if (total == 0) return;
    
    double startAngle = -90 * (3.14159 / 180); // Comenzar desde arriba
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final percentage = (item.completionPercentage ?? 0) / total;
      final sweepAngle = percentage * 2 * 3.14159;
      
      final paint = Paint()
        ..color = _getCategoryColorForPainter(item.categoryName)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Dibujar círculo interior para efecto donut
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.5, innerPaint);
  }

  Color _getCategoryColorForPainter(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ejercicio':
      case 'fitness':
      case 'deporte':
        return const Color(0xFFE91E63);
      case 'meditación':
      case 'mindfulness':
      case 'relajación':
        return const Color(0xFF9C27B0);
      case 'lectura':
      case 'estudio':
      case 'aprendizaje':
        return const Color(0xFF3F51B5);
      case 'agua':
      case 'hidratación':
        return const Color(0xFF2196F3);
      case 'alimentación':
      case 'nutrición':
      case 'comida':
        return const Color(0xFF4CAF50);
      case 'sueño':
      case 'descanso':
        return const Color(0xFF673AB7);
      case 'trabajo':
      case 'productividad':
        return const Color(0xFF795548);
      case 'social':
      case 'familia':
      case 'amigos':
        return const Color(0xFFFF9800);
      case 'creatividad':
      case 'arte':
        return const Color(0xFFFF5722);
      case 'finanzas':
      case 'dinero':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
