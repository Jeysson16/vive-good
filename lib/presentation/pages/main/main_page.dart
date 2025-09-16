import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/habit/habit_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/main/main_header.dart';
import '../../widgets/main/daily_register_section.dart';
import '../../widgets/main/category_tabs.dart';
import '../../widgets/main/habit_list.dart';
import '../../widgets/main/bottom_navigation.dart';
import '../../widgets/main/quick_actions_modal.dart';
import '../habits/my_habits_integrated_view.dart';
import '../progress/progress_main_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserHabits();
  }

  void _loadUserHabits() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      // Usar LoadDashboardHabits con parámetros requeridos
      context.read<HabitBloc>().add(
        LoadDashboardHabits(userId: userId, date: DateTime.now()),
      );
      context.read<HabitBloc>().add(LoadCategories());
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onBackToMain() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onMicPressed() {
    QuickActionsModal.show(context, onActionSelected: _handleQuickAction);
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'mark_done':
        _showMarkDoneDialog();
        break;
      case 'ai_suggestion':
        _showAISuggestion();
        break;
    }
  }

  void _showMarkDoneDialog() {
    // Show dialog to select habit to mark as done
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función "Marcar como hecho" próximamente'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _showAISuggestion() {
    // Show AI suggestion dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función "Sugerencia IA" próximamente'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _onHabitToggle(String userHabitId, bool isCompleted) {
    context.read<HabitBloc>().add(
      ToggleHabitCompletion(
        habitId: userHabitId,
        date: DateTime.now(),
        isCompleted: !isCompleted,
      ),
    );
  }

  void _onCategorySelected(String? categoryId) {
    // Si es 'all' o null, no filtrar por categoría
    final filterCategoryId = (categoryId == 'all') ? null : categoryId;
    context.read<HabitBloc>().add(FilterHabitsByCategory(filterCategoryId));
  }

  void _onProgressTap() {
    // Navigate to progress page
    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildMainContent(), // Home page (index 0)
            MyHabitsIntegratedView(), // My Habits page (index 1)
            const ProgressMainScreen(), // Progress page (index 2)
            const Center(child: Text('Perfil')), // Profile page (index 3)
          ],
        ),
      ),
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        onMicPressed: _onMicPressed,
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Header
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String userName = 'Usuario';
            if (authState is AuthAuthenticated) {
              userName = authState.user.name;
            }
            return MainHeader(userName: userName);
          },
        ),

        // Daily Register Section
        BlocBuilder<HabitBloc, HabitState>(
          builder: (context, state) {
            int pendingCount = 0;
            if (state is HabitLoaded) {
              pendingCount = state.pendingCount;
            }
            return DailyRegisterSection(
              date: DateFormat(
                'EEEE, d MMMM yyyy',
                'es_ES',
              ).format(DateTime.now()),
              pendingCount: pendingCount,
              onProgressTap: _onProgressTap,
            );
          },
        ),

        // Category Tabs
        BlocBuilder<HabitBloc, HabitState>(
          builder: (context, state) {
            if (state is HabitLoaded) {
              // Agregar "Todos" como primera categoría
              final allCategories = [
                const CategoryTabItem(id: 'all', name: 'Todos'),
                ...state.categories.map(
                  (category) =>
                      CategoryTabItem(id: category.id, name: category.name),
                ),
              ];
              return CategoryTabs(
                categories: allCategories,
                onCategorySelected: _onCategorySelected,
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Habit List
        Expanded(
          child: BlocBuilder<HabitBloc, HabitState>(
            builder: (context, state) {
              if (state is HabitLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                );
              }

              if (state is HabitError) {
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
                        'Error: ${state.message}',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserHabits,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (state is HabitLoaded) {
                return HabitList(
                  userHabits: state.filteredHabits,
                  habits: state.habits,
                  habitLogs: state.habitLogs,
                  onHabitToggle: _onHabitToggle,
                );
              }

              return const Center(
                child: Text(
                  'Cargando hábitos...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
