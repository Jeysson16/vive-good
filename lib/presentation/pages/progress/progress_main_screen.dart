import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../blocs/auth/auth_bloc.dart' as app_auth;
import '../../blocs/auth/auth_state.dart' as app_auth_state;
import '../../blocs/category_evolution/category_evolution_bloc.dart';
import '../../blocs/habit_breakdown/habit_breakdown_bloc.dart';
import '../../blocs/habit_breakdown/habit_breakdown_event.dart';
import '../../blocs/habit_statistics/habit_statistics_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_event.dart';
import '../../blocs/progress/progress_state.dart';
import 'monthly_evolution_screen.dart';

class ProgressMainScreen extends StatefulWidget {
  const ProgressMainScreen({super.key});

  @override
  State<ProgressMainScreen> createState() => _ProgressMainScreenState();
}

class _ProgressMainScreenState extends State<ProgressMainScreen> {
  // Carrusel de insights: controlador y página actual
  final PageController _insightsController = PageController(
    viewportFraction: 0.92,
  );
  int _insightsPage = 0;

  // Cache variables to avoid unnecessary reloads
  DateTime? _lastMonthlyDataLoad;
  DateTime? _lastHabitBreakdownLoad;
  DateTime? _lastProgressDataLoad;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  bool _isReturningFromEvolution = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Load initial data when screen is first opened
  void _loadInitialData() {
    final userId = _getCurrentUserId();
    print('🔍 ProgressMainScreen: _loadInitialData called, userId: $userId');

    if (userId != null) {
      final now = DateTime.now();

      // Check if we need to reload progress data (cache validation)
      if (_lastProgressDataLoad == null ||
          now.difference(_lastProgressDataLoad!) > _cacheValidDuration ||
          !_isReturningFromEvolution) {
        print(
          '🔍 ProgressMainScreen: Dispatching LoadUserProgress event for userId: $userId',
        );
        // Load main progress data immediately
        context.read<ProgressBloc>().add(LoadUserProgress(userId: userId));
        _lastProgressDataLoad = now;
      } else {
        print(
          '🔍 ProgressMainScreen: Skipping LoadUserProgress due to cache validation',
        );
      }

      // Preload monthly data for faster access later
      print('🔍 ProgressMainScreen: Calling _preloadMonthlyData()');
      _preloadMonthlyData();
    } else {
      print('❌ ProgressMainScreen: userId is null, calling _handleUserIdError');
      _handleUserIdError();
    }
  }

  // Force refresh and invalidate cache
  void _forceRefreshData() {
    _lastMonthlyDataLoad = null;
    _lastHabitBreakdownLoad = null;
    _lastProgressDataLoad = null;
    _isReturningFromEvolution = false;
    _loadInitialData();
  }

  // Preload monthly data in background for faster access
  void _preloadMonthlyData() async {
    print('🔍 ProgressMainScreen: _preloadMonthlyData() started');
    final userId = _getCurrentUserId();
    print('🔍 ProgressMainScreen: userId = $userId');
    if (userId != null) {
      final now = DateTime.now();

      // Always load monthly indicators for the cards in the main view
      // Check if monthly progress data needs to be loaded (cache validation)
      if (_lastMonthlyDataLoad == null ||
          now.difference(_lastMonthlyDataLoad!) > _cacheValidDuration) {
        print('🔍 ProgressMainScreen: Dispatching LoadMonthlyProgress event');
        context.read<ProgressBloc>().add(LoadMonthlyProgress(userId: userId));
        _lastMonthlyDataLoad = now;
      } else {
        print(
          '🔍 ProgressMainScreen: Skipping LoadMonthlyProgress due to cache validation',
        );
      }

      // Load habit breakdown data for monthly view
      // Check if habit breakdown data needs to be loaded (cache validation)
      if (_lastHabitBreakdownLoad == null ||
          now.difference(_lastHabitBreakdownLoad!) > _cacheValidDuration) {
        context.read<HabitBreakdownBloc>().add(
          LoadMonthlyHabitsBreakdown(
            userId: userId,
            year: now.year,
            month: now.month,
          ),
        );
        _lastHabitBreakdownLoad = now;
      }
    }
  }

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

