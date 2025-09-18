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
import '../../widgets/animated_category_tabs_with_line.dart';
import '../../widgets/habits/synchronized_habits_list.dart';
import '../../widgets/responsive_dimensions.dart';
import 'new_habit_screen.dart';

class MyHabitsIntegratedView extends StatefulWidget {
  final VoidCallback? onBack;

  const MyHabitsIntegratedView({Key? key, this.onBack}) : super(key: key);

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
  late AnimationController _suggestionsAnimationController;
  late Animation<double> _suggestionsAnimation;
  late PageController _pageController;
  late PageController _suggestionsPageController;
  int _currentSuggestionIndex = 0;
  late AnimationController _bounceAnimationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
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
        context.read<HabitBloc>().add(LoadUserHabits(userId: userId));
        // Cargar sugerencias una sola vez
        await _initializeSuggestionCategory();
        print('DEBUG: Loading suggestions for user: $userId'); // Debug log
      } else {
        print('DEBUG: No user ID found, cannot load suggestions'); // Debug log
      }
    } catch (e) {
      print('Error loading data: $e');
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
        print('🔄 Obteniendo ID desde Supabase: $supabaseUserId');
        // AÑADE ESTA LÍNEA PARA VER EL USER ID EN LA CONSOLA
        print('DEBUG: Current Supabase User ID: $supabaseUserId');
        context.read<HabitBloc>().add(
          LoadDashboardHabits(userId: supabaseUserId, date: DateTime.now()),
        );
        context.read<HabitBloc>().add(LoadCategories());

        // Las sugerencias se cargarán cuando sea necesario
        return supabaseUserId;
      } else {
        print('❌ No se pudo obtener ID de usuario desde Supabase');
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
      print('❌ Error al obtener ID de Supabase: $e');
      return null;
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
    context.read<HabitBloc>().add(FilterHabitsByCategory(categoryId));
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

    // Cargar TODAS las sugerencias de Supabase una sola vez (sin filtro de categoría)
    print(
      '🔍 SUPABASE DEBUG: Cargando TODAS las sugerencias sin filtro de categoría',
    );
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
    return BlocProvider(
      create: (context) =>
          CategoryScrollBloc()..add(InitializeCategoryScroll()),
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
    print(
      'DEBUG: Toggle suggestions dropdown called. Current state: $isSuggestionsExpanded',
    );
    print(
      'DEBUG: Animation controller value: ${_suggestionsAnimationController.value}',
    );
    print(
      'DEBUG: Animation controller status: ${_suggestionsAnimationController.status}',
    );

    setState(() {
      isSuggestionsExpanded = !isSuggestionsExpanded;
      _hasUserInteracted = true; // Marcar que el usuario ha interactuado
    });

    print('DEBUG: New state: $isSuggestionsExpanded');

    if (isSuggestionsExpanded) {
      print('DEBUG: Starting forward animation');
      _suggestionsAnimationController.forward().then((_) {
        print('DEBUG: Forward animation completed');
        // Activar animación de rebote después de expandir
        _bounceAnimationController.reset();
        _bounceAnimationController.forward();
      });
    } else {
      print('DEBUG: Starting reverse animation');
      _suggestionsAnimationController.reverse().then((_) {
        print('DEBUG: Reverse animation completed');
      });
    }
  }

  Widget _buildMyHabitsView() {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, habitState) {
        if (habitState is HabitLoaded) {
          return Column(
            children: [
              // Search bar
              _buildSearchBar(),

              // Animated Category tabs with scroll
              AnimatedCategoryTabsWithLine(
                categories: habitState.categories,
                selectedCategoryId: selectedCategoryId,
                onCategorySelected: _onCategorySelected,
              ),

              // Synchronized Habits list
              SynchronizedHabitsList(
                userHabits: habitState.filteredHabits,
                habits: [], // Lista vacía por ahora
                categories: habitState.categories,
                selectedCategoryId: selectedCategoryId,
                onCategoryChanged: _onCategorySelected,
                onHabitToggle: (userHabit) {
                  // Implementar toggle de hábito
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
              color: _getIconColor(habit.iconColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconData(habit.iconName),
              color: _getIconColor(habit.iconColor),
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
              color: _getIconColor(habit.iconColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getIconData(habit.iconName),
              color: _getIconColor(habit.iconColor),
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

  Widget _buildHabitItem(UserHabit userHabit) {
    // Determinar el color basado en el estado del hábito
    final bool isCompleted = userHabit.isCompletedToday;
    final Color statusColor = isCompleted
        ? const Color(0xFF219540)
        : const Color(0xFFF59E0B);
    final Color backgroundColor = isCompleted
        ? const Color(0xFF219540).withOpacity(0.1)
        : const Color(0xFFF59E0B).withOpacity(0.1);
    final IconData statusIcon = isCompleted
        ? Icons.check_circle
        : Icons.schedule;

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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(statusIcon, color: statusColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hábito ${userHabit.habitId}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Frecuencia: ${userHabit.frequency}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (userHabit.scheduledTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Programado: ${userHabit.scheduledTime}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) => _handleHabitAction(value, userHabit),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar hábito'),
                ),
                const PopupMenuItem(
                  value: 'progress',
                  child: Text('Ver progreso'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar hábito'),
                ),
              ],
              child: const Icon(
                Icons.more_vert,
                color: Color(0xFF6B7280),
                size: 20,
              ),
            ),
          ),
        ],
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
    );
  }

  void _handleHabitAction(String action, UserHabit userHabit) {
    switch (action) {
      case 'edit':
        // TODO: Implementar lógica para guardar nuevo hábito
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito guardado exitosamente'),
            backgroundColor: Color(0xFF219540),
          ),
        );
        break;
      case 'progress':
        break;
      case 'delete':
        break;
    }
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
              // print('🔍 SUPABASE DEBUG: PageView changed to index: $index');
            },
            itemBuilder: (context, index) {
              final habit = allSuggestions[index];
              // print(
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

              final iconData = _getIconForCategory(categoryName);
              final colorData = _getColorForCategory(categoryName);

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
            color: isActive ? const Color(0xFF219540) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
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
          'icon': _getIconForCategory(categoryName),
          'color': _getColorForCategory(categoryName),
          'category': categoryName,
        };
      }
    }

    print('🔍 SUPABASE DEBUG: No suggestions available');
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
        print('🚫 Sugerencia rechazada guardada: $rejectedKey');
      }
    } catch (e) {
      print('❌ Error al guardar sugerencia rechazada: $e');
    }
  }

  Future<List<String>> _loadRejectedSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('rejected_suggestions') ?? [];
    } catch (e) {
      print('❌ Error al cargar sugerencias rechazadas: $e');
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

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentación':
        return Icons.restaurant;
      case 'actividad física':
        return Icons.fitness_center;
      case 'sueño':
        return Icons.bedtime;
      case 'bienestar mental':
        return Icons.psychology;
      default:
        return Icons.star;
    }
  }

  Color _getColorForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentación':
        return const Color(0xFF10B981);
      case 'actividad física':
        return const Color(0xFF3B82F6);
      case 'sueño':
        return const Color(0xFF8B5CF6);
      case 'bienestar mental':
        return const Color(0xFFEC4899);
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
    ).then((_) {
      // Recargar datos cuando regrese de la pantalla de nuevo hábito
      _loadData();
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario no autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Crear el user_habit directamente con los datos de la sugerencia
      final userHabitData = {
        'user_id': user.id,
        'habit_id': null, // Hábito custom
        'frequency': 'diario',
        'frequency_details': {'times_per_day': 1},
        'scheduled_time': '09:00:00',
        'notifications_enabled': true,
        'notification_time': '09:00:00',
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'is_active': true,
        'is_public':
            false, // Los hábitos desde sugerencias son privados por defecto
        'estimated_duration': 15, // Duración por defecto
        'difficulty_level': 'Fácil', // Dificultad por defecto
        'custom_name': suggestion['title'] as String,
        'custom_description': suggestion['description'] as String,
        'category_id': _getCategoryIdByName(suggestion['category'] as String),
      };

      await Supabase.instance.client.from('user_habits').insert(userHabitData);

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
      }
    } catch (e) {
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              // Guardar sugerencia rechazada antes de cerrar
              final currentSuggestion = await _getCurrentSuggestion();
              if (currentSuggestion != null) {
                await _saveRejectedSuggestion(
                  currentSuggestion['title'] as String,
                  currentSuggestion['category'] as String,
                );
              }

              // Cerrar las sugerencias
              setState(() {
                isSuggestionsExpanded = false;
                _hasUserInteracted = true;
              });
              _suggestionsAnimationController.reverse();
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
    );
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                                selectedCategoryId == null,
                                () {
                                  _onCategorySelected(null);
                                  Navigator.pop(context);
                                },
                              ),
                              ...state.categories.map(
                                (category) => _buildFilterOption(
                                  category.name,
                                  selectedCategoryId == category.id,
                                  () {
                                    _onCategorySelected(category.id);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
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

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'bedtime':
        return Icons.bedtime;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.category; // Default icon
    }
  }

  Color _getIconColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey; // Default color
    }
  }

  // ...
}
