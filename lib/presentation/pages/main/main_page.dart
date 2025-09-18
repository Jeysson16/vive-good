import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/habit/habit_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart' as app_auth;
import '../../widgets/main/main_header.dart';
import '../../widgets/main/daily_register_section.dart';
import '../../widgets/main/category_tabs.dart';
import '../../widgets/main/habit_list.dart';
import '../../widgets/animated_category_tabs_with_line.dart';
import '../../widgets/main/bottom_navigation.dart';
import '../../widgets/main/quick_actions_modal.dart';
import '../../widgets/main/sliver_main_content.dart';
import '../../controllers/sliver_scroll_controller.dart';
import '../habits/my_habits_integrated_view.dart';
import '../progress/progress_main_screen.dart';
import '../../../views/profile/profile_view.dart';
import '../../../blocs/profile/profile_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Set<String> _selectedHabits = {};
  bool _showBottomTab = false;
  String? _selectedCategoryId;
  late TabController _tabController;
  late SliverScrollController _sliverController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Start with 1 tab
    _sliverController = SliverScrollController(
      tabController: _tabController,
      context: context,
      onCategoryChanged: _onCategorySelected,
    );
    
    // Data is now preloaded in splash screen, no need to load again
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _loadUserHabits();
    // });
  }

  void _loadUserHabits() {
    final authState = context.read<AuthBloc>().state;
    if (authState is app_auth.AuthAuthenticated) {
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
      // TODO: Implementar sugerencia IA en interfaz dedicada - mover a otra pantalla
      // case 'ai_suggestion':
      //   _showAISuggestion();
      //   break;
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
    setState(() {
      _selectedCategoryId = categoryId;
    });
    if (mounted) {
      context.read<HabitBloc>().add(FilterHabitsByCategory(categoryId));
    }
  }

  void _onProgressTap() {
    // Navigate to progress page
    setState(() {
      _selectedIndex = 2;
    });
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

  void _onMarkSelectedAsCompleted() {
    for (String habitId in _selectedHabits) {
      _onHabitToggle(habitId, true); // Mark as completed (true because it gets inverted in _onHabitToggle)
    }
    setState(() {
      _selectedHabits.clear();
      _showBottomTab = false;
    });
  }

  void _onClearSelection() {
    setState(() {
      _selectedHabits.clear();
      _showBottomTab = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sliverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                _buildMainContent(), // Home page (index 0)
                MyHabitsIntegratedView(), // My Habits page (index 1)
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
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        onMicPressed: _onMicPressed,
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        if (state is HabitLoaded) {
          // Update tab controller length when categories change
          final categoriesCount =
              state.categories.length + 1; // +1 for "Todos" tab
          if (_tabController.length != categoriesCount && categoriesCount > 0) {
            // Schedule controller recreation after the current frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Dispose previous controllers properly
                _sliverController.dispose();
                _tabController.dispose();

                // Create new controllers with correct length
                _tabController = TabController(
                  length: categoriesCount,
                  vsync: this,
                );
                _sliverController = SliverScrollController(
                  tabController: _tabController,
                  context: context,
                  onCategoryChanged: _onCategorySelected,
                );

                // Update categories in the controller
                _sliverController.updateCategories(state.categories);

                // Trigger rebuild
                if (mounted) {
                  setState(() {});
                }
              }
            });
          } else if (categoriesCount > 0) {
            // Update categories in the controller if length is the same
            _sliverController.updateCategories(state.categories);
          }
        }

        return SliverMainContent(
          controller: _sliverController,
          onHabitToggle: _onHabitToggle,
          onProgressTap: _onProgressTap,
          selectedHabits: _selectedHabits,
          onHabitSelected: _onHabitSelected,
        );
      },
    );
  }

  Widget _buildBottomSelectionTab() {
    return Positioned(
      bottom: 80, // Position above navbar to avoid overflow
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
                  Row(
                    children: [
                      Expanded(
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

                      // TODO: Implementar sugerencia IA en interfaz dedicada
                      // const SizedBox(width: 12),
                      // Expanded(
                      //   child: OutlinedButton(
                      //     onPressed: _onAISuggestion,
                      //     style: OutlinedButton.styleFrom(
                      //       foregroundColor: const Color(0xFF6366F1),
                      //       side: const BorderSide(color: Color(0xFF6366F1)),
                      //       padding: const EdgeInsets.symmetric(vertical: 16),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //     ),
                      //     child: const Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Icon(Icons.auto_awesome, size: 20),
                      //         SizedBox(width: 8),
                      //         Text(
                      //           'Sugerencia IA',
                      //           style: TextStyle(
                      //             fontSize: 16,
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
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
