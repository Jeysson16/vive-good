import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_state.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart' as app_auth;
import '../../controllers/sliver_scroll_controller.dart';
import 'main_header.dart';
import 'daily_register_section.dart';
import 'tabs_section.dart';
import 'habit_list.dart';
import 'sliver_persistent_header.dart';
import '../../../domain/entities/category.dart';

class SliverMainContent extends StatelessWidget {
  final SliverScrollController controller;
  final Function(String, bool) onHabitToggle;
  final Function() onProgressTap;
  final Set<String> selectedHabits;
  final Function(String, bool) onHabitSelected;

  const SliverMainContent({
    super.key,
    required this.controller,
    required this.onHabitToggle,
    required this.onProgressTap,
    required this.selectedHabits,
    required this.onHabitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitBloc, HabitState>(
      buildWhen: (previous, current) {
        // Only rebuild when state type changes or categories change
        if (previous.runtimeType != current.runtimeType) return true;
        if (previous is HabitLoaded && current is HabitLoaded) {
          return previous.filteredCategories.length !=
              current.filteredCategories.length;
        }
        return true;
      },
      builder: (context, state) {
        List<Category> categories = [];
        if (state is HabitLoaded) {
          categories = state.filteredCategories;
          // Update controller with new categories
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.updateCategories(categories);
          });
        }

        return CustomScrollView(
          controller: controller.scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // App Bar with header content
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: false,
              floating: true,
              snap: true,
              expandedHeight: 240,
              automaticallyImplyLeading: false,
              stretch: false,
              stretchTriggerOffset: 100.0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
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
                        child: BlocBuilder<HabitBloc, HabitState>(
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
                              onProgressTap: onProgressTap,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Persistent Header with Tabs
            BlocBuilder<HabitBloc, HabitState>(
              builder: (context, state) {
                if (state is HabitLoaded) {
                  return SliverPersistentHeader(
                    pinned: true,
                    floating: true,
                    delegate: SliverPersistentHeaderWidget(
                      controller: controller,
                      categories: state.categories,
                      tabController: controller.tabController,
                    ),
                  );
                }
                return SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _SliverAppBarDelegate(
                    minHeight: 48,
                    maxHeight: 48,
                    child: Container(
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Cargando categorías...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Habit List Content
            BlocBuilder<HabitBloc, HabitState>(
              buildWhen: (previous, current) {
                // Only rebuild when habits data actually changes
                if (previous.runtimeType != current.runtimeType) return true;
                if (previous is HabitLoaded && current is HabitLoaded) {
                  return previous.filteredHabits.length !=
                          current.filteredHabits.length ||
                      previous.habitLogs.length != current.habitLogs.length;
                }
                return true;
              },
              builder: (context, state) {
                if (state is HabitLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  );
                }

                if (state is HabitError) {
                  return SliverFillRemaining(
                    child: Center(
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Reload habits
                              final authState = context.read<AuthBloc>().state;
                              if (authState is app_auth.AuthAuthenticated) {
                                final userId = authState.user.id;
                                context.read<HabitBloc>().add(
                                  LoadDashboardHabits(
                                    userId: userId,
                                    date: DateTime.now(),
                                  ),
                                );
                              }
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is HabitLoaded) {
                  return HabitList(
                    userHabits:
                        state.userHabits, // Use all habits instead of filtered
                    habits: state.habits,
                    categories: state.categories,
                    habitLogs: state.habitLogs,
                    onHabitToggle: onHabitToggle,
                    selectedHabits: selectedHabits,
                    onHabitSelected: onHabitSelected,
                    selectedCategoryId: state.selectedCategoryId,
                  );
                }

                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hay hábitos disponibles',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
            
            // Bottom padding to prevent overlap with bottom navigation
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 100),
            ),
          ],
        );
      },
    );
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
    final progress = shrinkOffset / maxExtent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: SizedBox.expand(
        child: Transform.translate(
          offset: Offset(0, -shrinkOffset * 0.1),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }

  // Removed FloatingHeaderSnapConfiguration as it's not available in current Flutter version
}
