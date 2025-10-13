import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../blocs/category_scroll/category_scroll_bloc.dart';
import '../../blocs/category_scroll/category_scroll_event.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/habit/habit_state.dart';
import '../../widgets/figma_habit_card.dart';
import '../../widgets/main/habit_item.dart';
import '../../widgets/habits/synchronized_habits_list.dart';
import '../../widgets/responsive_dimensions.dart';
import '../../widgets/connectivity_indicator.dart';
import '../progress/progress_main_screen.dart';
import '../progress/habit_progress_screen.dart';
import '../main/main_page.dart';
import 'new_habit_screen.dart';

class MyHabitsIntegratedView extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHabitCreated;

  const MyHabitsIntegratedView({Key? key, this.onBack, this.onHabitCreated})
    : super(key: key);

  @override
  State<MyHabitsIntegratedView> createState() => _MyHabitsIntegratedViewState();
}

class _MyHabitsIntegratedViewState extends State<MyHabitsIntegratedView>
    with TickerProviderStateMixin {
  String? selectedCategoryId;
  String searchQuery = '';
  bool showSuggestions = true;
  bool isSuggestionsExpanded = false;
  bool _isLoading = false;
  bool _hasUserInteracted = false;
  Set<String> _selectedHabits = <String>{};
  late AnimationController _suggestionsAnimationController;
  late Animation<double> _suggestionsAnimation;
  late PageController _pageController;
  late PageController _suggestionsPageController;
  int _currentSuggestionIndex = 0;
  late AnimationController _bounceAnimationController;
  late Animation<double> _bounceAnimation;

  // Nuevas variables para filtros expandidos
  String? selectedFrequency;
  String? selectedCompletionStatus; // 'completed', 'pending', null (todos)
  int? minStreakCount;
  TimeOfDay? selectedScheduledTime;

  @override
  void initState() {
    print('🔍 INICIALIZANDO MIS HÁBITOS - initState() llamado');
    super.initState();
    _suggestionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _suggestionsAnimation = CurvedAnimation(
      parent: _suggestionsAnimationController,
      curve: Curves.easeInOut,
    );
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceAnimationController,
      curve: Curves.elasticOut,
    );
    _pageController = PageController();
    _suggestionsPageController = PageController();

    // Agregar listener simple para PageView de sugerencias
    _suggestionsPageController.addListener(() {
      if (_suggestionsPageController.hasClients) {
        final page = _suggestionsPageController.page?.round() ?? 0;
        if (page != _currentSuggestionIndex) {
          setState(() {
            _currentSuggestionIndex = page;
          });
        }
      }
    });

    // Inicializar la animación en estado contraído por defecto
    _suggestionsAnimationController.value = 0.0;
    isSuggestionsExpanded = false;
    _loadData();
  }

  @override
  void dispose() {
    _suggestionsAnimationController.dispose();
    _bounceAnimationController.dispose();
    _pageController.dispose();
    _suggestionsPageController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _tryGetUserIdFromSupabase();
      if (userId != null) {
        // Use RefreshUserHabits to force reload after habit creation
        context.read<HabitBloc>().add(RefreshUserHabits(userId: userId));
        context.read<HabitBloc>().add(LoadCategories());
        // Cargar sugerencias una sola vez
        await _initializeSuggestionCategory();
      } else {}
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkAndExpandSuggestions(List<UserHabit> userHabits) {
    // Expandir sugerencias por defecto si no hay hábitos y no se ha interactuado manualmente
    if (userHabits.isEmpty && !isSuggestionsExpanded && !_hasUserInteracted) {
      setState(() {
        isSuggestionsExpanded = true;
      });
      _suggestionsAnimationController.forward();
    }
  }

  Future<String?> _tryGetUserIdFromSupabase() async {
    // Try to get user ID directly from Supabase
    try {
      final supabaseUserId = Supabase.instance.client.auth.currentUser?.id;
      if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
        // Return user ID without loading data here - data loading is handled in _loadData
        return supabaseUserId;
      } else {
        // Show error state
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo autenticar el usuario'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
    // Use shouldScrollToFirst=true to trigger automatic scroll and highlight animation
    context.read<HabitBloc>().add(
      FilterHabitsByCategory(categoryId, shouldScrollToFirst: true),
    );
  }

  void _applyFilters() {
    // Aplicar filtros combinados
    context.read<HabitBloc>().add(
      FilterHabitsAdvanced(
        categoryId: selectedCategoryId,
        frequency: selectedFrequency,
        completionStatus: selectedCompletionStatus,
        minStreakCount: minStreakCount,
        scheduledTime: selectedScheduledTime?.format(context),
        shouldScrollToFirst: true,
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _toggleView() {
    setState(() {
      showSuggestions = !showSuggestions;
    });
  }

  Future<void> _initializeSuggestionCategory() async {
    setState(() {
      _currentSuggestionIndex = 0;
    });

    // Cargar TODAS las sugerencias de Supabase una sola vez
    final supabaseUserId = Supabase.instance.client.auth.currentUser?.id;
    if (supabaseUserId != null) {
      context.read<HabitBloc>().add(
        LoadHabitSuggestions(
          userId: supabaseUserId,
          categoryId: null, // Sin filtro de categoría - cargar todas
          limit: 100, // Límite más alto para obtener todas las sugerencias
        ),
      );
    }

    // Asegurar que el PageController esté en la posición correcta
    if (_suggestionsPageController.hasClients) {
      _suggestionsPageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 CONSTRUYENDO MIS HÁBITOS - build() llamado');
    return BlocProvider(
      create: (context) =>
          CategoryScrollBloc()..add(InitializeCategoryScroll()),
      child: BlocListener<HabitBloc, HabitState>(
        listener: (context, state) {
          if (state is UserHabitDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hábito eliminado exitosamente'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            // Recargar datos después de eliminar
            _loadData();
          } else if (state is HabitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        child: Column(
          children: [
            // Main content
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Suggestions dropdown
                      _buildSuggestionsDropdown(),

                      // Header
                      _buildHeader(),

                      // My Habits content
                      _buildMyHabitsView(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis Hábitos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pequeñas acciones que fortalecen tu salud',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF219540).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showFiltersModal,
              icon: const Icon(Icons.tune, color: Color(0xFF219540), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        if (state is HabitLoaded) {
          final hasUserHabits = state.filteredHabits.isNotEmpty;

          // Verificar si las sugerencias deben expandirse automáticamente solo una vez
          if (!_hasUserInteracted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndExpandSuggestions(state.filteredHabits);
            });
          }

          return Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Dropdown header
                GestureDetector(
                  onTap: _toggleSuggestionsDropdown,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF219540).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF219540),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sugerencias de Hábitos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AnimatedRotation(
                            turns: isSuggestionsExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Dropdown content
                SizeTransition(
                  sizeFactor: _suggestionsAnimation,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    child: Column(
                      children: [
                        // Sugerencia destacada única
                        _buildFeaturedSuggestion(),

                        const SizedBox(height: 6),

                        // Indicadores de puntos (slider)
                        _buildDotIndicators(),

                        const SizedBox(height: 16),

                        // Texto antes de los botones
                        const Text(
                          '¿Quieres agregarlo a tus hábitos?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botones de acción
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _toggleSuggestionsDropdown() {
    setState(() {
      isSuggestionsExpanded = !isSuggestionsExpanded;
      _hasUserInteracted = true; // Marcar que el usuario ha interactuado
    });

    if (isSuggestionsExpanded) {
      _suggestionsAnimationController.forward().then((_) {
        // Activar animación de rebote después de expandir
        _bounceAnimationController.reset();
        _bounceAnimationController.forward();
      });
    } else {
      _suggestionsAnimationController.reverse().then((_) {});
    }
  }

  Widget _buildMyHabitsView() {
    print('🔍 CONSTRUYENDO VISTA HÁBITOS - _buildMyHabitsView() llamado');
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, habitState) {
        if (habitState is HabitLoaded) {
          return Column(
            children: [
              // Search bar
              _buildSearchBar(),

              // Synchronized Habits list
              SynchronizedHabitsList(
                userHabits: habitState.filteredHabits,
                habits: [], // Lista vacía por ahora
                categories: habitState.filteredCategories,
                selectedCategoryId: selectedCategoryId,
                onCategoryChanged: _onCategorySelected,
                onHabitToggle: (userHabit) {
                  _toggleHabitCompletion(userHabit);
                },
                onEdit: (userHabit) {
                  _handleHabitAction('edit', userHabit);
                },
                onViewProgress: (userHabit) {
                  _handleHabitAction('progress', userHabit);
                },
                onDelete: (userHabit) {
                  _handleHabitAction('delete', userHabit);
                },
              ),

              // Add habit button
              _buildAddHabitButton(),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar hábitos...',
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 4, right: 12),
            child: Icon(Icons.search, color: Color(0xFF6B7280), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(Habit habit) {
    // Obtener información de la categoría para usar su icono
    final habitState = context.read<HabitBloc>().state;
    String categoryName = 'General';
    Category? category;
    if (habitState is HabitLoaded) {
      category = habitState.categories.cast<Category?>().firstWhere(
        (cat) => cat?.id == habit.categoryId,
        orElse: () => null,
      );
      if (category != null) {
        categoryName = category.name;
      }
    }
    
    final categoryIcon = _getIconForCategory(categoryName, category: category);
    final categoryColor = _getColorForCategory(categoryName, category: category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  habit.description ?? 'Sin descripción',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () =>
                _addHabitFromSuggestion(_habitToSuggestionMap(habit)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF219540),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Agregar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSuggestionItem(Habit habit) {
    // Obtener información de la categoría para usar su icono
    final habitState = context.read<HabitBloc>().state;
    String categoryName = 'General';
    Category? category;
    if (habitState is HabitLoaded) {
      category = habitState.categories.cast<Category?>().firstWhere(
        (cat) => cat?.id == habit.categoryId,
        orElse: () => null,
      );
      if (category != null) {
        categoryName = category.name;
      }
    }
    
    final categoryIcon = _getIconForCategory(categoryName, category: category);
    final categoryColor = _getColorForCategory(categoryName, category: category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _addHabitFromSuggestion(_habitToSuggestionMap(habit)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF219540),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Agregar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(
    UserHabit userHabit,
    List<Habit> habits,
    List<Category> categories,
  ) {
    // Usar userHabit.habit directamente si está disponible (viene del stored procedure con iconos correctos)
    // Solo usar fallback si userHabit.habit es null
    // Esto asegura que los iconos como 'local_drink' se muestren correctamente
    final habit = userHabit.habit ?? habits.firstWhere(
      (h) => h.id == userHabit.habitId,
      orElse: () => Habit(
        id: 'fallback',
        name: userHabit.customName ?? 'Hábito no encontrado',
        description: userHabit.customDescription ?? '',
        categoryId: userHabit.habitId != null ? 'fallback' : userHabit.id,
        iconName: 'star', // Fallback icon
        iconColor: '#6B7280', // Fallback color
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final category = categories.firstWhere(
      (c) => c.id == habit.categoryId,
      orElse: () => Category(
        id: 'fallback',
        name: 'Sin categoría',
        color: '#808080',
        iconName: 'help_outline',
      ),
    );

    // DEBUG: Logs para diagnosticar problema de iconos
    print('🔍 DEBUG MIS HÁBITOS - Hábito: ${habit.name}');
    print('🔍 DEBUG userHabit.habit es null: ${userHabit.habit == null}');
    print('🔍 DEBUG habit.iconName: ${habit.iconName}');
    print('🔍 DEBUG habit.iconColor: ${habit.iconColor}');
    print('🔍 DEBUG userHabit.habit?.iconName: ${userHabit.habit?.iconName}');
    print('🔍 DEBUG userHabit.habit?.iconColor: ${userHabit.habit?.iconColor}');
    print('🔍 DEBUG category.name: ${category.name}');
    print('🔍 DEBUG category.iconName: ${category.iconName}');
    print('🔍 DEBUG ========================================== COMPLETADO CALCULADO');

    return HabitItem(
      userHabit: userHabit,
      habit: habit,
      category: category,
      isCompleted: userHabit.isCompletedToday,
      isSelected: _selectedHabits.contains(userHabit.id),
      isHighlighted:
          false, // Por ahora false, se puede implementar lógica de highlight después
      isFirstInCategory: false, // Por ahora false
      // Al tocar el checkbox, completar el hábito (no solo seleccionar)
      onTap: () => _toggleHabitCompletion(userHabit),
      onSelectionChanged: (id, selected) {
        setState(() {
          if (selected) {
            _selectedHabits.add(id);
          } else {
            _selectedHabits.remove(id);
          }
        });
      },
      onHighlightComplete: () {
        // Callback cuando termine el highlight
      },
    );
  }

  void _toggleHabitCompletion(UserHabit userHabit) {
    // Despachar el evento al HabitBloc para reflejar el completado hoy
    context.read<HabitBloc>().add(
      ToggleHabitCompletion(
        habitId: userHabit.id,
        date: DateTime.now(),
        isCompleted: !userHabit.isCompletedToday,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.track_changes, size: 64, color: Color(0xFF6B7280)),
          const SizedBox(height: 16),
          const Text(
            'No tienes hábitos aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu primer hábito para comenzar',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddHabitButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _navigateToAddHabit,
          icon: const Icon(Icons.add),
          label: const Text('Agregar nuevo hábito'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF167746),
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Color(0xFF167746), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddHabit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewHabitScreen()),
    ).then((result) {
      // Recargar datos si se creó un hábito exitosamente
      if (result == true) {
        _loadData();
        // Notificar a main_page para que recargue el dashboard
        widget.onHabitCreated?.call();
      }
    });
  }

  void _handleHabitAction(String action, UserHabit userHabit) {
    switch (action) {
      case 'edit':
        _navigateToEditHabit(userHabit);
        break;
      case 'progress':
        _navigateToHabitProgress(userHabit);
        break;
      case 'delete':
        _showDeleteConfirmation(userHabit);
        break;
    }
  }

  void _navigateToEditHabit(UserHabit userHabit) {
    // Navegar a NewHabitScreen en modo edición con datos prellenados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NewHabitScreen(isEditMode: true, userHabitToEdit: userHabit),
      ),
    ).then((result) {
      // Recargar datos después de editar
      if (result == true) {
        _loadData();
        // Notificar a main_page para que recargue el dashboard
        widget.onHabitCreated?.call();
      }
    });
  }

  void _navigateToHabitProgress(UserHabit userHabit) {
    // Obtener el userId del usuario actual
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      // Navegar a la pantalla de progreso del hábito específico
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HabitProgressScreen(userHabit: userHabit, userId: userId),
        ),
      );
    } else {
      // Mostrar error si no hay usuario autenticado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(UserHabit userHabit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar hábito'),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${userHabit.habit?.name ?? userHabit.customName ?? 'este hábito'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteHabit(userHabit);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteHabit(UserHabit userHabit) {
    // Usar DeleteUserHabit en lugar de DeleteHabit para eliminación en cascada
    context.read<HabitBloc>().add(DeleteUserHabit(userHabit.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Eliminando hábito "${userHabit.habit?.name ?? userHabit.customName ?? 'Hábito'}"...',
        ),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _handleHabitSelection(UserHabit userHabit) {
    setState(() {
      if (_selectedHabits.contains(userHabit.id)) {
        _selectedHabits.remove(userHabit.id);
      } else {
        _selectedHabits.add(userHabit.id);
      }
    });

    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedHabits.contains(userHabit.id)
              ? 'Hábito seleccionado: ${userHabit.habit?.name ?? userHabit.customName ?? "Hábito"}'
              : 'Hábito deseleccionado: ${userHabit.habit?.name ?? userHabit.customName ?? "Hábito"}',
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _showAddHabitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agregar Hábito',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre del Hábito',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Ej. Beber agua',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ej. Mantenerse hidratado durante el día',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Categoría',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dropdown para categorías
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      hint: const Text('Selecciona una categoría'),
                      items: const [
                        DropdownMenuItem(
                          value: 'alimentacion',
                          child: Text('Alimentación'),
                        ),
                        DropdownMenuItem(
                          value: 'actividad_fisica',
                          child: Text('Actividad Física'),
                        ),
                        DropdownMenuItem(value: 'sueno', child: Text('Sueño')),
                        DropdownMenuItem(
                          value: 'salud_mental',
                          child: Text('Salud Mental'),
                        ),
                      ],
                      onChanged: (value) {
                        // Lógica para manejar el cambio de categoría
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Frecuencia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dropdown para frecuencia
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      hint: const Text('Selecciona la frecuencia'),
                      items: const [
                        DropdownMenuItem(
                          value: 'diario',
                          child: Text('Diario'),
                        ),
                        DropdownMenuItem(
                          value: 'semanal',
                          child: Text('Semanal'),
                        ),
                        DropdownMenuItem(
                          value: 'mensual',
                          child: Text('Mensual'),
                        ),
                      ],
                      onChanged: (value) {
                        // Lógica para manejar el cambio de frecuencia
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Recordatorio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Ej. 09:00 AM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para guardar el hábito
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar Hábito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSuggestion() {
    final habitState = context.read<HabitBloc>().state;
    if (habitState is! HabitLoaded) {
      return const SizedBox(height: 110);
    }

    final allSuggestions = habitState.habitSuggestions;

    if (allSuggestions.isEmpty) {
      return Container(
        height: 110,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No hay sugerencias disponibles',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    // Verificar que la animación esté inicializada
    if (!_bounceAnimationController.isCompleted &&
        !_bounceAnimationController.isAnimating) {
      _bounceAnimationController.forward();
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        // Verificar que el controlador esté inicializado
        if (!mounted) {
          return const SizedBox(height: 100);
        }

        return Container(
          height: 110,
          child: PageView.builder(
            controller: _suggestionsPageController,
            itemCount: allSuggestions.length,
            padEnds: false,
            pageSnapping: true,
            onPageChanged: (index) {
              setState(() {
                _currentSuggestionIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final habit = allSuggestions[index];
              //   '🔍 SUPABASE DEBUG: Building suggestion card for: ${habit.name} (categoryId: ${habit.categoryId})',
              // );

              // Obtener información de la categoría
              String categoryName = 'General';
              final category = habitState.categories
                  .cast<Category?>()
                  .firstWhere(
                    (cat) => cat?.id == habit.categoryId,
                    orElse: () => habitState.categories.isNotEmpty
                        ? habitState.categories.first
                        : null,
                  );
              if (category != null) {
                categoryName = category.name;
              }

              final iconData = _getIconForCategory(categoryName, category: category);
              final colorData = _getColorForCategory(categoryName, category: category);

              // Aplicar animación de rebote con delay escalonado
              final animationDelay = (index * 0.1).clamp(0.0, 1.0);
              final bounceValue = Curves.elasticOut.transform(
                (_bounceAnimation.value - animationDelay).clamp(0.0, 1.0),
              );

              return Transform.scale(
                scale: 0.8 + (bounceValue * 0.2),
                child: Transform.translate(
                  offset: Offset(0, -10 * bounceValue),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    margin: ResponsiveDimensions.getCardMargin(context),
                    padding: ResponsiveDimensions.getCardPadding(context),
                    constraints: BoxConstraints(
                      minHeight: ResponsiveDimensions.getCardMinHeight(context),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAF5E9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05 * bounceValue),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorData.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(iconData, color: colorData, size: 20),
                            ),
                            SizedBox(
                              width: ResponsiveDimensions.getSpacing(
                                context,
                                12,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveDimensions.getFontSize(
                                            context,
                                            12,
                                          ),
                                      color: colorData,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    habit.name,
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveDimensions.getFontSize(
                                            context,
                                            14,
                                          ),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: ResponsiveDimensions.getSpacing(context, 8),
                        ),
                        Text(
                          habit.description ??
                              'Hábito recomendado para mejorar tu bienestar',
                          style: TextStyle(
                            fontSize: ResponsiveDimensions.getFontSize(
                              context,
                              12,
                            ),
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDotIndicators() {
    final habitState = context.read<HabitBloc>().state;
    if (habitState is! HabitLoaded) {
      return const SizedBox.shrink();
    }

    final suggestions = habitState.habitSuggestions;
    final totalSuggestions = suggestions.length;

    if (totalSuggestions == 0) {
      return const SizedBox.shrink();
    }

    // Usar el índice actual del PageView
    final currentIndex = _currentSuggestionIndex.clamp(0, totalSuggestions - 1);

    // Limitar la cantidad de puntos visibles para evitar overflow
    const maxVisibleDots = 7;
    final showAllDots = totalSuggestions <= maxVisibleDots;

    if (showAllDots) {
      // Mostrar todos los puntos si son pocos
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSuggestions, (index) {
          final isActive = currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 12 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF219540)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    } else {
      // Mostrar indicadores con scroll visual cuando hay muchos puntos
      return Container(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicador de más contenido a la izquierda
            if (currentIndex > 2)
              Container(
                margin: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

            // Puntos principales (máximo 5 visibles)
            ...List.generate(5, (i) {
              int actualIndex;
              if (currentIndex <= 2) {
                actualIndex = i;
              } else if (currentIndex >= totalSuggestions - 3) {
                actualIndex = totalSuggestions - 5 + i;
              } else {
                actualIndex = currentIndex - 2 + i;
              }

              if (actualIndex < 0 || actualIndex >= totalSuggestions) {
                return const SizedBox.shrink();
              }

              final isActive = currentIndex == actualIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF219540)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),

            // Indicador de más contenido a la derecha
            if (currentIndex < totalSuggestions - 3)
              Container(
                margin: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _getCurrentSuggestion() async {
    final habitState = context.read<HabitBloc>().state;

    if (habitState is HabitLoaded) {
      // Filtrar sugerencias rechazadas
      final filteredSuggestions = await _filterRejectedSuggestions(
        habitState.habitSuggestions,
      );

      if (filteredSuggestions.isNotEmpty &&
          _currentSuggestionIndex < filteredSuggestions.length) {
        final habit = filteredSuggestions[_currentSuggestionIndex];

        // Obtener el nombre de la categoría
        String categoryName = 'General';
        final category = habitState.categories.cast<Category?>().firstWhere(
          (cat) => cat?.id == habit.categoryId,
          orElse: () => habitState.categories.isNotEmpty
              ? habitState.categories.first
              : null,
        );
        if (category != null) {
          categoryName = category.name;
        }

        return {
          'title': habit.name,
          'description': habit.description ?? 'Hábito recomendado',
          'icon': _getIconForCategory(categoryName, category: category),
          'color': _getColorForCategory(categoryName, category: category),
          'category': categoryName,
        };
      }
    }

    return null;
  }

  // Métodos para manejar sugerencias rechazadas
  Future<void> _saveRejectedSuggestion(
    String habitName,
    String category,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rejectedKey =
          '${habitName.toLowerCase()}_${category.toLowerCase()}';

      // Obtener lista actual de sugerencias rechazadas
      List<String> rejectedSuggestions =
          prefs.getStringList('rejected_suggestions') ?? [];

      // Agregar nueva sugerencia rechazada si no existe
      if (!rejectedSuggestions.contains(rejectedKey)) {
        rejectedSuggestions.add(rejectedKey);
        await prefs.setStringList('rejected_suggestions', rejectedSuggestions);
      }
    } catch (e) {}
  }

  Future<List<String>> _loadRejectedSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('rejected_suggestions') ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Habit>> _filterRejectedSuggestions(
    List<Habit> suggestions,
  ) async {
    final rejectedSuggestions = await _loadRejectedSuggestions();

    return suggestions.where((habit) {
      // Obtener el nombre de la categoría para este hábito
      final habitState = context.read<HabitBloc>().state;
      String categoryName = 'General';

      if (habitState is HabitLoaded) {
        final category = habitState.categories.cast<Category?>().firstWhere(
          (cat) => cat?.id == habit.categoryId,
          orElse: () => null,
        );
        if (category != null) {
          categoryName = category.name;
        }
      }

      final habitKey =
          '${habit.name.toLowerCase()}_${categoryName.toLowerCase()}';
      return !rejectedSuggestions.contains(habitKey);
    }).toList();
  }

  IconData _getIconForCategory(String categoryName, {Category? category}) {
    print('🔍 DEBUG _getIconForCategory - categoryName: $categoryName');
    print('🔍 DEBUG _getIconForCategory - category: ${category?.name}');
    print('🔍 DEBUG _getIconForCategory - category.iconName: ${category?.iconName}');
    
    // Si tenemos la categoría, usar su icono de la base de datos
    if (category?.iconName != null) {
      final iconData = _getIconData(category!.iconName!);
      print('🔍 DEBUG _getIconForCategory - usando icono de BD: ${category.iconName} -> $iconData');
      return iconData;
    }
    
    print('🔍 DEBUG _getIconForCategory - usando fallback para: $categoryName');
    // Fallback a mapeo por nombre (mantener compatibilidad)
    switch (categoryName.toLowerCase()) {
      case 'alimentación':
        return Icons.restaurant;
      case 'actividad física':
        return Icons.fitness_center;
      case 'sueño':
        return Icons.bedtime;
      case 'hidratación':
        return Icons.water_drop;
      case 'bienestar mental':
        return Icons.psychology;
      case 'productividad':
        return Icons.track_changes;
      default:
        return Icons.star;
    }
  }

  Color _getColorForCategory(String categoryName, {Category? category}) {
    print('🔍 DEBUG _getColorForCategory - categoryName: $categoryName');
    print('🔍 DEBUG _getColorForCategory - category: ${category?.name}');
    print('🔍 DEBUG _getColorForCategory - category.color: ${category?.color}');
    
    // Si tenemos la categoría, usar su color de la base de datos
    if (category?.color != null) {
      final color = _getIconColor(category!.color!);
      print('🔍 DEBUG _getColorForCategory - usando color de BD: ${category.color} -> $color');
      return color;
    }
    
    print('🔍 DEBUG _getColorForCategory - usando fallback para: $categoryName');
    // Fallback a mapeo por nombre (mantener compatibilidad)
    switch (categoryName.toLowerCase()) {
      case 'alimentación':
        return const Color(0xFF4CAF50); // Verde
      case 'actividad física':
        return const Color(0xFF2196F3); // Azul
      case 'sueño':
        return const Color(0xFF9C27B0); // Púrpura
      case 'hidratación':
        return const Color(0xFF00BCD4); // Cian
      case 'bienestar mental':
        return const Color(0xFFFF9800); // Naranja
      case 'productividad':
        return const Color(0xFF795548); // Marrón
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _navigateToNewHabit({bool prefillData = false}) async {
    final currentSuggestion = await _getCurrentSuggestion();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewHabitScreen(
          prefilledHabitName: prefillData && currentSuggestion != null
              ? currentSuggestion['title'] as String
              : null,
          prefilledDescription: prefillData && currentSuggestion != null
              ? currentSuggestion['description'] as String
              : null,
          prefilledCategoryId: prefillData && currentSuggestion != null
              ? _getCategoryIdByName(currentSuggestion['category'] as String)
              : null,
        ),
      ),
    ).then((result) {
      // Recargar datos cuando regrese de la pantalla de nuevo hábito
      if (result == true) {
        _loadData();
        // Notificar a main_page para que recargue el dashboard
        widget.onHabitCreated?.call();
      }
    });
  }

  String? _getCategoryIdByName(String categoryName) {
    final habitState = context.read<HabitBloc>().state;

    if (habitState is HabitLoaded) {
      final category = habitState.categories.cast<Category?>().firstWhere(
        (cat) => cat?.name.toLowerCase() == categoryName.toLowerCase(),
        orElse: () => null,
      );
      return category?.id;
    }
    return null;
  }

  Map<String, dynamic> _habitToSuggestionMap(Habit habit) {
    final habitState = context.read<HabitBloc>().state;
    String categoryName = 'General';

    if (habitState is HabitLoaded) {
      final category = habitState.categories.cast<Category?>().firstWhere(
        (cat) => cat?.id == habit.categoryId,
        orElse: () => null,
      );
      if (category != null) {
        categoryName = category.name;
      }
    }

    return {
      'title': habit.name,
      'description': habit.description ?? '',
      'category': categoryName,
    };
  }

  Future<void> _addHabitFromSuggestion(Map<String, dynamic> suggestion) async {
    try {
      print('DEBUG: Iniciando _addHabitFromSuggestion con datos: $suggestion');

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('DEBUG: Usuario no autenticado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario no autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('DEBUG: Usuario autenticado: ${user.id}');

      // Obtener category_id
      final categoryId = _getCategoryIdByName(suggestion['category'] as String);
      print(
        'DEBUG: Category ID obtenido: $categoryId para categoría: ${suggestion['category']}',
      );

      // Crear el user_habit directamente con los datos de la sugerencia
      final userHabitData = <String, dynamic>{
        'user_id': user.id,
        // No incluir habit_id para hábitos custom (null causa problemas de UUID)
        'frequency': 'daily',
        'frequency_details': {'times_per_day': 1},
        'scheduled_time': '09:00:00',
        'notifications_enabled': true,
        'notification_time': '09:00:00',
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'is_active': true,
        'is_public':
            false, // Los hábitos desde sugerencias son privados por defecto
        'custom_name': suggestion['title'] as String,
        'custom_description': suggestion['description'] as String,
        'category_id': categoryId,
      };

      print('DEBUG: Datos del hábito a insertar: $userHabitData');

      await Supabase.instance.client.from('user_habits').insert(userHabitData);

      print('DEBUG: Hábito insertado exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito agregado exitosamente'),
            backgroundColor: Color(0xFF219540),
          ),
        );

        // Cerrar las sugerencias y recargar datos
        setState(() {
          isSuggestionsExpanded = false;
          _hasUserInteracted = true;
        });
        _suggestionsAnimationController.reverse();
        _loadData();
        // Notificar a main_page para que recargue el dashboard
        widget.onHabitCreated?.call();
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error en _addHabitFromSuggestion: $e');
      print('DEBUG: Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar hábito: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Botones de acción principales
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  // Guardar sugerencia rechazada antes de navegar a la siguiente
                  final currentSuggestion = await _getCurrentSuggestion();
                  if (currentSuggestion != null) {
                    await _saveRejectedSuggestion(
                      currentSuggestion['title'] as String,
                      currentSuggestion['category'] as String,
                    );
                  }

                  // Navegar a la siguiente sugerencia o cerrar si es la última
                  await _navigateToNextSuggestion();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Rechazar',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  // Navegar a nueva pantalla de hábito con datos prellenados
                  await _navigateToNewHabit(prefillData: true);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF219540),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Configurar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToPreviousSuggestion() {
    final habitState = context.read<HabitBloc>().state;
    if (habitState is HabitLoaded && _currentSuggestionIndex > 0) {
      setState(() {
        _currentSuggestionIndex--;
      });
    }
  }

  Future<void> _navigateToNextSuggestion() async {
    final habitState = context.read<HabitBloc>().state;
    if (habitState is HabitLoaded) {
      final totalSuggestions = habitState.habitSuggestions.length;

      if (_currentSuggestionIndex < totalSuggestions - 1) {
        setState(() {
          _currentSuggestionIndex++;
        });
      } else {
        // Si es la última sugerencia, cerrar las sugerencias
        setState(() {
          isSuggestionsExpanded = false;
          _hasUserInteracted = true;
        });
        _suggestionsAnimationController.reverse();
      }
    }
  }

  void _showFiltersModal() {
    // Estados temporales locales para que el modal sea reactivo
    String? tempCategoryId = selectedCategoryId;
    String? tempFrequency = selectedFrequency;
    String? tempCompletionStatus = selectedCompletionStatus;
    int? tempMinStreakCount = minStreakCount;
    TimeOfDay? tempScheduledTime = selectedScheduledTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrar Hábitos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtro por Categoría
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<HabitBloc, HabitState>(
                        builder: (context, state) {
                          if (state is HabitLoaded) {
                            return Column(
                              children: [
                                _buildFilterOption(
                                  'Todas las categorías',
                                  tempCategoryId == null,
                                  () {
                                    modalSetState(() {
                                      tempCategoryId = null;
                                    });
                                  },
                                ),
                                ...state.categories.map(
                                  (category) => _buildFilterOption(
                                    category.name,
                                    tempCategoryId == category.id,
                                    () {
                                      modalSetState(() {
                                        tempCategoryId = category.id;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Filtro por Frecuencia
                      const Text(
                        'Frecuencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          _buildFilterOption(
                            'Todas las frecuencias',
                            tempFrequency == null,
                            () {
                              modalSetState(() {
                                tempFrequency = null;
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Diario',
                            tempFrequency == 'daily',
                            () {
                              modalSetState(() {
                                tempFrequency = 'daily';
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Semanal',
                            tempFrequency == 'weekly',
                            () {
                              modalSetState(() {
                                tempFrequency = 'weekly';
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Mensual',
                            tempFrequency == 'monthly',
                            () {
                              modalSetState(() {
                                tempFrequency = 'monthly';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Filtro por Estado de Completado
                      const Text(
                        'Estado de Completado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          _buildFilterOption(
                            'Todos los estados',
                            tempCompletionStatus == null,
                            () {
                              modalSetState(() {
                                tempCompletionStatus = null;
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Completados hoy',
                            tempCompletionStatus == 'completed',
                            () {
                              modalSetState(() {
                                tempCompletionStatus = 'completed';
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Pendientes',
                            tempCompletionStatus == 'pending',
                            () {
                              modalSetState(() {
                                tempCompletionStatus = 'pending';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Filtro por Racha Mínima
                      const Text(
                        'Racha Mínima',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Ej: 5 días',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  modalSetState(() {
                                    tempMinStreakCount = int.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Padding inferior para evitar solapamiento con botones fijos
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              // Botones fijos al fondo
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            modalSetState(() {
                              tempCategoryId = null;
                              tempFrequency = null;
                              tempCompletionStatus = null;
                              tempMinStreakCount = null;
                              tempScheduledTime = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Persistir selección a estado del padre y aplicar filtros
                            setState(() {
                              selectedCategoryId = tempCategoryId;
                              selectedFrequency = tempFrequency;
                              selectedCompletionStatus = tempCompletionStatus;
                              minStreakCount = tempMinStreakCount;
                              selectedScheduledTime = tempScheduledTime;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static map for icon name to IconData mapping
  static const Map<String, IconData> _iconMap = {
    // Iconos de las categorías de la base de datos
    'utensils': Icons.restaurant,
    'restaurant': Icons.restaurant,
    'food': Icons.restaurant,
    'activity': Icons.fitness_center,
    'fitness_center': Icons.fitness_center,
    'exercise': Icons.fitness_center,
    'moon': Icons.bedtime,
    'bed': Icons.bedtime,
    'sleep': Icons.bedtime,
    'droplet': Icons.water_drop,
    'water_drop': Icons.water_drop,
    'water': Icons.water_drop,
    'local_drink': Icons.local_drink,
    'brain': Icons.psychology,
    'psychology': Icons.psychology,
    'mental': Icons.psychology,
    'target': Icons.track_changes,
    'track_changes': Icons.track_changes,
    'productivity': Icons.track_changes,
    // Iconos específicos de la base de datos
    'apple': Icons.apple,
    'directions_walk': Icons.directions_walk,
    'accessibility_new': Icons.accessibility_new,
    'bedtime': Icons.bedtime,
    'phone_iphone': Icons.phone_iphone,
    'self_improvement': Icons.self_improvement,
    'edit': Icons.edit,
    'menu_book': Icons.menu_book,
    'event_note': Icons.event_note,
    // Iconos adicionales
    'favorite': Icons
        .fitness_center, // Cambiar de corazón a fitness para hábitos generales
    'heart': Icons.favorite,
    'work': Icons.work,
    'business': Icons.work,
    'school': Icons.school,
    'education': Icons.school,
    'person': Icons.person,
    'personal': Icons.person,
    'home': Icons.home,
    'house': Icons.home,
    'people': Icons.people,
    'social': Icons.people,
    'palette': Icons.palette,
    'creative': Icons.palette,
    'spiritual': Icons.self_improvement,
    'movie': Icons.movie,
    'entertainment': Icons.movie,
    'attach_money': Icons.attach_money,
    'money': Icons.attach_money,
    'finance': Icons.attach_money,
    'fastfood': Icons.fastfood,
    'general': Icons.track_changes,
  };

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.star;

    // Get icon from map using lowercase key, return default if not found
    return _iconMap[iconName.toLowerCase()] ?? Icons.star;
  }

  Color _getIconColor(String? colorString) {
    if (colorString == null) return const Color(0xFF6B7280);

    try {
      String cleanColor = colorString.trim();

      // Remove # if present
      if (cleanColor.startsWith('#')) {
        cleanColor = cleanColor.substring(1);
      }

      // Ensure we have a valid hex color (6 or 8 characters)
      if (cleanColor.length == 6) {
        // Add alpha channel for 6-digit hex
        cleanColor = 'FF$cleanColor';
      } else if (cleanColor.length != 8) {
        // Invalid length, use default
        return const Color(0xFF6B7280);
      }

      // Parse as hex and create Color
      final colorValue = int.parse(cleanColor, radix: 16);
      return Color(colorValue);
    } catch (e) {
      // Debug: print error for troubleshooting
      return const Color(0xFF6B7280);
    }
  }
}
