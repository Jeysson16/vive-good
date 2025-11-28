import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/habit_statistics.dart';
import '../../blocs/category_evolution/category_evolution_bloc.dart';
import '../../blocs/category_evolution/category_evolution_event.dart';
import '../../blocs/category_evolution/category_evolution_state.dart';
import '../../blocs/habit_breakdown/habit_breakdown_bloc.dart';
import '../../blocs/habit_breakdown/habit_breakdown_event.dart';
import '../../blocs/habit_breakdown/habit_breakdown_state.dart';
import '../../blocs/habit_statistics/habit_statistics_bloc.dart';
import '../../blocs/habit_statistics/habit_statistics_event.dart';
import '../../blocs/habit_statistics/habit_statistics_state.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_event.dart';
import '../../blocs/progress/progress_state.dart';
import '../../widgets/statistics/category_evolution_chart.dart';
import '../../widgets/statistics/category_selector_widget.dart';
import '../../widgets/statistics/category_unified_card.dart';
import '../../widgets/statistics/habit_statistics_card.dart';
import '../../widgets/statistics/statistics_summary_widget.dart';

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
  ProgressLoaded? _lastLoadedState; // cache del último estado cargado

  // Variables para el selector de mes y año
  late DateTime _selectedDate;
  final List<String> _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  // Helper method to get current user ID
  String? _getCurrentUserId() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser?.id.isNotEmpty == true) {
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
    _selectedDate = DateTime.now(); // Inicializar con el mes actual
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Cachear estado inicial si ya existe un ProgressLoaded para evitar spinner
    final initialProgressState = context.read<ProgressBloc>().state;
    if (initialProgressState is ProgressLoaded) {
      _lastLoadedState = initialProgressState;
    }

    // Cargar datos mensuales con optimización
    _loadMonthlyData();
  }

  void _loadMonthlyData() async {
    final userId = _getCurrentUserId();
    print('🔄 _loadMonthlyData: Starting data load for ${_selectedDate.year}-${_selectedDate.month}, userId: $userId');
    
    if (userId != null) {
      // Cargar datos de progreso para el mes específico seleccionado
      print('🔄 _loadMonthlyData: Dispatching LoadMonthlyProgressForDate');
      context.read<ProgressBloc>().add(
        LoadMonthlyProgressForDate(
          userId: userId,
          year: _selectedDate.year,
          month: _selectedDate.month,
        ),
      );

      // Preparar UI
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
        _animationController.forward();
      }

      // Phase 2: Secondary data - load immediately to show loading states
      print('🔄 _loadMonthlyData: Loading secondary data immediately');
      _loadSecondaryDataInParallel(userId);
    } else {
      print('❌ _loadMonthlyData: userId is null');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUserIdError();
      });
    }
  }

  void _loadSecondaryDataInParallel(String userId) {
    print('🔄 _loadSecondaryDataInParallel: Starting parallel data load for ${_selectedDate.year}-${_selectedDate.month}');
    
    // Execute all secondary BLoC loads simultaneously without waiting
    Future.wait([
      Future.microtask(
        () {
          print('🔄 Dispatching LoadMonthlyHabitsBreakdown for ${_selectedDate.year}-${_selectedDate.month}');
          return context.read<HabitBreakdownBloc>().add(
            LoadMonthlyHabitsBreakdown(
              userId: userId,
              year: _selectedDate.year,
              month: _selectedDate.month,
            ),
          );
        },
      ),
      Future.microtask(
        () {
          print('🔄 Dispatching LoadHabitStatistics for ${_selectedDate.year}-${_selectedDate.month}');
          return context.read<HabitStatisticsBloc>().add(
            LoadHabitStatistics(
              userId: userId,
              year: _selectedDate.year,
              month: _selectedDate.month,
            ),
          );
        },
      ),
      Future.microtask(
        () {
          print('🔄 Dispatching LoadCategoryEvolution for ${_selectedDate.year}-${_selectedDate.month}');
          return context.read<CategoryEvolutionBloc>().add(
            LoadCategoryEvolution(
              userId: userId,
              year: _selectedDate.year,
              month: _selectedDate.month,
            ),
          );
        },
      ),
    ]).then((_) {
      print('✅ _loadSecondaryDataInParallel: All secondary data loads dispatched successfully');
    }).catchError((error) {
      // Handle any errors in secondary data loading
      print('❌ Error loading secondary data: $error');
      debugPrint('Error loading secondary data: $error');
    });
  }

  // Método para mostrar el selector de mes y año
  void _showMonthYearPicker() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _MonthYearPickerDialog(
          selectedDate: _selectedDate,
          months: _months,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      print('📅 Date changed from ${_selectedDate.year}-${_selectedDate.month} to ${picked.year}-${picked.month}');
      setState(() {
        _selectedDate = picked;
        _isInitialLoad = true;
      });
      _animationController.reset();
      print('📅 Calling _loadMonthlyData after date change');
      _loadMonthlyData();
    } else {
      print('📅 Date picker cancelled or same date selected');
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
        title: GestureDetector(
          onTap: _showMonthYearPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black,
                size: 20,
              ),
            ],
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
      body: BlocConsumer<ProgressBloc, ProgressState>(
        buildWhen: (previous, current) {
          // Siempre permitir reconstrucción cuando llega ProgressLoaded
          if (current is ProgressLoaded) return true;
          // Evitar reconstrucciones por ProgressLoading si ya hay datos cacheados
          if (_lastLoadedState != null && current is ProgressLoading) {
            return false;
          }
          return true;
        },
        listenWhen: (previous, current) =>
            current is ProgressLoaded || current is ProgressError,
        listener: (context, state) {
          if (state is ProgressLoaded) {
            _lastLoadedState = state;
            if (mounted) {
              // Asegurar animación y actualización inmediata al cargar datos
              _animationController.forward();
              setState(() {});
            }
          }
        },
        builder: (context, state) {
          final ProgressLoaded? effectiveState = state is ProgressLoaded
              ? state
              : _lastLoadedState;
          if (state is ProgressError) {
            return _buildErrorScreen(state.message);
          }

          if (effectiveState != null) {
            // Check if there's actually data to display
            if (effectiveState.monthlyProgress == null ||
                effectiveState.monthlyProgress!.isEmpty) {
              return _buildNoDataScreen();
            }

            // Renderizar contenido directamente sin skeletons

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
                      _buildMonthlyOverview(effectiveState),
                      const SizedBox(height: 24),
                      _buildMonthlyChart(effectiveState),
                      const SizedBox(height: 24),
                      _buildStatisticsSummaryWithSkeleton(),
                      const SizedBox(height: 24),
                      _buildCategoryPieChart(effectiveState),
                      const SizedBox(height: 24),
                      _buildUnifiedCategorySectionWithSkeleton(),
                    ],
                  ),
                ),
              ),
            );
          }

          // Vista mínima de carga sin texto si aún no hay datos cacheados
          return _buildInitialSpinner();
        },
      ),
    );
  }

  Widget _buildInitialSpinner() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF4CAF50),
        strokeWidth: 3,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
                  _formatMonthlyTotal(state),
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
                  const Color(0xFF4CAF50),
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Hábitos Nuevos',
                  '${state.progress.newHabits}',
                  const Color(0xFF2196F3),
                  Icons.add_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMonthlyTotal(ProgressLoaded state) {
    double avg = 0.0;
    if (state.monthlyProgress != null && state.monthlyProgress!.isNotEmpty) {
      avg =
          state.monthlyProgress!
              .map((p) => p.weeklyProgressPercentage)
              .fold(0.0, (a, b) => a + b) /
          state.monthlyProgress!.length;
    } else {
      avg = state.progress.weeklyProgressPercentage;
    }
    final pct = (avg * 100).clamp(0.0, 100.0);
    return '${pct.isFinite ? pct.toInt() : 0}%';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStatisticsSummaryWithSkeleton() {
    return BlocBuilder<HabitStatisticsBloc, HabitStatisticsState>(
      builder: (context, statisticsState) {
        print('DEBUG: HabitStatisticsState: ${statisticsState.runtimeType}');
        
        if (statisticsState is HabitStatisticsLoaded &&
            statisticsState.statistics.isNotEmpty) {
          print('DEBUG: Showing statistics data with ${statisticsState.statistics.length} items');
          return StatisticsSummaryWidget(
            statistics: statisticsState.statistics,
          );
        }

        if (statisticsState is HabitStatisticsRefreshing &&
            statisticsState.currentStatistics.isNotEmpty) {
          print('DEBUG: Showing refreshing statistics with ${statisticsState.currentStatistics.length} items');
          return StatisticsSummaryWidget(
            statistics: statisticsState.currentStatistics,
          );
        }

        if (statisticsState is HabitStatisticsError) {
          print('DEBUG: HabitStatisticsError: ${statisticsState.message}');
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
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error al cargar datos: Servicio temporalmente no disponible. Intenta nuevamente en unos momentos.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (statisticsState is HabitStatisticsLoaded &&
            statisticsState.statistics.isEmpty) {
          print('DEBUG: No statistics data available');
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
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay datos disponibles para este período',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar skeleton mientras carga
        print('DEBUG: Showing statistics skeleton');
        return _buildStatisticsSkeleton();
      },
    );
  }

  Widget _buildStatisticsSkeleton() {
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
          // Title skeleton
          Container(
            height: 24,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Stats skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSummary() {
    return BlocBuilder<HabitStatisticsBloc, HabitStatisticsState>(
      builder: (context, statisticsState) {
        if (statisticsState is HabitStatisticsLoaded &&
            statisticsState.statistics.isNotEmpty) {
          return StatisticsSummaryWidget(
            statistics: statisticsState.statistics,
          );
        }

        if (statisticsState is HabitStatisticsRefreshing &&
            statisticsState.currentStatistics.isNotEmpty) {
          return StatisticsSummaryWidget(
            statistics: statisticsState.currentStatistics,
          );
        }

        if (statisticsState is HabitStatisticsLoading) {
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
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            ),
          );
        }

        // Si no hay datos, no mostrar nada
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMonthlyChart(ProgressLoaded state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
    // Preferir datos mensuales reales si están disponibles
    List<double> progress = [];
    if (state.monthlyProgress != null && state.monthlyProgress!.isNotEmpty) {
      progress = state.monthlyProgress!
          .map((p) => p.weeklyProgressPercentage.clamp(0.0, 1.0))
          .toList();
    }
    // Fallback a aproximación basada en la semana actual
    if (progress.length != 4) {
      final currentWeekProgress = state.progress.weeklyProgressPercentage;
      progress = [
        (currentWeekProgress * 0.6).clamp(0.0, 1.0),
        (currentWeekProgress * 0.7).clamp(0.0, 1.0),
        (currentWeekProgress * 0.8).clamp(0.0, 1.0),
        currentWeekProgress.clamp(0.0, 1.0),
      ];
    }

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (breakdownState is HabitBreakdownLoaded &&
                  breakdownState.breakdown.isNotEmpty) {
                // Verificar si hay datos significativos (al menos un hábito completado)
                final hasSignificantData = breakdownState.breakdown.any((item) => 
                  (item.completedHabits ?? 0) > 0 || (item.completionPercentage ?? 0) > 0);
                
                if (hasSignificantData) {
                  return _buildPieChartWidget(breakdownState.breakdown);
                } else {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.pie_chart_outline,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No hay actividad registrada en este período',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
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
                          'Error al cargar distribución: ${breakdownState.message}',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
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
    final total = breakdown.fold<double>(
      0,
      (sum, item) => sum + (item.completionPercentage ?? 0),
    );

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
                  child: const SizedBox(width: 150, height: 150),
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: breakdown.take(5).map<Widget>((item) {
                      final color = _parseColorFromHex(item.categoryColor);
                      final percentage = total > 0
                          ? (item.completionPercentage / total * 100)
                          : 0;
                      final completedHabits = item.completedHabits ?? 0;
                      final totalHabits = item.totalHabits ?? 0;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.categoryName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$completedHabits/$totalHabits hábitos - ${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedCategorySectionWithSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título principal
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Análisis por Categoría',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cards unificados por categoría
        BlocBuilder<CategoryEvolutionBloc, CategoryEvolutionState>(
          builder: (context, evolutionState) {
            print('DEBUG: CategoryEvolutionState: ${evolutionState.runtimeType}');
            return BlocBuilder<HabitStatisticsBloc, HabitStatisticsState>(
              builder: (context, statisticsState) {
                print('DEBUG: HabitStatisticsState in categories: ${statisticsState.runtimeType}');
                
                // Manejar errores
                if (evolutionState is CategoryEvolutionError) {
                  print('DEBUG: CategoryEvolutionError: ${evolutionState.message}');
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error al cargar datos: Servicio temporalmente no disponible. Intenta nuevamente en unos momentos.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (statisticsState is HabitStatisticsError) {
                  print('DEBUG: HabitStatisticsError in categories: ${statisticsState.message}');
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error al cargar datos: Servicio temporalmente no disponible. Intenta nuevamente en unos momentos.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Si ambos están cargados pero no hay datos
                if (evolutionState is CategoryEvolutionLoaded &&
                    statisticsState is HabitStatisticsLoaded &&
                    evolutionState.evolution.isEmpty &&
                    statisticsState.statistics.isEmpty) {
                  print('DEBUG: No data available for both evolution and statistics');
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay datos disponibles para este período',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Si hay datos de evolución
                if (evolutionState is CategoryEvolutionLoaded &&
                    evolutionState.evolution.isNotEmpty) {
                  print('DEBUG: Showing category evolution data with ${evolutionState.evolution.length} categories');
                  // Obtener estadísticas si están disponibles
                  final statistics = statisticsState is HabitStatisticsLoaded
                      ? statisticsState.statistics
                      : <dynamic>[];
                  print('DEBUG: Statistics available: ${statistics.length} items');

                  return Column(
                    children: evolutionState.evolution.map((evolution) {
                      // Buscar estadísticas correspondientes a esta categoría
                      HabitStatistics? categoryStats;
                      if (statistics.isNotEmpty) {
                        try {
                          categoryStats = statistics.firstWhere(
                            (stat) =>
                                stat.categoryName.toLowerCase() ==
                                evolution.categoryName.toLowerCase(),
                          );
                        } catch (e) {
                          categoryStats = null;
                        }
                      }

                      return CategoryUnifiedCard(
                        evolution: evolution,
                        statistics: categoryStats,
                      );
                    }).toList(),
                  );
                }

                // Mostrar skeleton mientras carga
                print('DEBUG: Showing category skeleton - evolutionState: ${evolutionState.runtimeType}, statisticsState: ${statisticsState.runtimeType}');
                return _buildCategorySkeleton();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorySkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
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
              // Category title skeleton
              Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar skeleton
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Stats skeleton
              Row(
                children: [
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título principal
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Análisis por Categoría',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cards unificados por categoría
        BlocBuilder<CategoryEvolutionBloc, CategoryEvolutionState>(
          builder: (context, evolutionState) {
            return BlocBuilder<HabitStatisticsBloc, HabitStatisticsState>(
              builder: (context, statisticsState) {
                if (evolutionState is CategoryEvolutionLoading ||
                    statisticsState is HabitStatisticsLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  );
                }

                if (evolutionState is CategoryEvolutionError) {
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
                            'Error al cargar datos: ${evolutionState.message}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (evolutionState is CategoryEvolutionLoaded) {
                  if (evolutionState.evolution.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No hay datos disponibles para este período',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  // Obtener estadísticas si están disponibles
                  final statistics = statisticsState is HabitStatisticsLoaded
                      ? statisticsState.statistics
                      : <dynamic>[];

                  return Column(
                    children: evolutionState.evolution.map((evolution) {
                      // Buscar estadísticas correspondientes a esta categoría
                      HabitStatistics? categoryStats;
                      if (statistics.isNotEmpty) {
                        try {
                          categoryStats = statistics.firstWhere(
                            (stat) =>
                                stat.categoryName.toLowerCase() ==
                                evolution.categoryName.toLowerCase(),
                          );
                        } catch (e) {
                          categoryStats = null;
                        }
                      }

                      return CategoryUnifiedCard(
                        evolution: evolution,
                        statistics: categoryStats,
                      );
                    }).toList(),
                  );
                }

                if (evolutionState is CategoryEvolutionRefreshing) {
                  final currentEvolution = evolutionState.currentEvolution;
                  final statistics = statisticsState is HabitStatisticsLoaded
                      ? statisticsState.statistics
                      : <dynamic>[];

                  return Column(
                    children: [
                      const LinearProgressIndicator(
                        color: Color(0xFF4CAF50),
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      ...currentEvolution.map((evolution) {
                        HabitStatistics? categoryStats;
                        if (statistics.isNotEmpty) {
                          try {
                            categoryStats = statistics.firstWhere(
                              (stat) =>
                                  stat.categoryName.toLowerCase() ==
                                  evolution.categoryName.toLowerCase(),
                            );
                          } catch (e) {
                            categoryStats = null;
                          }
                        }

                        return CategoryUnifiedCard(
                          evolution: evolution,
                          statistics: categoryStats,
                        );
                      }),
                    ],
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryEvolutionSection() {
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
            'Análisis Temporal por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<CategoryEvolutionBloc, CategoryEvolutionState>(
            builder: (context, evolutionState) {
              if (evolutionState is CategoryEvolutionLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );
              }

              if (evolutionState is CategoryEvolutionError) {
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
                          'Error al cargar evolución: ${evolutionState.message}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (evolutionState is CategoryEvolutionLoaded) {
                if (evolutionState.evolution.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay datos de evolución disponibles para este período',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Selector de categorías
                    CategorySelectorWidget(
                      categories: evolutionState.evolution,
                      selectedCategoryId: evolutionState.selectedCategoryId,
                      onCategorySelected: (categoryId) {
                        context.read<CategoryEvolutionBloc>().add(
                          SelectCategory(categoryId),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Gráfico de evolución
                    ...evolutionState.evolution
                        .where(
                          (evolution) =>
                              evolutionState.selectedCategoryId == null ||
                              evolution.categoryId.toString() ==
                                  evolutionState.selectedCategoryId,
                        )
                        .map(
                          (evolution) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CategoryEvolutionChart(evolution: evolution),
                          ),
                        )
                        ,
                  ],
                );
              }

              if (evolutionState is CategoryEvolutionRefreshing) {
                return Column(
                  children: [
                    const LinearProgressIndicator(
                      color: Color(0xFF4CAF50),
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    // Selector de categorías
                    CategorySelectorWidget(
                      categories: evolutionState.currentEvolution,
                      selectedCategoryId: evolutionState.selectedCategoryId,
                      onCategorySelected: (categoryId) {
                        context.read<CategoryEvolutionBloc>().add(
                          SelectCategory(categoryId),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Gráfico de evolución
                    ...evolutionState.currentEvolution
                        .where(
                          (evolution) =>
                              evolutionState.selectedCategoryId == null ||
                              evolution.categoryId.toString() ==
                                  evolutionState.selectedCategoryId,
                        )
                        .map(
                          (evolution) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CategoryEvolutionChart(evolution: evolution),
                          ),
                        )
                        ,
                  ],
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

  Widget _buildHabitStatisticsSection() {
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
            'Estadísticas Detalladas por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<HabitStatisticsBloc, HabitStatisticsState>(
            builder: (context, statisticsState) {
              if (statisticsState is HabitStatisticsLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );
              }

              if (statisticsState is HabitStatisticsError) {
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
                          'Error al cargar estadísticas: ${statisticsState.message}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (statisticsState is HabitStatisticsLoaded) {
                if (statisticsState.statistics.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay estadísticas disponibles para este período',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Column(
                  children: statisticsState.statistics.map((statistics) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: HabitStatisticsCard(statistics: statistics),
                    );
                  }).toList(),
                );
              }

              if (statisticsState is HabitStatisticsRefreshing) {
                return Column(
                  children: [
                    const LinearProgressIndicator(
                      color: Color(0xFF4CAF50),
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    ...statisticsState.currentStatistics.map((statistics) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HabitStatisticsCard(statistics: statistics),
                      );
                    }),
                  ],
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

  Color _parseColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF9E9E9E); // Color gris por defecto
    }

    try {
      String colorString = hexColor.replaceAll('#', '');
      if (colorString.length == 6) {
        colorString = 'FF$colorString'; // Agregar alpha si no está presente
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return const Color(0xFF9E9E9E); // Color gris por defecto en caso de error
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

    final total = data.fold<double>(
      0,
      (sum, item) => sum + (item.completionPercentage ?? 0),
    );

    if (total == 0) return;

    double startAngle = -90 * (3.14159 / 180); // Comenzar desde arriba

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final percentage = (item.completionPercentage ?? 0) / total;
      final sweepAngle = percentage * 2 * 3.14159;

      final paint = Paint()
        ..color = _parseColorFromHex(item.categoryColor, i)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dibujar porcentaje en el segmento si es lo suficientemente grande
      if (percentage > 0.08) {
        // Solo mostrar si el segmento es mayor al 8%
        final middleAngle = startAngle + sweepAngle / 2;
        final textRadius = radius * 0.75;
        final textX = center.dx + textRadius * math.cos(middleAngle);
        final textY = center.dy + textRadius * math.sin(middleAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(percentage * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        final textOffset = Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }

      startAngle += sweepAngle;
    }

    // Dibujar círculo interior para efecto donut
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, innerPaint);
  }

  Color _parseColorFromHex(String? hexColor, int index) {
    if (hexColor == null || hexColor.isEmpty) {
      // Colores alternativos para categorías sin color definido
      final colors = [
        const Color(0xFF9E9E9E),
        const Color(0xFF00BCD4),
        const Color(0xFF8BC34A),
        const Color(0xFFCDDC39),
        const Color(0xFFFFC107),
        const Color(0xFFFF5722),
        const Color(0xFF3F51B5),
        Colors.white,
      ];
      return colors[index % colors.length];
    }

    try {
      String colorString = hexColor.replaceAll('#', '');
      if (colorString.length == 6) {
        colorString = 'FF$colorString'; // Agregar alpha si no está presente
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      // Color de respaldo en caso de error
      final colors = [
        const Color(0xFF9E9E9E),
        const Color(0xFF00BCD4),
        const Color(0xFF8BC34A),
        const Color(0xFFCDDC39),
        const Color(0xFFFFC107),
        const Color(0xFFFF5722),
        const Color(0xFF3F51B5),
        Colors.white,
      ];
      return colors[index % colors.length];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget del diálogo selector de mes y año
class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final List<String> months;

  const _MonthYearPickerDialog({
    required this.selectedDate,
    required this.months,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.selectedDate.year;
    selectedMonth = widget.selectedDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Seleccionar Mes y Año',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 300,
        height: 200,
        child: Column(
          children: [
            // Selector de año
            Row(
              children: [
                const Text('Año: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(10, (index) {
                      final year = DateTime.now().year - 5 + index;
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (int? newYear) {
                      if (newYear != null) {
                        setState(() {
                          selectedYear = newYear;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Selector de mes
            Row(
              children: [
                const Text('Mes: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(widget.months[index]),
                      );
                    }),
                    onChanged: (int? newMonth) {
                      if (newMonth != null) {
                        setState(() {
                          selectedMonth = newMonth;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final newDate = DateTime(selectedYear, selectedMonth);
            Navigator.of(context).pop(newDate);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }
}
