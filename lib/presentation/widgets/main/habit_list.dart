import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_log.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_state.dart';
import '../../blocs/main_page/main_page_bloc.dart';
import '../../controllers/sliver_scroll_controller.dart';
import '../common/responsive_dimensions.dart';
import 'habit_item.dart';

class HabitList extends StatefulWidget {
  final List<Category> categories;
  final List<UserHabit> userHabits;
  final List<UserHabit>? filteredHabits;
  final List<Habit> habits;
  final Map<String, List<HabitLog>> habitLogs;
  final Function(String, bool) onHabitToggle;
  final Set<String> selectedHabits;
  final Function(String, bool) onHabitSelected;
  final String? selectedCategoryId;
  final String? animatedHabitId;
  final String? animationState;
  final SliverScrollController? scrollController;
  final String? firstHabitOfCategoryId;
  final VoidCallback? onAnimationError;

  const HabitList({
    super.key,
    required this.categories,
    required this.userHabits,
    this.filteredHabits,
    required this.habits,
    required this.habitLogs,
    required this.onHabitToggle,
    required this.selectedHabits,
    required this.onHabitSelected,
    this.selectedCategoryId,
    this.animatedHabitId,
    this.animationState,
    this.scrollController,
    this.firstHabitOfCategoryId,
    this.onAnimationError,
  });

