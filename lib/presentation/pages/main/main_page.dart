import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_event.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../widgets/main/bottom_navigation.dart';
import '../../widgets/main/sliver_main_content.dart';
import '../../controllers/sliver_scroll_controller.dart';
import '../habits/my_habits_integrated_view.dart';
import '../progress/progress_main_screen.dart';
import '../assistant/assistant_page.dart';
import '../../../views/profile/profile_view.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../widgets/connectivity_indicator.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Set<String> _selectedHabits = {};
  Set<String> _bulkAnimatingHabits = {};
  bool _showBottomTab = false;
  String? _selectedCategoryId;
  String?
  _firstHabitOfCategoryId; // ID del primer hábito de la categoría seleccionada
  late TabController _tabController;
  late SliverScrollController _sliverController;
  Timer? _loadingVerificationTimer;
  
  // Instancia persistente de MyHabitsIntegratedView para evitar recreación
  late Widget _myHabitsView;

  @override
  void initState() {
    super.initState();
    // Inicializa TabController con el número correcto de pestañas si ya hay datos cargados;
    // de lo contrario, usa 1 pestaña ("Todos") como placeholder para evitar mismatch inicial.
    int initialTabLength = 1; // Siempre al menos 1 por "Todos"
    final dashboardState = context.read<DashboardBloc>().state;
    if (dashboardState is DashboardLoaded) {
      // Calcular categorías con hábitos visibles hoy para las pestañas
      final categoriesWithHabits = _getCategoriesWithHabits(
        dashboardState.categories,
        dashboardState.userHabits,
        dashboardState.habits,
        dashboardState.habitLogs.values.expand((e) => e).toList(),
      );
      initialTabLength = (categoriesWithHabits.length + 1).clamp(1, 1000);
    }
    _tabController = TabController(length: initialTabLength, vsync: this);
    _sliverController = SliverScrollController(
      tabController: _tabController,
      context: context,
      onCategoryChanged: _onCategorySelected,
    );

    // Inicializar instancia persistente de MyHabitsIntegratedView
    _myHabitsView = MyHabitsIntegratedView(
      onHabitCreated: () {
        // Recargar datos del dashboard cuando se crea un nuevo hábito
        _loadUserHabits();
      },
    );

    // Load dashboard data only if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserHabitsIfNeeded();
      _startLoadingVerificationTimer();
    });
  }

  void _updateTabController(int newLength) {
    // Ensure minimum length of 1
    final safeLength = newLength > 0 ? newLength : 1;
    
    // Only recreate if the length actually changed and is different from current
    if (_tabController.length != safeLength) {
      print('🔧 [DEBUG] Updating TabController: ${_tabController.length} -> $safeLength');
      
      // Store current index to preserve selection if possible
      final currentIndex = _tabController.index;
      
      // Dispose old controller
      _tabController.dispose();

      // Create new controller with correct length
      _tabController = TabController(
        length: safeLength, 
        vsync: this,
        initialIndex: currentIndex < safeLength ? currentIndex : 0,
      );

      // Only recreate SliverScrollController if necessary
      if (_sliverController.tabController != _tabController) {
        _sliverController.dispose();
        _sliverController = SliverScrollController(
          tabController: _tabController,
          context: context,
          onCategoryChanged: _onCategorySelected,
        );
      }

      print('🔧 [DEBUG] TabController updated successfully with $safeLength tabs');
      
      // Trigger rebuild only when necessary
      if (mounted) {
        setState(() {});
      }
    } else {
      print('🔧 [DEBUG] TabController length unchanged: $safeLength');
    }
  }

  void _loadUserHabitsIfNeeded() {
    final dashboardState = context.read<DashboardBloc>().state;
    print('🔍 [DEBUG] MainPage - Dashboard state: ${dashboardState.runtimeType}');
    
    // Only load if data is not already loaded
    if (dashboardState is! DashboardLoaded) {
      print('🔍 [DEBUG] MainPage - Dashboard not loaded, loading data...');
      _loadUserHabits();
    } else {
      print('🔍 [DEBUG] MainPage - Dashboard already loaded with ${(dashboardState as DashboardLoaded).userHabits.length} habits');
    }
  }

  void _loadUserHabits() {
    final authState = context.read<AuthBloc>().state;
    print('🔍 [DEBUG] MainPage - Auth state: ${authState.runtimeType}');
    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      print('🔍 [DEBUG] MainPage - Loading dashboard data for user: $userId');
      
      // Reload dashboard data
      context.read<DashboardBloc>().add(
        LoadDashboardData(userId: userId, date: DateTime.now()),
      );
      
      // Also reload habit suggestions to reflect new habits
      context.read<HabitBloc>().add(
        LoadHabitSuggestions(
          userId: userId,
          categoryId: null, // Load all suggestions
          limit: 100,
        ),
      );
    } else {
      print('❌ [DEBUG] MainPage - User not authenticated!');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // TODO: Mover a interfaz dedicada de sugerencia IA
  // void _showAISuggestion() {
  //   // Show AI suggestion dialog
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Función "Sugerencia IA" próximamente'),
  //       backgroundColor: Color(0xFF6366F1),
  //     ),
  //   );
  // }

  void _onHabitToggle(String habitId, bool isCompleted) {
    // Actualiza Dashboard (animación y métricas)
    context.read<DashboardBloc>().add(
      ToggleDashboardHabitCompletion(
        habitId: habitId,
        date: DateTime.now(),
        isCompleted: isCompleted,
      ),
    );

    // Sincroniza también HabitBloc para que "Mis Hábitos" refleje el cambio
    context.read<HabitBloc>().add(
      ToggleHabitCompletion(
        habitId: habitId,
        date: DateTime.now(),
        isCompleted: isCompleted,
      ),
    );

    // Refrescar progreso para que la vista de progreso se actualice
    _refreshProgressAfterChange();
  }

  void _onCategorySelected(String? categoryId) {
    // Identificar el primer hábito de la categoría seleccionada
    String? firstHabitId;
    if (categoryId != null) {
      final dashboardState = context.read<DashboardBloc>().state;
      if (dashboardState is DashboardLoaded) {
        // Filtrar hábitos por categoría y obtener el primero (solo hábitos no completados)
        final habitsInCategory = dashboardState.userHabits.where((userHabit) {
          // Solo considerar hábitos no completados
          if (userHabit.isCompletedToday) return false;
          
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
          return habit.categoryId == categoryId;
        }).toList();

        if (habitsInCategory.isNotEmpty) {
          // Usar el ID del UserHabit, no del Habit
          firstHabitId = habitsInCategory.first.id;
        } 
      }
    }

    setState(() {
      _selectedCategoryId = categoryId;
      _firstHabitOfCategoryId = firstHabitId;
    });

    if (mounted) {
      // Use DashboardBloc to handle category filtering for dashboard
      context.read<DashboardBloc>().add(FilterDashboardByCategory(categoryId));

      // Scroll to first habit of selected category if categoryId is not null
      if (categoryId != null) {
        _sliverController.scrollToFirstHabitOfCategory(categoryId);
      }
    }
  }



  void _onHabitSelected(String habitId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedHabits.add(habitId);
      } else {
        _selectedHabits.remove(habitId);
      }
      _showBottomTab = _selectedHabits.isNotEmpty;
    });
  }

  void _onMarkSelectedAsCompleted() async {
    // Prevent multiple executions
    if (_selectedHabits.isEmpty) return;
    
    // Store the selected habits to process
    final habitsToComplete = List<String>.from(_selectedHabits);
    
    // Disparar una sola acción de completado en bloque para animación simultánea
    context.read<DashboardBloc>().add(
      ToggleDashboardHabitsCompletionBulk(
        habitIds: habitsToComplete,
        date: DateTime.now(),
        isCompleted: true,
      ),
    );

    // También actualizar HabitBloc para que "Mis Hábitos" se mantenga en sincronía
    final now = DateTime.now();
    for (final id in habitsToComplete) {
      context.read<HabitBloc>().add(
        ToggleHabitCompletion(
          habitId: id,
          date: now,
          isCompleted: true,
        ),
      );
    }

    // Refrescar progreso tras completado masivo
    _refreshProgressAfterChange(delay: const Duration(milliseconds: 800));

    // Mantener la selección visible durante la animación para evitar "dispose" prematuro
    // y luego limpiar cuando hayan terminado las animaciones internas
    // Activar animación bulk y limpiar selección visual inmediatamente
    if (!mounted) return;
    setState(() {
      _bulkAnimatingHabits = habitsToComplete.toSet();
      _selectedHabits.clear();
      _showBottomTab = false;
    });

    // Limpiar IDs de animación tras finalizar la animación del Bloc
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _bulkAnimatingHabits.clear();
      });
    });
  }

  // Dispara RefreshUserProgress con una pequeña espera para evitar carreras
  void _refreshProgressAfterChange({
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Future.delayed(delay, () {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else {
        userId = Supabase.instance.client.auth.currentUser?.id;
      }

      if (userId != null && userId.isNotEmpty) {
        context.read<ProgressBloc>().add(
          RefreshUserProgress(userId: userId),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo refrescar progreso: usuario no autenticado',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _onClearSelection() {
    setState(() {
      _selectedHabits.clear();
      _showBottomTab = false;
    });
  }

  void _onChatWithAssistant() {
    if (_selectedHabits.isEmpty) return;

    // Obtener los UserHabits seleccionados con sus datos completos
    final dashboardState = context.read<DashboardBloc>().state;
    if (dashboardState is! DashboardLoaded) return;

    final selectedUserHabits = dashboardState.userHabits
        .where((userHabit) => _selectedHabits.contains(userHabit.id))
        .toList();

    // Navegar a la página del asistente con los hábitos adjuntados
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssistantPage(
          attachedHabits: selectedUserHabits,
        ),
      ),
    );

    // Limpiar la selección después de navegar
    _onClearSelection();
  }

  void _onAnimationError() {
    print('🚨 [ERROR] Animation error detected in main page');
    // Trigger a sync error state with auto-refresh
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<DashboardBloc>().add(
        RefreshDashboardData(
          userId: authState.user.id,
          date: DateTime.now(),
        ),
      );
    }
  }

  void _startLoadingVerificationTimer() {
    // Cancel any existing timer
    _loadingVerificationTimer?.cancel();
    
    // Start a timer to check if habits load within 8 seconds
    _loadingVerificationTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      
      final dashboardState = context.read<DashboardBloc>().state;
      print('🕐 [DEBUG] Loading verification timer triggered. State: ${dashboardState.runtimeType}');
      
      // If still loading or in error state after 8 seconds, trigger refresh
      if (dashboardState is DashboardLoading || 
          dashboardState is DashboardError ||
          (dashboardState is DashboardLoaded && dashboardState.userHabits.isEmpty)) {
        
        print('🚨 [WARNING] Habits not loaded after 8 seconds, triggering refresh');
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<DashboardBloc>().add(
            RefreshDashboardData(
              userId: authState.user.id,
              date: DateTime.now(),
            ),
          );
        }
      }
    });
  }

  /// Get categories that have user habits for tabs
  List<Category> _getCategoriesWithHabits(
    List<Category> categories,
    List<UserHabit> userHabits,
    List<Habit> habits,
    List<HabitLog> habitLogs,
  ) {
    print('🔍 [DEBUG] MainPage _getCategoriesWithHabits called');
    print('   - Total categories: ${categories.length}');
    print('   - Total user habits: ${userHabits.length}');
    print('   - Total habits: ${habits.length}');
    
    // Filter categories with at least one visible (pending & active today) habit
    final categoriesWithHabits = categories.where((category) {
      final hasVisible = userHabits.any((userHabit) {
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
        if (habit.categoryId != category.id) return false;
        final today = DateTime.now();
        final isCompletedToday = _isHabitCompletedToday(userHabit, habitLogs);
        final activeToday = _shouldHabitBeActiveToday(userHabit, today);
        return !isCompletedToday && activeToday;
      });
      
      if (hasVisible) {
        print('   - Category "${category.name}" has pending habits for today');
      }
      
      return hasVisible;
    }).toList();
    
    print('   - Categories with habits: ${categoriesWithHabits.length}');
    for (var category in categoriesWithHabits) {
      print('     - ${category.name} (${category.id})');
    }
    
    return categoriesWithHabits;
  }

  bool _isHabitCompletedToday(UserHabit userHabit, List<HabitLog> logs) {
    // Use isCompletedToday from UserHabit which comes from stored procedure
    // This is more efficient and consistent than manually checking logs
    return userHabit.isCompletedToday;
  }

  /// Verifica si el hábito debe estar activo hoy según su frecuencia
  bool _shouldHabitBeActiveToday(UserHabit userHabit, DateTime today) {
    if (!userHabit.isActive) return false;

    switch (userHabit.frequency.toLowerCase()) {
      case 'daily':
      case 'diario':
        return true;
      case 'weekly':
      case 'semanal':
        if (userHabit.frequencyDetails != null &&
            userHabit.frequencyDetails!.containsKey('days_of_week')) {
          final selectedDays =
              userHabit.frequencyDetails!['days_of_week'] as List<dynamic>?;
          if (selectedDays != null && selectedDays.isNotEmpty) {
            final todayWeekday = today.weekday; // 1=Lunes .. 7=Domingo
            return selectedDays.contains(todayWeekday);
          }
        }
        return true; // Sin días específicos => todos los días
      case 'monthly':
      case 'mensual':
        if (userHabit.frequencyDetails != null &&
            userHabit.frequencyDetails!.containsKey('day_of_month')) {
          final targetDay =
              userHabit.frequencyDetails!['day_of_month'] as int?;
          if (targetDay != null) {
            return today.day == targetDay;
          }
        }
        return today.day == 1; // Sin día específico => día 1 del mes
      default:
        return true; // Frecuencia desconocida => activo
    }
  }

  @override
  void dispose() {
    _loadingVerificationTimer?.cancel();
    _tabController.dispose();
    _sliverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 4,),
          // Offline banner at the top
          const OfflineBanner(),
          // Main content
          Expanded(
            child: Stack(
              children: [
                // Main content with bottom padding for navigation
                Positioned.fill(
                  bottom: 64, // Height of bottom navigation
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        IndexedStack(
                          index: _selectedIndex,
                          children: [
                            _buildMainContent(), // Home page (index 0)
                            _myHabitsView, // My Habits page (index 1) - Instancia persistente
                            const ProgressMainScreen(), // Progress page (index 2)
                            BlocProvider(
                              create: (context) =>
                                  ProfileBloc(supabaseClient: Supabase.instance.client),
                              child: const ProfileView(),
                            ), // Profile page (index 3)
                          ],
                        ),
                        if (_showBottomTab && _selectedIndex == 0)
                          _buildBottomSelectionTab(),
                      ],
                    ),
                  ),
                ),
                // Bottom navigation positioned at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: MainBottomNavigation(
                    currentIndex: _selectedIndex,
                    onTap: _onBottomNavTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            print('🔍 [DEBUG] BlocListener received state: ${state.runtimeType}');
            if (state is DashboardLoaded) {
              print('🔍 [DEBUG] DashboardLoaded state detected, calling _getCategoriesWithHabits');
              // Filter categories that have associated user habits for TabController
              final categoriesWithHabits = _getCategoriesWithHabits(
                state.categories,
                state.userHabits,
                state.habits,
                state.habitLogs.values.expand((e) => e).toList(),
              );

              // Update TabController with filtered categories count
              final totalTabs =
                  categoriesWithHabits.length + 1; // +1 for "Todos" tab
              _updateTabController(totalTabs);

              // Update categories in SliverScrollController with filtered categories
              _sliverController.updateCategories(categoriesWithHabits);
            } else if (state is DashboardSyncError && state.shouldAutoRefresh) {
              print('🔍 [DEBUG] DashboardSyncError detected, triggering auto-refresh');
              // Auto-refresh after a short delay
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    context.read<DashboardBloc>().add(
                      RefreshDashboardData(
                        userId: authState.user.id,
                        date: DateTime.now(),
                      ),
                    );
                  }
                }
              });
            } else {
              print('🔍 [DEBUG] State is not DashboardLoaded: ${state.runtimeType}');
            }
          },
          child: Stack(
            children: [
              SliverMainContent(
                controller: _sliverController,
                onHabitToggle: _onHabitToggle,
                selectedHabits: _selectedHabits,
                animatingHabitIds: _bulkAnimatingHabits,
                onHabitSelected: _onHabitSelected,
                firstHabitOfCategoryId: _firstHabitOfCategoryId,
                onAnimationError: _onAnimationError,
                onTabsCountRequired: (count) {
                  _updateTabController(count);
                },
              ),
              // Loading overlay
              if (state is DashboardLoading || state is DashboardInitial)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando hábitos...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Sync error overlay with auto-refresh
              if (state is DashboardSyncError)
                Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                              ),
                              const SizedBox(height: 16),
                              const Icon(
                                Icons.sync_problem,
                                size: 48,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sincronizando datos...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildBottomSelectionTab() {
    return Positioned(
      bottom: 10,
      left: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header with selection count
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedHabits.length} seleccionado${_selectedHabits.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _onClearSelection,
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Column(
                    children: [
                      // Primera fila - Marcar como hecho
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onMarkSelectedAsCompleted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Marcar como hecho',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Segunda fila - Conversar con el asistente
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _onChatWithAssistant,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Conversar con el asistente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
