import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart' as entities;
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../common/responsive_dimensions.dart';
import '../main/habit_item.dart';

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
    // Ya no necesitamos el listener del scroll interno
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    // El scroll ahora es manejado por el SingleChildScrollView padre
    // Esta función se mantiene para compatibilidad pero no hace nada
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
      final habit = _getHabitForUserHabit(userHabit);
      return habit.categoryId == categoryId;
    }).toList();
  }

  Habit _getHabitForUserHabit(UserHabit userHabit) {
    // Debug: Verificar si el habit está llegando correctamente
    print('🔍 DEBUG _getHabitForUserHabit: userHabit.id = ${userHabit.id}');
    print(
      '🔍 DEBUG _getHabitForUserHabit: userHabit.habit = ${userHabit.habit}',
    );
    print(
      '🔍 DEBUG _getHabitForUserHabit: userHabit.habitId = ${userHabit.habitId}',
    );
    print(
      '🔍 DEBUG _getHabitForUserHabit: userHabit.customName = ${userHabit.customName}',
    );

    // Si el userHabit tiene un habit asociado (del stored procedure), usarlo
    if (userHabit.habit != null) {
      print(
        '🔍 DEBUG _getHabitForUserHabit: Usando habit del stored procedure',
      );
      print(
        '🔍 DEBUG _getHabitForUserHabit: habit.iconName = ${userHabit.habit!.iconName}',
      );
      print(
        '🔍 DEBUG _getHabitForUserHabit: habit.iconColor = ${userHabit.habit!.iconColor}',
      );
      print(
        '🔍 DEBUG _getHabitForUserHabit: habit.categoryId = ${userHabit.habit!.categoryId}',
      );
      return userHabit.habit!;
    }

    // Si no tiene habit asociado pero tiene customName, crear un habit personalizado
    if (userHabit.customName != null && userHabit.customName!.isNotEmpty) {
      return Habit(
        id: userHabit.habitId ?? userHabit.id,
        name: userHabit.customName!,
        description: userHabit.customDescription ?? '',
        categoryId: '',
        iconName: 'star',
        iconColor: '#6366F1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Fallback: buscar en la lista de hábitos predefinidos
    if (userHabit.habitId != null) {
      try {
        return widget.habits.firstWhere(
          (habit) => habit.id == userHabit.habitId,
        );
      } catch (e) {
        // Si no se encuentra, crear un hábito genérico
        return Habit(
          id: userHabit.habitId!,
          name: 'Hábito personalizado',
          description: '',
          categoryId: '',
          iconName: 'star',
          iconColor: '#6366F1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    // Último fallback
    return Habit(
      id: userHabit.id,
      name: 'Hábito personalizado',
      description: '',
      categoryId: '',
      iconName: 'star',
      iconColor: '#6366F1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  entities.Category _getCategoryForHabit(Habit habit) {
    // Buscar la categoría correspondiente al hábito
    try {
      return widget.categories.firstWhere(
        (category) => category.id == habit.categoryId,
      );
    } catch (e) {
      // Fallback a una categoría genérica si no se encuentra
      return entities.Category(
        id: 'default',
        name: 'General',
        iconName: 'track_changes',
        color: '#6366F1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar hábitos por categoría
    final groupedHabits = <String?, List<UserHabit>>{};

    // Agrupar por categorías específicas
    for (final category in widget.categories) {
      final categoryHabits = _getHabitsForCategory(category.id);
      if (categoryHabits.isNotEmpty) {
        groupedHabits[category.id] = categoryHabits;
      }
    }

    final containerPadding = ResponsiveDimensions.getCardPadding(context);
    final categorySpacing =
        ResponsiveDimensions.getVerticalSpacing(context) * 1.5;
    final titleBottomPadding = ResponsiveDimensions.getVerticalSpacing(context);
    final categoryTitleFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'heading',
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: containerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedHabits.entries.map((entry) {
          final categoryId = entry.key;
          final habits = entry.value;
          final categoryName = widget.categories
              .firstWhere((c) => c.id == categoryId)
              .name;

          return Container(
            key: _categoryKeys[categoryId ?? 'all'],
            margin: EdgeInsets.only(bottom: categorySpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la categoría
                Padding(
                  padding: EdgeInsets.only(bottom: titleBottomPadding),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: categoryTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),

                // Lista de hábitos de la categoría
                ...habits.map((userHabit) {
                  final habit = _getHabitForUserHabit(userHabit);
                  final category = _getCategoryForHabit(habit);
                  return HabitItem(
                    userHabit: userHabit,
                    habit: habit,
                    category: category,
                    isCompleted: userHabit.isCompletedToday,
                    isSelected:
                        false, // Default value since this widget doesn't handle selection
                    onTap: () => widget.onHabitToggle(userHabit),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
