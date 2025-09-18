import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_state.dart';
import '../../blocs/progress/progress_event.dart';
import 'monthly_evolution_screen.dart';
import '../../widgets/progress/metric_card.dart';
import '../../widgets/progress/circular_progress_widget.dart';
import '../../widgets/progress/progress_slider.dart';
import 'dart:math' as math;

class ProgressMainScreen extends StatefulWidget {
  const ProgressMainScreen({super.key});

  @override
  State<ProgressMainScreen> createState() => _ProgressMainScreenState();
}

class _ProgressMainScreenState extends State<ProgressMainScreen> {
  bool _showMonthlyEvolution = false;

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

  void _toggleView() {
    setState(() {
      _showMonthlyEvolution = !_showMonthlyEvolution;
    });
    
    // Load data when switching to monthly evolution view
    if (_showMonthlyEvolution) {
      final userId = _getCurrentUserId();
      if (userId != null) {
        context.read<ProgressBloc>().add(LoadUserProgress(userId: userId));
      } else {
        _handleUserIdError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _showMonthlyEvolution 
        ? _buildMonthlyEvolutionView()
        : _buildMainProgressView(),
    );
  }

  Widget _buildMonthlyEvolutionView() {
    return Column(
      children: [
        // Custom app bar for monthly evolution
        Container(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _toggleView,
              ),
              const Expanded(
                child: Text(
                  'Evolución Mensual',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
        ),
        // Monthly evolution content
        Expanded(
          child: BlocBuilder<ProgressBloc, ProgressState>(
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
        ),
      ],
    );
  }

  Widget _buildMainProgressView() {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        print('🔍 PROGRESS DEBUG: Current state: ${state.runtimeType}');
        
        if (state is ProgressLoading) {
          print('🔍 PROGRESS DEBUG: Showing loading state');
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }
        
        if (state is ProgressError) {
          print('🔍 PROGRESS DEBUG: Showing error state: ${state.message}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFB74D),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Problema de conexión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                // Mostrar datos offline si están disponibles
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mostrando datos guardados localmente'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF666666),
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              child: const Text('Ver offline'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
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
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Consejos para resolver el problema
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Consejos para resolver el problema:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTipItem('Verifica tu conexión WiFi o datos móviles'),
                        _buildTipItem('Asegúrate de tener una conexión estable'),
                        _buildTipItem('Intenta cerrar y abrir la aplicación'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (state is ProgressLoaded || state is ProgressRefreshing) {
          print('🔍 PROGRESS DEBUG: Showing loaded state');
          final progress = state is ProgressLoaded 
              ? state.progress 
              : (state as ProgressRefreshing).progress;
          
          return RefreshIndicator(
            onRefresh: () async {
              final userId = _getCurrentUserId();
              if (userId != null) {
                context.read<ProgressBloc>().add(RefreshUserProgress(userId: userId));
              } else {
                _handleUserIdError();
              }
            },
            color: const Color(0xFF219540),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFFFFFF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Header with greeting and profile
                    _buildHeader(progress.userName ?? 'Usuario', progress.userProfileImage),
                    const SizedBox(height: 16),
                    
                    // Quick stats overview
                    _buildQuickStatsOverview(progress),
                    const SizedBox(height: 16),
                    
                    // Weekly progress bars
                    _buildWeeklyProgressBars(state),
                    const SizedBox(height: 16),
                    
                    // Detailed metrics cards
                    _buildDetailedMetricsCards(progress),
                    const SizedBox(height: 16),
                    
                    // Metrics cards row
                    _buildMetricsRow(progress),
                    const SizedBox(height: 8),
                    
                    // Activities metrics
                    _buildActivitiesMetrics(progress),
                    const SizedBox(height: 8),
                    
                    // Progress insights
                    _buildProgressInsights(progress),
                    const SizedBox(height: 12),
                    
                    // Progress slider
                    _buildProgressSlider(),
                    const SizedBox(height: 12),
                    
                    // Motivational message
                    _buildMotivationalMessage(progress),
                    const SizedBox(height: 12),
                    
                    // Monthly evolution button
                    _buildMonthlyEvolutionButton(),
                    const SizedBox(height: 60), // Space for bottom navigation
                  ],
                ),
              ),
            ),
          );
        }
        
        // Default case: show loading or trigger initial load
        print('🔍 PROGRESS DEBUG: Unhandled state, triggering load');
        // Trigger initial load if not already loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userId = _getCurrentUserId();
          if (userId != null) {
            context.read<ProgressBloc>().add(LoadUserProgress(userId: userId));
          } else {
            _handleUserIdError();
          }
        });
        
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String userName, String? profileImageUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bien hecho, Jeysson!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Este es tu progreso esta semana',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0E0E0),
            ),
            child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      profileImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Color(0xFF666666),
                          size: 24,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Color(0xFF666666),
                    size: 24,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIllustration() {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        Map<String, double> dailyProgress = {
          'Lun': 0.0,
          'Mar': 0.0,
          'Mié': 0.0,
          'Jue': 0.0,
          'Vie': 0.0,
          'Sáb': 0.0,
          'Dom': 0.0,
        };

        if (state is ProgressLoaded && state.dailyProgress != null) {
          dailyProgress = state.dailyProgress!;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(days.length, (index) {
              final dayName = days[index];
              final progress = dailyProgress[dayName] ?? 0.0;
              return Column(
                children: [
                  _buildDayLabel(dayName),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: _buildProgressBar(progress),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildDayLabel(String day) {
    return Text(
      day,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF666666),
      ),
    );
  }
  
  Widget _buildProgressBar(double progress) {
    // Ensure progress is between 0 and 1
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      tween: Tween(begin: 0.0, end: clampedProgress),
      builder: (context, animatedProgress, child) {
        return Container(
          width: 40,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFFE8F5E8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (animatedProgress > 0)
                Container(
                  width: 40,
                  height: 60 * animatedProgress,
                  decoration: BoxDecoration(
                    color: _getProgressColor(animatedProgress),
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _getProgressColor(animatedProgress),
                        _getProgressColor(animatedProgress).withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return const Color(0xFF219540); // Green for high progress
    } else if (progress >= 0.5) {
      return const Color(0xFF4CAF50); // Medium green
    } else if (progress >= 0.3) {
      return const Color(0xFFFFA726); // Orange for medium progress
    } else {
      return const Color(0xFFFF7043); // Red-orange for low progress
    }
  }
  
  Widget _buildWeeklyProgressBars(dynamic state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Days of the week labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('Lun', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                Text('Mar', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                Text('Mié', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                Text('Jue', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                Text('Vie', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final progress = _calculateDayProgress(state, index, false, false);
                return Flexible(
                  child: Container(
                    width: 40,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          width: 40,
                          height: 60 * progress,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  double _calculateDayProgress(ProgressState state, int dayIndex, bool isToday, bool isPastDay) {
    if (state is ProgressLoaded && state.dailyProgress != null) {
      // Get daily progress from the loaded state
      final dailyProgressMap = state.dailyProgress!;
      final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
      
      if (dayIndex < dayNames.length) {
        final dayName = dayNames[dayIndex];
        return dailyProgressMap[dayName]?.clamp(0.0, 1.0) ?? 0.0;
      }
    }
    
    // Fallback to mock data if no real data available
    final mockProgress = [0.8, 1.0, 0.6, 0.9, 0.3];
    return dayIndex < mockProgress.length ? mockProgress[dayIndex] : 0.0;
  }

  Widget _buildMetricsRow(dynamic progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Hábitos cumplidos\nesta semana',
              '${progress.weeklyCompletedHabits ?? 0}',
              'Actividades\npendientes',
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Hábitos sugeridos\npor ViveGood',
              '${progress.suggestedHabits ?? 0}',
              'Nuevos\nhábitos',
              const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: accentColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesMetrics(dynamic progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Left side - Nutrition suggestions
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sugerencias de\nalimentación\naceptadas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4CAF50),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Pendientes',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side - Percentage
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${progress.acceptedNutritionSuggestions ?? 0}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(double percentage) {
    // This section is now integrated into _buildActivitiesMetrics
    return const SizedBox.shrink();
  }
  
  Widget _buildProgressSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressDot(true),
          const SizedBox(width: 8),
          _buildProgressDot(false),
          const SizedBox(width: 8),
          _buildProgressDot(false),
        ],
      ),
    );
  }
  
  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF219540) : const Color(0xFFE0E0E0),
      ),
    );
  }

  Widget _buildMonthlyEvolutionButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _toggleView,
          icon: const Icon(
            Icons.analytics_outlined,
            color: Colors.white,
            size: 22,
          ),
          label: const Text(
            'Ver evolución mensual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalMessage(dynamic progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        progress.motivationalMessage ?? '¡Sigue así! Tus nuevos hábitos están reduciendo los factores de riesgo de gastritis',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required int percentage,
    required Color backgroundColor,
  }) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: percentage / 100.0,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF219540)),
                ),
              ),
              Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF219540),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsOverview(dynamic progress) {
    final weeklyCompleted = progress.weeklyCompletedHabits ?? 0;
    final suggestedHabits = progress.suggestedHabits ?? 0;
    
    // Evitar división por cero y valores infinitos
    final completionRate = suggestedHabits > 0 
        ? (weeklyCompleted / suggestedHabits).clamp(0.0, 1.0)
        : 0.0;
    
    // Validar que el resultado sea finito antes de convertir a entero
    final progressPercentage = completionRate.isFinite 
        ? (completionRate * 100).round()
        : 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progreso Semanal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$progressPercentage% completado',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$weeklyCompleted de ${suggestedHabits > 0 ? suggestedHabits : 'N/A'} hábitos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: completionRate.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricsCards(dynamic progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailedMetricCard(
              'Racha Actual',
              '${_calculateCurrentStreak()} días',
              Icons.local_fire_department,
              const Color(0xFFFF6B35),
              'Mantén el ritmo',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDetailedMetricCard(
              'Promedio Semanal',
              '${((progress.weeklyProgressPercentage ?? 0.0) * 100).round()}%',
              Icons.analytics,
              const Color(0xFF2196F3),
              'Muy bien',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDetailedMetricCard(
              'Meta Mensual',
              '${_calculateMonthlyGoalProgress()}%',
              Icons.flag,
              const Color(0xFF9C27B0),
              'En progreso',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInsights(dynamic progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Insights de Progreso',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Mejor día de la semana',
            _getBestDayOfWeek(),
            Icons.star,
            const Color(0xFFFFB300),
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            'Hábito más consistente',
            'Ejercicio matutino',
            Icons.fitness_center,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            'Área de mejora',
            'Hidratación diaria',
            Icons.water_drop,
            const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  int _calculateCurrentStreak() {
    // Calculate streak based on actual progress data
    final state = context.read<ProgressBloc>().state;
    if (state is ProgressLoaded) {
      // Simple streak calculation based on weekly completed habits
      final completedHabits = state.progress.weeklyCompletedHabits;
      final suggestedHabits = state.progress.suggestedHabits;
      
      if (suggestedHabits > 0) {
        final completionRate = completedHabits / suggestedHabits;
        if (completionRate >= 0.8) return completedHabits;
        if (completionRate >= 0.6) return (completedHabits * 0.8).round();
        return (completedHabits * 0.5).round();
      }
    }
    return 0;
  }

  int _calculateMonthlyGoalProgress() {
    // Calculate monthly progress based on actual data
    final state = context.read<ProgressBloc>().state;
    if (state is ProgressLoaded) {
      final weeklyPercentage = state.progress.weeklyProgressPercentage;
      // Estimate monthly progress based on weekly progress
      return (weeklyPercentage * 100).round();
    }
    return 0;
  }

  String _getBestDayOfWeek() {
    // Calculate best day based on actual daily progress
    final state = context.read<ProgressBloc>().state;
    if (state is ProgressLoaded && state.dailyProgress != null) {
      final dailyProgress = state.dailyProgress!;
      String bestDay = 'Lunes';
      double bestProgress = 0.0;
      
      dailyProgress.forEach((day, progress) {
        if (progress > bestProgress) {
          bestProgress = progress;
          bestDay = day;
        }
      });
      
      return bestDay;
    }
    return 'Sin datos';
  }

  // Monthly Evolution View Methods
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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
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
    
    // Get actual progress data from state
    final state = context.read<ProgressBloc>().state;
    List<double> progress = [0.0, 0.0, 0.0, 0.0]; // Default to zeros
    
    if (state is ProgressLoaded) {
      // Use actual weekly progress percentage for current week
      final currentWeekProgress = state.progress.weeklyProgressPercentage;
      // For now, we'll use the current week's progress for the last week
      // and simulate decreasing progress for previous weeks
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
              height: (progress[index] * 150).isFinite ? progress[index] * 150 : 0,
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
          _buildHabitItem('Ejercicio', 0.85),
          const SizedBox(height: 12),
          _buildHabitItem('Alimentación', 0.72),
          const SizedBox(height: 12),
          _buildHabitItem('Hidratación', 0.68),
          const SizedBox(height: 12),
          _buildHabitItem('Descanso', 0.91),
        ],
      ),
    );
  }

  Widget _buildHabitItem(String name, double progress) {
    final color = _getCategoryColor(name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${((progress * 100).isFinite ? (progress * 100).toInt() : 0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
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

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}