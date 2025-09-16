import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/category.dart' as entities;
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../blocs/category_scroll/category_scroll_bloc.dart';
import '../../blocs/category_scroll/category_scroll_event.dart';

class SynchronizedHabitsList extends StatefulWidget {
  final List<UserHabit> userHabits;
  final List<Habit> habits;
  final List<entities.Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategoryChanged;
  final Function(UserHabit) onHabitToggle;

  const SynchronizedHabitsList({
    Key? key,
    required this.userHabits,
    required this.habits,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onHabitToggle,
  }) : super(key: key);

  @override
  State<SynchronizedHabitsList> createState() => _SynchronizedHabitsListState();
}

class _SynchronizedHabitsListState extends State<SynchronizedHabitsList> {
  late ScrollController _scrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _lastVisibleCategory;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollChanged);
    _initializeCategoryKeys();
  }

  void _initializeCategoryKeys() {
    _categoryKeys.clear();
    _categoryKeys['all'] = GlobalKey();
    for (final category in widget.categories) {
      _categoryKeys[category.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final visibleCategory = _findVisibleCategory(scrollOffset, viewportHeight);

    if (visibleCategory != _lastVisibleCategory) {
      _lastVisibleCategory = visibleCategory;

      // Actualizar el BLoC con la nueva categoría visible
      context.read<CategoryScrollBloc>().add(
        UpdateScrollPosition(
          scrollOffset: scrollOffset,
          visibleCategoryId: visibleCategory,
        ),
      );

      // Notificar al widget padre sobre el cambio de categoría
      widget.onCategoryChanged(visibleCategory);

      // Trigger bounce animation for the new visible category
      if (visibleCategory != null) {
        final categoryIndex = _getCategoryIndex(visibleCategory);
        context.read<CategoryScrollBloc>().add(
          TriggerCategoryBounce(
            categoryId: visibleCategory,
            bounceLeft: categoryIndex % 2 == 0,
          ),
        );
      }
    }
  }

  String? _findVisibleCategory(double scrollOffset, double viewportHeight) {
    final centerOffset = scrollOffset + (viewportHeight / 2);

    for (final entry in _categoryKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;

      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

          if (centerOffset >= position.dy &&
              centerOffset <= position.dy + size.height) {
            return entry.key == 'all' ? null : entry.key;
          }
        }
      }
    }

    return null;
  }

  int _getCategoryIndex(String categoryId) {
    if (categoryId == 'all') return 0;
    final index = widget.categories.indexWhere((c) => c.id == categoryId);
    return index >= 0 ? index + 1 : 0;
  }

  List<UserHabit> _getHabitsForCategory(String? categoryId) {
    if (categoryId == null) return widget.userHabits;

    return widget.userHabits.where((userHabit) {
      final habit = widget.habits.firstWhere(
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
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar hábitos por categoría
    final groupedHabits = <String?, List<UserHabit>>{};

    // Agregar categoría "Todos" si hay hábitos
    if (widget.userHabits.isNotEmpty) {
      groupedHabits[null] = widget.userHabits;
    }

    // Agrupar por categorías específicas
    for (final category in widget.categories) {
      final categoryHabits = _getHabitsForCategory(category.id);
      if (categoryHabits.isNotEmpty) {
        groupedHabits[category.id] = categoryHabits;
      }
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: groupedHabits.length,
        itemBuilder: (context, index) {
          final categoryId = groupedHabits.keys.elementAt(index);
          final habits = groupedHabits[categoryId]!;
          final categoryName = categoryId == null
              ? 'Todos los hábitos'
              : widget.categories.firstWhere((c) => c.id == categoryId).name;

          return Container(
            key: _categoryKeys[categoryId ?? 'all'],
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la categoría
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),

                // Lista de hábitos de la categoría
                ...habits.map((userHabit) {
                  final habit = widget.habits.firstWhere(
                    (h) => h.id == userHabit.habitId,
                    orElse: () => Habit(
                      id: '',
                      name: 'Hábito no encontrado',        
                      description: '',
                      categoryId: null,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );

                  return _buildHabitCard(userHabit, habit);
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitCard(UserHabit userHabit, Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => widget.onHabitToggle(userHabit),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: userHabit.isCompletedToday
                    ? const Color(0xFF219540)
                    : Colors.transparent,
                border: Border.all(
                  color: userHabit.isCompletedToday
                      ? const Color(0xFF219540)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: userHabit.isCompletedToday
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),

          const SizedBox(width: 16),

          // Contenido del hábito
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: userHabit.isCompletedToday
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF1F2937),
                    decoration: userHabit.isCompletedToday
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (habit.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    habit.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Indicador de racha
          if (userHabit.streakCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF219540).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${userHabit.streakCount} días',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF219540),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
