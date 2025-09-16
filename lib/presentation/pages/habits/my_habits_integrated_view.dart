import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/habit/habit_state.dart';
import '../../blocs/category_scroll/category_scroll_bloc.dart';
import '../../blocs/category_scroll/category_scroll_event.dart';
import '../../blocs/category_scroll/category_scroll_state.dart';
import '../../widgets/habits/animated_category_tabs.dart';
import '../../widgets/habits/synchronized_habits_list.dart';
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
  String selectedSuggestionCategory = 'Alimentación';
  late AnimationController _suggestionsAnimationController;
  late Animation<double> _suggestionsAnimation;
  late PageController _pageController;
  int _currentSuggestionIndex = 0;

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
    _pageController = PageController();
    // Inicializar la animación en estado contraído por defecto
    _suggestionsAnimationController.value = 0.0;
    isSuggestionsExpanded = false;
    _loadData();
  }

  @override
  void dispose() {
    _suggestionsAnimationController.dispose();
    _pageController.dispose();
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
        print(
          '🔄 DEBUG: Enviando evento LoadHabitSuggestions para userId: $supabaseUserId',
        );
        final currentHabitState = context.read<HabitBloc>().state;
        final String? categoryId = currentHabitState is HabitLoaded
            ? currentHabitState.selectedCategoryId
            : null;

        context.read<HabitBloc>().add(
          LoadHabitSuggestions(userId: supabaseUserId, categoryId: categoryId),
        );
        print('🔄 DEBUG: Evento LoadHabitSuggestions enviado correctamente');
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryScrollBloc()..add(InitializeCategoryScroll()),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
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
                              )
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                        // Category tabs
                        _buildSuggestionCategoryTabs(),
                        const SizedBox(height: 16),
                        // Debug: Print suggestions count
                        Builder(
                          builder: (context) {
                            print(
                              '🔍 UI DEBUG: habitSuggestions.length = ${state.habitSuggestions.length}',
                            );
                            state.habitSuggestions.forEach((suggestion) {
                              print('  - UI: ${suggestion.name}');
                            });
                            return const SizedBox.shrink();
                          },
                        ),
                        // Texto introductorio
                        const Text(
                          'Podrías beneficiarte de este hábito:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Sugerencia destacada única
                        _buildFeaturedSuggestion(),
                        
                        const SizedBox(height: 16),
                        
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
              AnimatedCategoryTabs(
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
            onPressed: () => _addHabitFromSuggestion(_habitToSuggestionMap(habit)),
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
      MaterialPageRoute(
        builder: (context) => const NewHabitScreen(),
      ),
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
    // Múltiples sugerencias por categoría
    final suggestions = {
      'Alimentación': [
        {
          'title': 'Beber 8 vasos de agua',
          'description': 'Mantente hidratado todo el día',
          'icon': Icons.local_drink,
          'color': const Color(0xFF10B981),
        },
        {
          'title': 'Comer 5 frutas y verduras',
          'description': 'Nutrición balanceada diaria',
          'icon': Icons.eco,
          'color': const Color(0xFF10B981),
        },
        {
          'title': 'Evitar comida procesada',
          'description': 'Alimentación más natural',
          'icon': Icons.no_food,
          'color': const Color(0xFF10B981),
        },
      ],
      'Actividad física': [
        {
          'title': 'Caminar 30 minutos',
          'description': 'Ejercicio cardiovascular básico',
          'icon': Icons.directions_walk,
          'color': const Color(0xFF3B82F6),
        },
        {
          'title': 'Hacer 20 flexiones',
          'description': 'Fortalece el tren superior',
          'icon': Icons.fitness_center,
          'color': const Color(0xFF3B82F6),
        },
        {
          'title': 'Estirar 10 minutos',
          'description': 'Mejora la flexibilidad',
          'icon': Icons.self_improvement,
          'color': const Color(0xFF3B82F6),
        },
      ],
      'Sueño': [
        {
          'title': 'Dormir 8 horas',
          'description': 'Descanso reparador para tu salud',
          'icon': Icons.bedtime,
          'color': const Color(0xFF8B5CF6),
        },
        {
          'title': 'Acostarse antes de las 11 PM',
          'description': 'Rutina de sueño saludable',
          'icon': Icons.schedule,
          'color': const Color(0xFF8B5CF6),
        },
        {
          'title': 'Evitar pantallas 1 hora antes',
          'description': 'Mejor calidad de sueño',
          'icon': Icons.phone_android,
          'color': const Color(0xFF8B5CF6),
        },
      ],
    };
    
    final currentSuggestions = suggestions[selectedSuggestionCategory] ?? suggestions['Alimentación']!;
    
    return Container(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentSuggestionIndex = index;
          });
        },
        itemCount: currentSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = currentSuggestions[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDAF5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (suggestion['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    suggestion['icon'] as IconData,
                    color: suggestion['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        suggestion['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion['description'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDotIndicators() {
    // Obtener el número de sugerencias para la categoría actual
    final suggestions = {
      'Alimentación': 3,
      'Actividad física': 3,
      'Sueño': 3,
    };
    
    final currentSuggestionsCount = suggestions[selectedSuggestionCategory] ?? 3;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(currentSuggestionsCount, (index) {
        final isActive = _currentSuggestionIndex == index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF219540) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
  
  Map<String, dynamic>? _getCurrentSuggestion() {
    final suggestions = {
      'Alimentación': [
        {
          'title': 'Beber 8 vasos de agua al día',
          'description': 'Mantente hidratado',
          'icon': Icons.local_drink,
          'color': const Color(0xFF3B82F6),
          'category': 'Alimentación',
        },
        {
          'title': 'Comer 5 porciones de frutas y verduras',
          'description': 'Nutrición balanceada',
          'icon': Icons.eco,
          'color': const Color(0xFF10B981),
          'category': 'Alimentación',
        },
        {
          'title': 'Evitar comida procesada',
          'description': 'Alimentación natural',
          'icon': Icons.no_food,
          'color': const Color(0xFFEF4444),
          'category': 'Alimentación',
        },
      ],
      'Actividad física': [
        {
          'title': 'Caminar 30 minutos diarios',
          'description': 'Ejercicio cardiovascular',
          'icon': Icons.directions_walk,
          'color': const Color(0xFFF59E0B),
          'category': 'Actividad física',
        },
        {
          'title': 'Hacer ejercicios de estiramiento',
          'description': 'Flexibilidad y movilidad',
          'icon': Icons.self_improvement,
          'color': const Color(0xFF8B5CF6),
          'category': 'Actividad física',
        },
        {
          'title': 'Subir escaleras en lugar del ascensor',
          'description': 'Actividad física diaria',
          'icon': Icons.stairs,
          'color': const Color(0xFF06B6D4),
          'category': 'Actividad física',
        },
      ],
      'Sueño': [
        {
          'title': 'Dormir 8 horas diarias',
          'description': 'Descanso reparador',
          'icon': Icons.bedtime,
          'color': const Color(0xFF6366F1),
          'category': 'Sueño',
        },
        {
          'title': 'Evitar pantallas antes de dormir',
          'description': 'Higiene del sueño',
          'icon': Icons.phone_android,
          'color': const Color(0xFFEC4899),
          'category': 'Sueño',
        },
        {
          'title': 'Mantener horario regular de sueño',
          'description': 'Mejor calidad de sueño',
          'icon': Icons.schedule,
          'color': const Color(0xFF8B5CF6),
          'category': 'Sueño',
        },
      ],
    };
    
    final currentSuggestions = suggestions[selectedSuggestionCategory];
    if (currentSuggestions != null && _currentSuggestionIndex < currentSuggestions.length) {
      return currentSuggestions[_currentSuggestionIndex];
    }
    return null;
  }

  void _navigateToNewHabit({bool prefillData = false}) {
    final currentSuggestion = _getCurrentSuggestion();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewHabitScreen(
          prefilledHabitName: prefillData && currentSuggestion != null ? currentSuggestion['title'] as String : null,
          prefilledDescription: prefillData && currentSuggestion != null ? currentSuggestion['description'] as String : null,
          prefilledCategoryId: prefillData && currentSuggestion != null ? _getCategoryIdByName(currentSuggestion['category'] as String) : null,
        ),
      ),
    ).then((_) {
      // Recargar datos cuando regrese de la pantalla de nuevo hábito
      _loadData();
    });
  }

  String? _getCategoryIdByName(String categoryName) {
    // Mapeo básico de nombres de categoría a IDs
    // En una implementación real, esto debería venir de la base de datos
    switch (categoryName) {
      case 'Alimentación':
        return '1'; // ID de la categoría Alimentación
      case 'Actividad física':
        return '2'; // ID de la categoría Actividad física
      case 'Sueño':
        return '3'; // ID de la categoría Sueño
      default:
        return null;
    }
  }

  Map<String, dynamic> _habitToSuggestionMap(Habit habit) {
    return {
      'title': habit.name,
      'description': habit.description ?? '',
      'category': 'General', // Default category since Habit entity doesn't have category name
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
        'is_public': false, // Los hábitos desde sugerencias son privados por defecto
        'estimated_duration': 15, // Duración por defecto
        'difficulty_level': 'Fácil', // Dificultad por defecto
        'custom_name': suggestion['title'] as String,
        'custom_description': suggestion['description'] as String,
        'category_id': _getCategoryIdByName(suggestion['category'] as String),
      };

      await Supabase.instance.client
          .from('user_habits')
          .insert(userHabitData);

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
            onPressed: () {
              // Lógica de rechazar - simplemente cerrar las sugerencias
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
            onPressed: () {
              // Navegar a nueva pantalla de hábito con datos prellenados
              _navigateToNewHabit(prefillData: true);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF219540)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Modificar',
              style: TextStyle(
                color: Color(0xFF219540),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Agregar hábito directamente con los datos de la sugerencia
              final currentSuggestion = _getCurrentSuggestion();
              if (currentSuggestion != null) {
                _addHabitFromSuggestion(currentSuggestion);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF219540),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Aceptar',
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

  Widget _buildSuggestionCategoryTabs() {
    final categories = ['Alimentación', 'Actividad física', 'Sueño'];
    
    return Container(
      height: 40,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedSuggestionCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedSuggestionCategory = category;
                  _currentSuggestionIndex = 0;
                });
                // Resetear el PageController a la primera página
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected 
                          ? const Color(0xFF219540) 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected 
                          ? const Color(0xFF219540) 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