  void _navigateToMonthlyEvolution() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MonthlyEvolutionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            print(
              'ProgressMainScreen - ProfileBloc estado: ${state.runtimeType}',
            );
            if (state is ProfileUpdated || state is ProfileImageUpdated) {
              print(
                'ProgressMainScreen - Perfil actualizado, recargando datos de progreso',
              );
              // Recargar los datos de progreso cuando el perfil se actualiza
              _loadInitialData();
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            // Main content
            Expanded(child: _buildMainProgressView()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _insightsController.dispose();
    super.dispose();
  }

  Widget _buildMainProgressView() {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        if (state is ProgressLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        if (state is ProgressError) {
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
                                    content: Text(
                                      'Mostrando datos guardados localmente',
                                    ),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF666666),
                                side: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              child: const Text('Ver offline'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                final userId = _getCurrentUserId();
                                if (userId != null) {
                                  context.read<ProgressBloc>().add(
                                    LoadUserProgress(userId: userId),
                                  );
                                } else {
                                  _handleUserIdError();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
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
                        _buildTipItem(
                          'Verifica tu conexión WiFi o datos móviles',
                        ),
                        _buildTipItem(
                          'Asegúrate de tener una conexión estable',
                        ),
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
          final progress = state is ProgressLoaded
              ? state.progress
              : (state as ProgressRefreshing).progress;

          return RefreshIndicator(
            onRefresh: () async {
              final userId = _getCurrentUserId();
              if (userId != null) {
                context.read<ProgressBloc>().add(
                  RefreshUserProgress(userId: userId),
                );
              } else {
                _handleUserIdError();
              }
            },
            color: const Color(0xFF219540),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFFFFFF),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Header with greeting and profile
                        Builder(
                          builder: (context) {
                            String headerName = progress.userName;
                            final authState = context
                                .read<app_auth.AuthBloc>()
                                .state;
                            if (authState is app_auth_state.AuthAuthenticated) {
                              headerName = authState.user.name;
                            }
                            return _buildHeader(
                              headerName.isNotEmpty ? headerName : 'Usuario',
                              progress.userProfileImage,
                            );
                          },
                        ),
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
                        const SizedBox(
                          height: 60,
                        ), // Space for bottom navigation
                      ],
                    ),
                  ),
                  if (state is ProgressRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        color: Colors.white.withOpacity(0.85),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Actualizando...',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Default case: show loading or trigger initial load
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
                  'Bien hecho, ${userName.split(' ').first}!',
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
                : const Icon(Icons.person, color: Color(0xFF666666), size: 24),
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
        } else if (state is ProgressRefreshing &&
            (state).dailyProgress != null) {
          dailyProgress = (state).dailyProgress!;
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
                  SizedBox(height: 60, child: _buildProgressBar(progress)),
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
                Text(
                  'Lun',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                Text(
                  'Mar',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                Text(
                  'Mié',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                Text(
                  'Jue',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                Text(
                  'Vie',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                Text(
                  'Sáb',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                Text(
                  'Dom',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final progress = _calculateDayProgress(
                  state,
                  index,
                  false,
                  false,
                );
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

  double _calculateDayProgress(
    ProgressState state,
    int dayIndex,
    bool isToday,
    bool isPastDay,
  ) {
    Map<String, double>? dailyProgressMap;
    if (state is ProgressLoaded && state.dailyProgress != null) {
      // Get daily progress from the loaded state
      dailyProgressMap = state.dailyProgress!;
    } else if (state is ProgressRefreshing && (state).dailyProgress != null) {
      dailyProgressMap = (state).dailyProgress!;
    }
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    if (dailyProgressMap != null && dayIndex < dayNames.length) {
      final dayName = dayNames[dayIndex];
      return dailyProgressMap[dayName]?.clamp(0.0, 1.0) ?? 0.0;
    }

    // Fallback to mock data if no real data available
    final mockProgress = [0.8, 1.0, 0.6, 0.9, 0.3, 0.7, 0.5];
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
              'Actividades\ncumplidas',
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
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
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
                          'Alimentación',
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
    // El carrusel de insights ahora dibuja sus propios puntos dinámicos.
    // Este slider se oculta para evitar confusión.
    return const SizedBox.shrink();
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
          onPressed: () async {
            final userId = _getCurrentUserId();
            if (userId != null) {
              // Evitar prefetch para no forzar estados Loading justo antes de navegar
              // La MonthlyEvolutionScreen usa caché del último ProgressLoaded
            }

            // Marcar que vamos a la pantalla de evolución
            _isReturningFromEvolution = false;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<ProgressBloc>()),
                    BlocProvider.value(
                      value: context.read<HabitBreakdownBloc>(),
                    ),
                    BlocProvider.value(
                      value: context.read<HabitStatisticsBloc>(),
                    ),
                    BlocProvider.value(
                      value: context.read<CategoryEvolutionBloc>(),
                    ),
                  ],
                  child: const MonthlyEvolutionScreen(),
                ),
              ),
            );

            // Marcar que regresamos de la pantalla de evolución
            _isReturningFromEvolution = true;
          },
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
    // Obtener el progreso del día actual desde el estado del BLoC
    final state = context.read<ProgressBloc>().state;
    double todayProgress = 0.0;
    int completedToday = 0;
    final suggestedHabits = progress.suggestedHabits ?? 0;

    if (state is ProgressLoaded && state.dailyProgress != null) {
      // Determinar qué día de la semana es hoy
      final now = DateTime.now();
      final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final todayIndex = (now.weekday - 1) % 7; // 0 = Lunes, 6 = Domingo
      final todayName = dayNames[todayIndex];

      // Obtener el progreso del día actual
      todayProgress = state.dailyProgress![todayName] ?? 0.0;
      completedToday = (todayProgress * suggestedHabits).round();
    } else if (state is ProgressRefreshing && (state).dailyProgress != null) {
      final now = DateTime.now();
      final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final todayIndex = (now.weekday - 1) % 7;
      final todayName = dayNames[todayIndex];
      todayProgress = (state).dailyProgress![todayName] ?? 0.0;
      completedToday = (todayProgress * suggestedHabits).round();
    }

    // Calcular porcentaje basado en el progreso del día actual
    final progressPercentage = (todayProgress * 100).round();

    // Generar mensaje dinámico basado en el progreso real del día actual
    String dynamicMessage;
    Color messageColor;
    IconData messageIcon;

    if (progressPercentage >= 80) {
      dynamicMessage =
          '¡Excelente progreso! Has completado $completedToday de $suggestedHabits hábitos hoy. ¡Sigue así!';
      messageColor = const Color(0xFF4CAF50);
      messageIcon = Icons.celebration;
    } else if (progressPercentage >= 50) {
      dynamicMessage =
          '¡Buen trabajo! Has completado $completedToday de $suggestedHabits hábitos hoy. Estás en el camino correcto.';
      messageColor = const Color(0xFF2196F3);
      messageIcon = Icons.trending_up;
    } else if (progressPercentage > 0) {
      dynamicMessage =
          '¡Sigue adelante! Has completado $completedToday de $suggestedHabits hábitos hoy. Cada paso cuenta.';
      messageColor = const Color(0xFFFF9800);
      messageIcon = Icons.emoji_events;
    } else {
      dynamicMessage =
          '¡Es un nuevo día! Tienes $suggestedHabits hábitos esperándote. ¡Comienza ahora!';
      messageColor = const Color(0xFF9C27B0);
      messageIcon = Icons.rocket_launch;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
      ), // Reducir margen para mayor ancho
      padding: const EdgeInsets.all(20), // Aumentar padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            messageColor.withOpacity(0.1),
            messageColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // Bordes más redondeados
        border: Border.all(color: messageColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: messageColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: messageColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(messageIcon, color: messageColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              dynamicMessage,
              style: TextStyle(
                fontSize: 15, // Aumentar tamaño de fuente
                fontWeight: FontWeight.w500, // Hacer texto más prominente
                color: const Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ),
        ],
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF219540),
                  ),
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
    final activeHabits = progress.suggestedHabits ?? 0; // total activos
    final possibleActions = activeHabits * 7; // acciones posibles por semana

    // Calcular el porcentaje basado en los datos reales para mayor precisión
    double completionRate = 0.0;
    if (possibleActions > 0) {
      completionRate = (weeklyCompleted / possibleActions).clamp(0.0, 1.0);
    } else {
      // Fallback al porcentaje del backend si no hay datos de acciones
      completionRate = (progress.weeklyProgressPercentage ?? 0.0).clamp(
        0.0,
        1.0,
      );
    }

    final progressPercentage = ((completionRate * 100).isFinite
        ? (completionRate * 100).round()
        : 0);

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
                  '$weeklyCompleted de ${possibleActions > 0 ? possibleActions : 'N/A'} acciones',
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(Icons.trending_up, color: Colors.white, size: 24),
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
              '${_calculateWeeklyAverage()}%',
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
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
            child: Icon(icon, color: color, size: 20),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final insightCards = <Widget>[
                // 1. CARD DE HÁBITOS ACTUALES
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildInsightCard(
                    'Hábitos Actuales',
                    Icons.fitness_center,
                    const Color(0xFF4CAF50),
                    [
                      _buildInsightMetric(
                        'Mejor día de la semana',
                        _getMonthlyIndicator('best_day') ?? _getBestDayOfWeek(),
                        Icons.star,
                        const Color(0xFFFFB300),
                      ),
                      _buildInsightMetric(
                        'Hábito más consistente',
                        _getMonthlyIndicator('most_consistent_habit') ??
                            'Ejercicio matutino',
                        Icons.fitness_center,
                        const Color(0xFF4CAF50),
                      ),
                      _buildInsightMetric(
                        'Mejor categoría',
                        _getMonthlyIndicator('best_category') ??
                            'Actividad física',
                        Icons.category,
                        const Color(0xFF2196F3),
                      ),
                      _buildInsightMetric(
                        'Categoría que necesita atención',
                        _getMonthlyIndicator('needs_attention_category') ??
                            'Hidratación',
                        Icons.priority_high,
                        const Color(0xFFFF5722),
                      ),
                    ],
                  ),
                ),

                // 2. CARD DE ANÁLISIS TEMPORAL
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildInsightCard(
                    'Análisis Temporal',
                    Icons.timeline,
                    const Color(0xFF2196F3),
                    [
                      _buildInsightMetric(
                        'Cambio vs semana anterior',
                        _getMonthlyIndicator('weekly_change') ?? '+0%',
                        Icons.trending_up,
                        const Color(0xFF4CAF50),
                      ),
                      _buildInsightMetric(
                        'Racha actual',
                        _getMonthlyIndicator('current_streak') ?? '0 días',
                        Icons.local_fire_department,
                        const Color(0xFFFF9800),
                      ),
                      _buildInsightMetric(
                        'Variedad de hábitos',
                        _getMonthlyIndicator('habit_variety') ?? '0 hábitos',
                        Icons.diversity_3,
                        const Color(0xFF607D8B),
                      ),
                    ],
                  ),
                ),

                // 3. CARD DE INSIGHTS AVANZADOS
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildInsightCard(
                    'Insights Avanzados',
                    Icons.psychology,
                    Colors.deepPurple,
                    [
                      _buildInsightMetric(
                        'Adopción de hábitos saludables',
                        _getMonthlyIndicator('healthy_adoption_pct') ?? '0%',
                        Icons.self_improvement,
                        const Color(0xFF2E7D32),
                      ),
                      _buildInsightMetric(
                        'Mejor categoría adoptada',
                        _getMonthlyIndicator('best_adopted_category') ??
                            'Ninguna',
                        Icons.emoji_events,
                        const Color(0xFFFFB300),
                      ),
                      _buildInsightMetric(
                        'Análisis de conversaciones',
                        _getMonthlyIndicator('conversation_insights') ??
                            '0 análisis',
                        Icons.chat_bubble_outline,
                        const Color(0xFF00BCD4),
                      ),
                      _buildInsightMetric(
                        'Score de bienestar general',
                        _getMonthlyIndicator('wellness_score') ?? '0/100',
                        Icons.favorite,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ];

              return Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: PageView(
                      controller: _insightsController,
                      onPageChanged: (i) => setState(() => _insightsPage = i),
                      children: insightCards,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(insightCards.length, (i) {
                      final isActive = _insightsPage == i;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 8 : 6,
                        height: isActive ? 8 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFBDBDBD),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String? _getMonthlyIndicator(String key) {
    final state = context.read<ProgressBloc>().state;
    print('🔍 UI: Getting monthly indicator for key: $key');
    print('🔍 UI: State type: ${state.runtimeType}');

    if (state is ProgressLoaded && state.monthlyIndicators != null) {
      final value = state.monthlyIndicators![key];
      print(
        '🔍 UI: Monthly indicators available: ${state.monthlyIndicators!.keys.length} keys',
      );
      print('🔍 UI: Value for $key: $value');
      return value;
    } else {
      print('❌ UI: No monthly indicators available or state not loaded');
      if (state is ProgressLoaded) {
        print('🔍 UI: State is ProgressLoaded but monthlyIndicators is null');
      }
    }
    return null;
  }

  Widget _buildInsightItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
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

  Widget _buildInsightCard(
    String title,
    IconData titleIcon,
    Color titleColor,
    List<Widget> metrics,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: titleColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: titleColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: titleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(titleIcon, color: titleColor, size: 14),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Métricas
          ...metrics.asMap().entries.map((entry) {
            final index = entry.key;
            final metric = entry.value;
            return Column(
              children: [
                metric,
                if (index < metrics.length - 1) ...[
                  const SizedBox(height: 3),
                  Divider(
                    color: titleColor.withOpacity(0.1),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 3),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  int _calculateCurrentStreak() {
    // Get streak from BLoC state (calculated from database)
    final state = context.read<ProgressBloc>().state;
    if (state is ProgressLoaded && state.userStreak != null) {
      return state.userStreak!;
    }
    return 0; // Default value if streak is not available
  }

  int _calculateMonthlyGoalProgress() {
    // Calculate monthly progress based on actual data
    final state = context.read<ProgressBloc>().state;
    if (state is ProgressLoaded) {
      // Si tenemos datos mensuales reales, usarlos
      if (state.monthlyProgress != null && state.monthlyProgress!.isNotEmpty) {
        final monthlyAverage =
            state.monthlyProgress!
                .map((p) => p.weeklyProgressPercentage)
                .fold(0.0, (a, b) => a + b) /
            state.monthlyProgress!.length;
        return (monthlyAverage * 100).clamp(0.0, 100.0).round();
      }

      // Fallback: estimar basado en el progreso semanal actual
      // Asumiendo que el mes tiene 4 semanas y estamos en progreso
      final weeklyPercentage = state.progress.weeklyProgressPercentage;
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;
      final monthProgress = (dayOfMonth / daysInMonth) * weeklyPercentage;

      return (monthProgress * 100).clamp(0.0, 100.0).round();
    }
    return 0;
  }

  int _calculateWeeklyAverage() {
    // Calculate weekly average based on daily progress
    final state = context.read<ProgressBloc>().state;
    if (state is ProgressLoaded && state.dailyProgress != null) {
      final dailyProgress = state.dailyProgress!;
      final progressValues = dailyProgress.values
          .where((v) => v > 0.0)
          .toList();

      if (progressValues.isNotEmpty) {
        final average =
            progressValues.fold(0.0, (a, b) => a + b) / progressValues.length;
        return (average * 100).clamp(0.0, 100.0).round();
      }
    }

    // Fallback al progreso semanal del backend
    if (state is ProgressLoaded) {
      return ((state.progress.weeklyProgressPercentage ?? 0.0) * 100)
          .clamp(0.0, 100.0)
          .round();
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
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
          SizedBox(height: 200, child: _buildWeeklyProgressChart()),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart() {
    final weeks = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];

    // Get progress data from state
    final state = context.read<ProgressBloc>().state;
    List<double> progress = [0.0, 0.0, 0.0, 0.0];

    if (state is ProgressLoaded &&
        state.monthlyProgress != null &&
        state.monthlyProgress!.isNotEmpty) {
      progress = state.monthlyProgress!
          .map((p) => p.weeklyProgressPercentage.clamp(0.0, 1.0))
          .toList();
    } else if (state is ProgressLoaded) {
      // Fallback estimation
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
              height: (progress[index] * 150).isFinite
                  ? progress[index] * 150
                  : 0,
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
    // Usar colores específicos para cada categoría
    switch (categoryName.toLowerCase()) {
      case 'alimentación':
      case 'alimentacion':
      case 'nutrición':
      case 'nutricion':
        return const Color(0xFF4CAF50); // Verde
      case 'actividad física':
      case 'actividad fisica':
      case 'ejercicio':
      case 'exercise':
        return const Color(0xFF2196F3); // Azul
      case 'sueño':
      case 'sueno':
      case 'descanso':
      case 'sleep':
        return const Color(0xFF9C27B0); // Púrpura
      case 'hidratación':
      case 'hidratacion':
      case 'agua':
      case 'water':
        return const Color(0xFF00BCD4); // Cian
      case 'bienestar mental':
      case 'mental':
      case 'estrés':
      case 'estres':
      case 'stress':
        return const Color(0xFFFF9800); // Naranja
      case 'medicación':
      case 'medicacion':
      case 'medicina':
        return const Color(0xFF795548); // Marrón
      case 'productividad':
      case 'trabajo':
      case 'work':
        return const Color(0xFF607D8B); // Gris azulado
      case 'finanzas':
      case 'dinero':
      case 'money':
        return const Color(0xFF4CAF50); // Verde
      case 'hogar':
      case 'casa':
      case 'home':
        return const Color(0xFFFF5722); // Naranja rojizo
      case 'social':
      case 'relaciones':
      case 'relationships':
        return const Color(0xFFE91E63); // Rosa
      default:
        return const Color(0xFF6B7280); // Gris por defecto
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
