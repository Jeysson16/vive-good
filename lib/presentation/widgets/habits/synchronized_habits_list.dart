import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/category.dart' as entities;
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../services/habits_service.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_state.dart';
import '../common/responsive_dimensions.dart';
import '../main/compact_habit_item.dart';

class SynchronizedHabitsList extends StatefulWidget {
  final List<UserHabit> userHabits;
  final List<Habit> habits;
  final List<entities.Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategoryChanged;
  final Function(UserHabit) onHabitToggle;
  final Function(UserHabit)? onEdit;
  final Function(UserHabit)? onViewProgress;
  final Function(UserHabit)? onDelete;

  const SynchronizedHabitsList({
    super.key,
    required this.userHabits,
    required this.habits,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onHabitToggle,
    this.onEdit,
    this.onViewProgress,
    this.onDelete,
  });

  @override
  State<SynchronizedHabitsList> createState() => _SynchronizedHabitsListState();
}

class _SynchronizedHabitsListState extends State<SynchronizedHabitsList>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _lastVisibleCategory;
  String? _previousSelectedCategoryId;
  String? _highlightedHabitId;
  AnimationController? _highlightController;
  Animation<double>? _highlightAnimation;
  
  // Variable para almacenar los IDs de hábitos completados hoy
  Set<String> _completedTodayHabitIds = {};

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG SYNC HABITS - initState() ejecutado, cargando hábitos completados...');
    
    _scrollController = ScrollController();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController!, curve: Curves.easeInOut),
    );
    _initializeCategoryKeys();
    
    print('🔍 DEBUG SYNC HABITS - Inicializando SynchronizedHabitsList');
    
    // Cargar hábitos completados al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 DEBUG SYNC HABITS - PostFrameCallback ejecutado, llamando _loadCompletedTodayHabits()');
      _loadCompletedTodayHabits();
    });
  }

  void _initializeCategoryKeys() {
    _categoryKeys.clear();
    _categoryKeys['all'] = GlobalKey();
    for (final category in widget.categories) {
      _categoryKeys[category.id] = GlobalKey();
    }
  }

  /// Carga los hábitos completados hoy desde el backend
  Future<void> _loadCompletedTodayHabits() async {
    print('🔍 DEBUG SYNC HABITS - Cargando hábitos completados hoy...');
    
    try {
      print('🔍 DEBUG SYNC HABITS - Llamando a HabitsService.getTodayCompletedHabits()...');
      final completedHabits = await HabitsService.getTodayCompletedHabits();
      
      print('🔍 DEBUG SYNC HABITS - Respuesta recibida: ${completedHabits.length} hábitos');
      print('🔍 DEBUG SYNC HABITS - Datos completos: $completedHabits');
      
      setState(() {
        _completedTodayHabitIds = completedHabits
            .map((habit) => habit['user_habit_id'] as String)
            .toSet();
      });
      
      print('🔍 DEBUG SYNC HABITS - Hábitos completados hoy cargados: ${_completedTodayHabitIds.length}');
      print('🔍 DEBUG SYNC HABITS - IDs completados: $_completedTodayHabitIds');
      print('🔍 DEBUG SYNC HABITS - _loadCompletedTodayHabits() completado. IDs cargados: $_completedTodayHabitIds');
    } catch (e) {
      print('❌ DEBUG SYNC HABITS - Error al cargar hábitos completados: $e');
      setState(() {
        _completedTodayHabitIds = {};
      });
      print('🔍 DEBUG SYNC HABITS - _loadCompletedTodayHabits() completado con error. IDs cargados: $_completedTodayHabitIds');
    }
   }

  /// Verifica si un hábito está completado hoy
  bool _isHabitCompletedToday(String userHabitId) {
    final isCompleted = _completedTodayHabitIds.contains(userHabitId);
    print('🔍 DEBUG SYNC HABITS - Hábito $userHabitId completado hoy: $isCompleted');
    return isCompleted;
  }

  /// Método público para refrescar los hábitos completados
  void _refreshCompletedHabits() {
    print('🔄 SYNC HABITS - Refrescando hábitos completados manualmente');
    _loadCompletedTodayHabits();
  }
 
    @override
    void dispose() {
    _scrollController.dispose();
    _highlightController?.dispose();
    super.dispose();
  }

  void _scrollToFirstHabitOfCategory(String categoryId) {
    final categoryHabits = _getHabitsForCategory(categoryId);

    if (categoryHabits.isNotEmpty) {
      final firstHabit = categoryHabits.first;
      _highlightHabit(firstHabit.id);

      // Scroll to category section
      final categoryKey = _categoryKeys[categoryId];
      if (categoryKey?.currentContext != null) {
        Scrollable.ensureVisible(
          categoryKey!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: 0.1, // Show category title at top
        );
      }
    }
  }

  void _highlightHabit(String habitId) {
    // Verificar que el controlador esté inicializado
    if (_highlightController == null) {
      return;
    }

    setState(() {
      _highlightedHabitId = habitId;
    });

    _highlightController!.reset();
    _highlightController!.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _highlightController != null) {
          setState(() {
            _highlightedHabitId = null;
          });
          _highlightController!.reset();
        }
      });
    });
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
    // Si el userHabit tiene un habit asociado (del stored procedure), usarlo
    if (userHabit.habit != null) {
      return userHabit.habit!;
    }

    // Si no tiene habit asociado pero tiene customName, crear un habit personalizado
    if (userHabit.customName != null && userHabit.customName!.isNotEmpty) {
      return Habit(
        id: userHabit.habitId ?? userHabit.id,
        name: userHabit.customName ?? 'Hábito personalizado',
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
          id: userHabit.habitId ?? userHabit.id,
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
    return BlocListener<HabitBloc, HabitState>(
      listener: (context, state) {
        print('🔄 SYNC HABITS - Listener ejecutado, estado: ${state.runtimeType}');
        if (state is HabitLoaded) {
          print('🔄 SYNC HABITS - Estado actualizado, recargando hábitos completados');
          _loadCompletedTodayHabits();
        }
      },
      child: _buildHabitsList(context),
    );
  }

  Widget _buildHabitsList(BuildContext context) {
    // Check if category selection changed and trigger scroll
    if (widget.selectedCategoryId != null &&
        widget.selectedCategoryId != _previousSelectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstHabitOfCategory(widget.selectedCategoryId!);
      });
      _previousSelectedCategoryId = widget.selectedCategoryId;
    }

    // Agrupar hábitos por categoría
    final groupedHabits = <String?, List<UserHabit>>{};

    // Si hay categoría seleccionada, mostrar SOLO esa categoría
    final categoriesToRender = widget.selectedCategoryId != null
        ? widget.categories.where((c) => c.id == widget.selectedCategoryId).toList()
        : widget.categories;

    for (final category in categoriesToRender) {
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
                  final isHighlighted = _highlightedHabitId == userHabit.id;
                  final isCompletedToday = _isHabitCompletedToday(userHabit.id);

                  // Log de depuración para verificar los datos del hábito
                  print('🔍 DEBUG SYNC HABITS - Hábito: ${userHabit.customName ?? habit.name}, ID: ${userHabit.id}, Completado: $isCompletedToday, Icono: ${habit.iconName}, Color: ${habit.iconColor}');

                  Widget habitItem = CompactHabitItem(
                    userHabit: userHabit,
                    habit: habit,
                    category: category,
                    isCompleted: isCompletedToday,
                    isHighlighted: isHighlighted,
                    onTap: () {
                      widget.onHabitToggle(userHabit);
                    },
                    onHighlightComplete: () {
                      if (mounted) {
                        setState(() {
                          _highlightedHabitId = null;
                        });
                      }
                    },
                    onEdit: widget.onEdit,
                    onViewProgress: widget.onViewProgress,
                    onDelete: widget.onDelete,
                  );

                  // Wrap with AnimatedBuilder for highlight effect
                  if (isHighlighted && _highlightAnimation != null) {
                    habitItem = AnimatedBuilder(
                      animation: _highlightAnimation!,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.4 * _highlightAnimation!.value),
                                blurRadius: 20 * _highlightAnimation!.value,
                                spreadRadius: 5 * _highlightAnimation!.value,
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
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