  @override
  State<HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  String? _previousSelectedCategoryId;
  String? _highlightedHabitId;
  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );
    _previousSelectedCategoryId = widget.selectedCategoryId;

    // Vincular el TabBar con el scroll actual de la grilla
    if (widget.scrollController?.scrollController.hasListeners == false) {
      widget.scrollController?.scrollController.addListener(_handleScrollSync);
    } else {
      widget.scrollController?.scrollController.addListener(_handleScrollSync);
    }
  }

  bool _isHabitCompletedToday(UserHabit userHabit) {
    // isCompletedToday en UserHabit es no-nullable y refleja el estado del día.
    // Mantén la lógica simple y consistente con DashboardBloc.
    return userHabit.isCompletedToday;
  }

  List<UserHabit> _getTodayIncompleteHabits() {
    // Usa la lista filtrada si existe, si no, usa todos los userHabits
    final habitsToFilter = widget.filteredHabits ?? widget.userHabits;
    print(
      '🔍 [DEBUG] HabitList - Total habits to filter: ${habitsToFilter.length}',
    );

    final today = DateTime.now();
    final isBulkToggle = (widget.animationState ?? '')
        .toLowerCase()
        .contains('habittoggled');
    final filtered = habitsToFilter.where((userHabit) {
      final isNotCompleted = !userHabit.isCompletedToday;
      final isActive = _shouldHabitBeActiveToday(userHabit, today);
      // Mantener visibles solo los seleccionados DURANTE animación simultánea
      final isBeingAnimated = widget.animatedHabitId == userHabit.id ||
          (isBulkToggle && widget.selectedHabits.contains(userHabit.id));

      // Incluye hábitos pendientes activos hoy, o el que esté en animación.
      return (isNotCompleted && isActive) || isBeingAnimated;
    }).toList();
    print(
      '🔍 [DEBUG] HabitList - Filtered incomplete habits: ${filtered.length}',
    );
    return filtered;
  }

  bool _shouldHabitBeActiveToday(UserHabit userHabit, DateTime today) {
    // Replica la lógica del DashboardBloc para evitar discrepancias
    if (!(userHabit.isActive ?? true)) {
      return false;
    }
    final freq = (userHabit.frequency ?? '').toLowerCase();
    switch (freq) {
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
            final todayWeekday = today.weekday; // 1=Lun ... 7=Dom
            return selectedDays.contains(todayWeekday);
          }
        }
        return true;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    widget.scrollController?.scrollController.removeListener(_handleScrollSync);
    super.dispose();
  }

  void _handleScrollSync() {
    final controller = widget.scrollController;
    if (controller == null) return;
    if (controller.isHeaderAnimating) return; // evitar cambios durante animación de header
    if (!controller.scrollController.hasClients) return;

    final offset = controller.scrollController.offset;
    const headerOffset = 300.0; // coincide con SliverToBoxAdapter
    const tabsOffset = 60.0; // altura de tabs
    final paddingOffset = ResponsiveDimensions.getCardPadding(context);

    final visibleOffset =
        offset - (headerOffset + tabsOffset + paddingOffset);
    if (visibleOffset < 0) return; // aún en el header, no cambiar tabs

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final itemHeight = _getItemHeight(context);
    final spacing = ResponsiveDimensions.getVerticalSpacing(context);

    final row = (visibleOffset / (itemHeight + spacing)).floor();
    final startIndex = row * crossAxisCount;

    final allVisibleHabits = _getTodayIncompleteHabits();
    if (allVisibleHabits.isEmpty) return;

    final clampedIndex = startIndex.clamp(0, allVisibleHabits.length - 1);
    final userHabit = allVisibleHabits[clampedIndex];
    final habit = widget.habits.firstWhere(
      (h) => h.id == userHabit.habitId,
      orElse: () => Habit(
        id: userHabit.habitId ?? userHabit.id,
        name: userHabit.customName ?? 'Hábito',
        description: '',
        categoryId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final categoryId = habit.categoryId;
    if (categoryId == null) return;
    final categoryIndex =
        widget.categories.indexWhere((c) => c.id == categoryId);
    if (categoryIndex == -1) return;

    final tabIndex = categoryIndex + 1; // +1 por pestaña "Todos"
    controller.syncTabWithScroll(tabIndex);
  }

  void _scrollToFirstHabitOfCategory(String categoryId) {
    print(
      '🔍 [DEBUG] HabitList _scrollToFirstHabitOfCategory called for category: $categoryId',
    );
    // Use the same list that the grid renders to avoid index mismatches
    final allVisibleHabits = _getTodayIncompleteHabits();
    print(
      '🔍 [DEBUG] Found ${allVisibleHabits.length} visible (incomplete/animated) habits',
    );

    // Find the index of the first habit that belongs to the selected category
    int? targetIndex;
    String? firstHabitId;

    for (int i = 0; i < allVisibleHabits.length; i++) {
      final userHabit = allVisibleHabits[i];
      final habit = widget.habits.firstWhere(
        (h) => h.id == userHabit.habitId,
        orElse: () => Habit(
          id: 'fallback',
          name: 'Hábito no encontrado',
          description: '',
          categoryId: userHabit.habitId != null ? 'fallback' : userHabit.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      print(
        '🔍 [DEBUG] Checking habit ${habit.name} (category: ${habit.categoryId})',
      );
      if (habit.categoryId == categoryId) {
        targetIndex = i;
        firstHabitId = userHabit.id;
        print(
          '🔍 [DEBUG] Found first habit of category at index $i: ${habit.name}',
        );
        _highlightHabit(userHabit.id);
        break;
      }
    }

    if (targetIndex == null) {
      print('🔍 [DEBUG] No habits found for category $categoryId');
      return;
    }

    // Scroll to the target item if found
    if (widget.scrollController?.scrollController.hasClients == true) {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = _getCrossAxisCount(screenWidth);
      final row = (targetIndex / crossAxisCount).floor();

      // Calculate more precise position
      final itemHeight = _getItemHeight(context);
      final spacing = ResponsiveDimensions.getVerticalSpacing(context);
      final headerOffset = 300.0; // Height of header section
      final tabsOffset = 60.0; // Height of tabs section
      final paddingOffset = ResponsiveDimensions.getCardPadding(context);

      final targetOffset =
          headerOffset +
          tabsOffset +
          paddingOffset +
          (row * (itemHeight + spacing));

      print(
        '🔍 [DEBUG] Scrolling to offset: $targetOffset (row: $row, itemHeight: $itemHeight)',
      );

      widget.scrollController!.scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } else {
      print('🔍 [DEBUG] ScrollController has no clients');
    }
  }

  void _highlightHabit(String habitId) {
    // Verificar que el controlador esté inicializado
    if (!mounted) {
      return;
    }

    setState(() {
      _highlightedHabitId = habitId;
    });

    _highlightController.reset();
    _highlightController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedHabitId = null;
          });
          _highlightController.reset();
        }
      });
    });
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 600) {
      return 0.95; // Mobile - más compacto en altura
    } else if (screenWidth < 900) {
      return 0.8; // Tablet
    } else {
      return 0.85; // Desktop - más cuadrado
    }
  }

  double _getItemHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final spacing = ResponsiveDimensions.getHorizontalSpacing(context);
    final padding = ResponsiveDimensions.getCardPadding(context);

    final availableWidth =
        screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
    final itemWidth = availableWidth / crossAxisCount;
    final childAspectRatio = _getChildAspectRatio(screenWidth);

    return itemWidth / childAspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    // Check if category selection changed and trigger scroll
    if (widget.selectedCategoryId != null &&
        widget.selectedCategoryId != _previousSelectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstHabitOfCategory(widget.selectedCategoryId!);
      });
      _previousSelectedCategoryId = widget.selectedCategoryId;
    }

    return _buildHabitGrid(context);
  }

  Widget _buildHabitGrid(BuildContext context) {
    final incompleteHabits = _getTodayIncompleteHabits();
    final habitsToCheck = widget.userHabits;

    if (incompleteHabits.isEmpty) {
      // Revisa pendientes a nivel global (activos hoy), no solo en la lista filtrada
      final today = DateTime.now();
      final globalPending = widget.userHabits.where((uh) {
        final notCompleted = !_isHabitCompletedToday(uh);
        final activeToday = _shouldHabitBeActiveToday(uh, today);
        return notCompleted && activeToday;
      }).isNotEmpty;

      if (!globalPending) {
        return SliverFillRemaining(child: _buildAllCompletedState(context));
      } else {
        return SliverFillRemaining(child: _buildEmptyState(context));
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final childAspectRatio = _getChildAspectRatio(screenWidth);
    final padding = ResponsiveDimensions.getCardPadding(context);
    final spacing = ResponsiveDimensions.getHorizontalSpacing(context);

    return SliverPadding(
      padding: EdgeInsets.all(padding),
      sliver: SliverGrid(
        key: _gridKey,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final userHabit = incompleteHabits[index];
          final habit = widget.habits.firstWhere(
            (h) => h.id == userHabit.habitId,
            orElse: () => Habit(
              id: 'fallback',
              name: 'Hábito no encontrado',
              description: '',
              categoryId: userHabit.habitId != null ? 'fallback' : userHabit.id,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final category = widget.categories.firstWhere(
            (c) => c.id == habit.categoryId,
            orElse: () => Category(
              id: 'fallback',
              name: 'Sin categoría',
              color: '#808080',
              iconName: 'help_outline',
            ),
          );

          final isCompletedToday = _isHabitCompletedToday(userHabit);

          // Check if this habit should be highlighted
          // Either it's manually highlighted OR it's the first habit of the selected category
          final isManuallyHighlighted = _highlightedHabitId == userHabit.id;
          bool isFirstInCategory =
              widget.firstHabitOfCategoryId == userHabit.id;

          // Ensure "first in category" aligns with the currently visible grid
          if (!isFirstInCategory &&
              widget.selectedCategoryId != null &&
              habit.categoryId == widget.selectedCategoryId) {
            // If no earlier visible item belongs to the selected category, this is the first
            final hasEarlierSameCategory = incompleteHabits.take(index).any((
              uh,
            ) {
              final h = widget.habits.firstWhere(
                (hh) => hh.id == uh.habitId,
                orElse: () => Habit(
                  id: 'fallback',
                  name: 'Hábito no encontrado',
                  description: '',
                  categoryId: uh.habitId != null ? 'fallback' : uh.id,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              return h.categoryId == widget.selectedCategoryId;
            });
            isFirstInCategory = !hasEarlierSameCategory;
          }

          final isHighlighted = isManuallyHighlighted || isFirstInCategory;

          // Check if this habit is being animated
          // Animar simultáneamente todos los seleccionados cuando el estado es habitToggled
          final isBulkToggle = (widget.animationState ?? '')
              .toLowerCase()
              .contains('habittoggled');
          final isBeingAnimated = widget.animatedHabitId == userHabit.id ||
              (isBulkToggle && widget.selectedHabits.contains(userHabit.id));

          // Dirección de salida: izquierda si está en la primera columna, derecha en otras
          final exitToLeft = (index % crossAxisCount) == 0;

          Widget habitItem = HabitItem(
            key: ValueKey('habit_${userHabit.id}'),
            userHabit: userHabit,
            habit: habit,
            category: category,
            isCompleted: isCompletedToday,
            isFirstInCategory: isFirstInCategory,
            isHighlighted: isHighlighted,
            isBeingAnimated: isBeingAnimated,
            exitToLeft: exitToLeft,
            animationState: widget.animationState,
            isSelected: widget.selectedHabits.contains(userHabit.id),
            onTap: () {
              // Always call onHabitToggle - HabitItem will handle the appropriate animation
              // For completed habits: pulse animation (feedback only)
              // For uncompleted habits: full completion animation + state change
              widget.onHabitToggle(userHabit.id, !isCompletedToday);
            },
            onSelectionChanged: (habitId, isSelected) =>
                widget.onHabitSelected(habitId, isSelected),
            onHighlightComplete: () {
              setState(() {
                _highlightedHabitId = null;
              });
            },
            onAnimationError: widget.onAnimationError,
          );

          // Wrap with AnimatedBuilder for highlight effect
          if (isHighlighted) {
            // Debug: trace which habit is highlighted in the grid
            // Helps confirm visual highlight path is active on mobile
            // ignore: avoid_print
            print(
              'HabitList: highlighting habit ${userHabit.id} (${habit.name})',
            );
            habitItem = AnimatedBuilder(
              animation: _highlightAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF10B981,
                        ).withOpacity(0.4 * _highlightAnimation.value),
                        blurRadius: 20 * _highlightAnimation.value,
                        spreadRadius: 5 * _highlightAnimation.value,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: habitItem,
            );
          }

          return habitItem;
        }, childCount: incompleteHabits.length),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '¡No hay hábitos pendientes!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega nuevos hábitos para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCompletedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          Text(
            '¡Felicitaciones!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Has completado todos tus hábitos de hoy',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
