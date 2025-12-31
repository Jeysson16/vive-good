import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart' as app_auth;
import '../../controllers/sliver_scroll_controller.dart';
import 'main_header.dart';
import 'daily_register_section.dart';
import 'habit_list.dart';
import 'sliver_persistent_header.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/habit_log.dart';
import '../tech_acceptance_widget.dart';
import '../symptoms_knowledge_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SliverMainContent extends StatefulWidget {
  final SliverScrollController controller;
  final Function(String, bool) onHabitToggle;
  final Set<String> selectedHabits;
  final Set<String> animatingHabitIds;
  final Function(String, bool) onHabitSelected;
  final String? firstHabitOfCategoryId;
  final VoidCallback? onAnimationError;
  final void Function(int)? onTabsCountRequired;

  const SliverMainContent({
    super.key,
    required this.controller,
    required this.onHabitToggle,
    required this.selectedHabits,
    this.animatingHabitIds = const {},
    required this.onHabitSelected,
    this.firstHabitOfCategoryId,
    this.onAnimationError,
    this.onTabsCountRequired,
  });

  @override
  State<SliverMainContent> createState() => _SliverMainContentState();
}

class _SliverMainContentState extends State<SliverMainContent> {
  Map<String, bool>? _evaluationsCompleted;
  bool _isLoadingEvaluations = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluationsStatus();
  }

  Future<void> _loadEvaluationsStatus() async {
    final result = await _checkEvaluationsCompleted();
    if (mounted) {
      setState(() {
        _evaluationsCompleted = result;
        _isLoadingEvaluations = false;
      });
    }
  }

  void _refreshEvaluationsStatus() {
    setState(() {
      _isLoadingEvaluations = true;
    });
    _loadEvaluationsStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (previous, current) {
        // Only rebuild when state type changes or data actually changes
        if (previous.runtimeType != current.runtimeType) return true;
        if (previous is DashboardLoaded && current is DashboardLoaded) {
          // Rebuild when structural lengths change OR when counters/selection/animation change
          return previous.categories.length != current.categories.length ||
              previous.userHabits.length != current.userHabits.length ||
              previous.habitLogs.length != current.habitLogs.length ||
              previous.pendingCount != current.pendingCount ||
              previous.completedCount != current.completedCount ||
              previous.filteredHabits.length != current.filteredHabits.length ||
              previous.selectedCategoryId != current.selectedCategoryId ||
              previous.animatedHabitId != current.animatedHabitId ||
              previous.animationState != current.animationState;
        }
        return true;
      },
      builder: (context, dashboardState) {
        // Show single loading spinner when data is not loaded
        if (dashboardState is DashboardLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }

        // Show error state if needed
        if (dashboardState is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los datos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboardState.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<Category> categories = [];
        if (dashboardState is DashboardLoaded) {
          // Filter categories that have associated habits
          categories = _getCategoriesWithHabits(
            dashboardState.categories,
            dashboardState.userHabits,
            dashboardState.habits,
            dashboardState.habitLogs.values.expand((e) => e).toList(),
          );
          // Update controller with new categories and handle TabController length
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.updateCategories(categories);

            // Update tab controller length when categories change
            final categoriesCount = categories.length + 1; // +1 for "Todos" tab
            final safeTabCount = categoriesCount > 0 ? categoriesCount : 1;

            if (widget.controller.tabController.length != safeTabCount) {
              // Notify parent that TabController needs recreation
              widget.onTabsCountRequired?.call(safeTabCount);
            }
          });
        }

        return CustomScrollView(
          controller: widget.controller.scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header content that scrolls normally
            SliverToBoxAdapter(
              child: Container(
                height: 300,
                decoration: const BoxDecoration(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    // Main Header
                    Expanded(
                      flex: 3,
                      child: BlocBuilder<AuthBloc, app_auth.AuthState>(
                        builder: (context, authState) {
                          String userName = 'Usuario';
                          if (authState is app_auth.AuthAuthenticated) {
                            userName = authState.user.name;
                          }
                          return MainHeader(userName: userName);
                        },
                      ),
                    ),

                    // Daily Register Section
                    Expanded(
                      flex: 4,
                      child: Builder(
                        builder: (context) {
                          // Use the pendingCount from DashboardBloc instead of calculating locally
                          int pendingCount = 0;
                          if (dashboardState is DashboardLoaded) {
                            pendingCount = dashboardState.pendingCount;
                            print(
                              '🔍 [DEBUG] SliverMainContent - Using pendingCount from DashboardBloc: $pendingCount',
                            );
                          }

                          return DailyRegisterSection(
                            date: DateFormat(
                              'EEEE, d MMMM yyyy',
                              'es_ES',
                            ).format(DateTime.now()),
                            pendingCount: pendingCount,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Evaluation Widgets Section - Only show if not completed
            SliverToBoxAdapter(
              child: _isLoadingEvaluations
                  ? const SizedBox.shrink()
                  : Builder(
                      builder: (context) {
                        final completedEvaluations = _evaluationsCompleted ?? {};
                        final showTechAcceptance =
                            !(completedEvaluations['tech_acceptance'] ?? false);
                        final showSymptomsKnowledge =
                            !(completedEvaluations['symptoms_knowledge'] ?? false);

                        // If both are completed, don't show the section
                        if (!showTechAcceptance && !showSymptomsKnowledge) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            if (showTechAcceptance)
                              TechAcceptanceWidget(
                                onCompleted: () {
                                  // Refresh dashboard data when evaluation is completed
                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is app_auth.AuthAuthenticated) {
                                    context.read<DashboardBloc>().add(
                                      RefreshDashboardData(
                                        userId: authState.user.id,
                                        date: DateTime.now(),
                                      ),
                                    );
                                  }
                                  // Refresh evaluations status
                                  _refreshEvaluationsStatus();
                                },
                              ),
                            if (showSymptomsKnowledge)
                              SymptomsKnowledgeWidget(
                                onCompleted: () {
                                  // Refresh dashboard data when evaluation is completed
                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is app_auth.AuthAuthenticated) {
                                    context.read<DashboardBloc>().add(
                                      RefreshDashboardData(
                                        userId: authState.user.id,
                                        date: DateTime.now(),
                                      ),
                                    );
                                  }
                                  // Refresh evaluations status
                                  _refreshEvaluationsStatus();
                                },
                              ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
            ),

            // Persistent Header with Tabs
            if (dashboardState is DashboardLoaded) ...[
              Builder(
                builder: (context) {
                  // Filter categories that have associated habits
                  final categoriesWithHabits = _getCategoriesWithHabits(
                    dashboardState.categories,
                    dashboardState.userHabits,
                    dashboardState.habits,
                    dashboardState.habitLogs.values.expand((e) => e).toList(),
                  );

                  return SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: SliverPersistentHeaderWidget(
                      controller: widget.controller,
                      categories: categoriesWithHabits,
                      tabController: widget.controller.tabController,
                    ),
                  );
                },
              ),
            ],

            // Habit List
            if (dashboardState is DashboardLoaded) ...[
              Builder(
                builder: (context) {
                  // Filter categories that have associated habits
                  final categoriesWithHabits = _getCategoriesWithHabits(
                    dashboardState.categories,
                    dashboardState.userHabits,
                    dashboardState.habits,
                    dashboardState.habitLogs.values.expand((e) => e).toList(),
                  );

                  // Use filtered habits if available, otherwise use all user habits
                  final habitsToUse =
                      dashboardState.filteredHabits ??
                      dashboardState.userHabits;
                  final sortedHabits = _sortHabitsByCategory(
                    habitsToUse,
                    dashboardState.habits,
                    categoriesWithHabits,
                  );

                  return HabitList(
                    categories: categoriesWithHabits,
                    // Pasa todos los userHabits para chequeos globales de pendientes/completados
                    userHabits: dashboardState.userHabits,
                    // Pasa la lista filtrada/ordenada para la grilla visible
                    filteredHabits: sortedHabits,
                    habits: dashboardState.habits,
                    habitLogs: dashboardState.habitLogs,
                    onHabitToggle: widget.onHabitToggle,
                    selectedHabits: widget.selectedHabits,
                    animatingHabitIds: widget.animatingHabitIds,
                    onHabitSelected: widget.onHabitSelected,
                    selectedCategoryId: dashboardState.selectedCategoryId,
                    animatedHabitId: dashboardState.animatedHabitId,
                    animationState: dashboardState.animationState.toString(),
                    scrollController: widget.controller,
                    firstHabitOfCategoryId: widget.firstHabitOfCategoryId,
                    onAnimationError: widget.onAnimationError,
                  );
                },
              ),
            ],

            // Bottom padding to prevent overlap with bottom navigation
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }

  /// Sort habits by category order to match the tabs order
  List<UserHabit> _sortHabitsByCategory(
    List<UserHabit> userHabits,
    List<Habit> habits,
    List<Category> categories,
  ) {
    // Create a map of category ID to its index in the categories list
    final categoryOrderMap = <String, int>{};
    for (int i = 0; i < categories.length; i++) {
      categoryOrderMap[categories[i].id] = i;
    }

    // Sort user habits based on their category order
    final sortedHabits = List<UserHabit>.from(userHabits);
    sortedHabits.sort((a, b) {
      // Find the habits for comparison - manejo seguro
      final habitA = habits.firstWhere(
        (h) => h.id == a.habitId,
        orElse: () => Habit(
          id: a.id,
          name: a.customName ?? 'Hábito personalizado',
          description: '',
          categoryId: 'fallback',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final habitB = habits.firstWhere(
        (h) => h.id == b.habitId,
        orElse: () => Habit(
          id: b.id,
          name: b.customName ?? 'Hábito personalizado',
          description: '',
          categoryId: 'fallback',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Get category order indices (default to high number if not found) - safe null handling
      final categoryIdA = habitA.categoryId ?? '';
      final categoryIdB = habitB.categoryId ?? '';
      final orderA = categoryIdA.isNotEmpty
          ? (categoryOrderMap[categoryIdA] ?? 999)
          : 999;
      final orderB = categoryIdB.isNotEmpty
          ? (categoryOrderMap[categoryIdB] ?? 999)
          : 999;

      // Sort by category order first, then by habit name
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      return habitA.name.compareTo(habitB.name);
    });

    return sortedHabits;
  }

  /// Get categories that should be displayed in tabs
  List<Category> _getCategoriesWithHabits(
    List<Category> categories,
    List<UserHabit> userHabits,
    List<Habit> habits,
    List<HabitLog> habitLogs,
  ) {
    // Mostrar solo categorías que tienen hábitos visibles hoy en la grilla:
    // hábitos no completados y activos hoy (coincide con la lógica de Dashboard).
    final today = DateTime.now();
    final visibleCategoryIds = <String>{};

    for (final uh in userHabits) {
      final isNotCompleted = !uh.isCompletedToday;
      final isActiveToday = _shouldHabitBeActiveToday(uh, today);
      if (!isNotCompleted || !isActiveToday) {
        continue; // Solo categorías con hábitos visibles hoy
      }

      final h = habits.firstWhere(
        (hh) => hh.id == uh.habitId,
        orElse: () => Habit(
          id: uh.habitId ?? uh.id,
          name: uh.customName ?? 'Hábito',
          description: '',
          categoryId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final catId = h.categoryId;
      if (catId != null && catId.isNotEmpty) {
        visibleCategoryIds.add(catId);
      }
    }

    final categoriesWithHabits = categories
        .where((c) => visibleCategoryIds.contains(c.id))
        .toList();

    return categoriesWithHabits;
  }

  bool _isHabitCompletedToday(UserHabit userHabit, List<HabitLog> logs) {
    final now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    return logs.any(
      (log) => log.userHabitId == userHabit.id && sameDay(log.completedAt, now),
    );
  }

  /// Check if a habit should be active today based on its frequency
  bool _shouldHabitBeActiveToday(UserHabit userHabit, DateTime today) {
    print(
      '🔍 [DEBUG] _shouldHabitBeActiveToday - Habit ${userHabit.id}: isActive=${userHabit.isActive}, frequency=${userHabit.frequency}',
    );

    if (!userHabit.isActive) {
      print('  -> Habit is not active, returning false');
      return false;
    }

    switch (userHabit.frequency.toLowerCase()) {
      case 'daily':
      case 'diario':
        print('  -> Daily habit, returning true');
        return true;
      case 'weekly':
      case 'semanal':
        // Check if today is one of the selected days for weekly habits
        if (userHabit.frequencyDetails != null &&
            userHabit.frequencyDetails!.containsKey('days_of_week')) {
          final selectedDays =
              userHabit.frequencyDetails!['days_of_week'] as List<dynamic>?;
          if (selectedDays != null && selectedDays.isNotEmpty) {
            // Convert today's weekday (1=Monday, 7=Sunday) to match the stored format
            final todayWeekday = today.weekday;
            final result = selectedDays.contains(todayWeekday);
            print(
              '  -> Weekly habit with specific days: $selectedDays, today=$todayWeekday, result=$result',
            );
            return result;
          }
        }
        // If no specific days are set, default to all days
        print('  -> Weekly habit with no specific days, returning true');
        return true;
      case 'monthly':
      case 'mensual':
        // For monthly habits, check if today matches the target day
        if (userHabit.frequencyDetails != null &&
            userHabit.frequencyDetails!.containsKey('day_of_month')) {
          final targetDay = userHabit.frequencyDetails!['day_of_month'] as int?;
          if (targetDay != null) {
            final result = today.day == targetDay;
            print(
              '  -> Monthly habit with target day $targetDay, today=${today.day}, result=$result',
            );
            return result;
          }
        }
        // If no specific day is set, default to first day of month
        final result = today.day == 1;
        print(
          '  -> Monthly habit with no specific day, today=${today.day}, result=$result',
        );
        return result;
      default:
        print('  -> Unknown frequency, returning true');
        return true; // Default to active for unknown frequencies
    }
  }

  /// Check if evaluations have been completed by the current user
  Future<Map<String, bool>> _checkEvaluationsCompleted() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        return {'tech_acceptance': false, 'symptoms_knowledge': false};
      }

      // Check tech acceptance evaluation
      final techAcceptanceResponse = await supabase
          .from('tech_acceptance_evaluations')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      // Check symptoms knowledge evaluation
      final symptomsKnowledgeResponse = await supabase
          .from('symptoms_knowledge_evaluations')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return {
        'tech_acceptance': techAcceptanceResponse != null,
        'symptoms_knowledge': symptomsKnowledgeResponse != null,
      };
    } catch (e) {
      print('Error checking evaluations: $e');
      return {'tech_acceptance': false, 'symptoms_knowledge': false};
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: maxExtent, child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }

  // Removed FloatingHeaderSnapConfiguration as it's not available in current Flutter version
}
