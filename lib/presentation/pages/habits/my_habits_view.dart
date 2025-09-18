import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_state.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/animated_habit_card.dart';
import '../../widgets/animated_loading_widget.dart';
import '../../widgets/animated_error_widget.dart';
import '../../widgets/animated_mic_button.dart';
import '../../../data/models/user_habit.dart';
import '../../../domain/entities/category.dart';

class MyHabitsView extends StatefulWidget {
  const MyHabitsView({Key? key}) : super(key: key);

  @override
  State<MyHabitsView> createState() => _MyHabitsViewState();
}

class _MyHabitsViewState extends State<MyHabitsView>
    with TickerProviderStateMixin {
  String? selectedCategoryId;
  String searchQuery = '';
  late AnimationController _listAnimationController;
  late AnimationController _categoryAnimationController;
  late Animation<double> _listAnimation;
  late Animation<double> _categoryAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHabits();
  }

  void _initializeAnimations() {
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _listAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _categoryAnimation = CurvedAnimation(
      parent: _categoryAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _loadHabits() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<HabitBloc>().add(LoadUserHabits(userId: authState.user.id));
      context.read<HabitBloc>().add(LoadCategories());
    } else {
      // Usuario no autenticado, manejar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
    }
  }

  void _onHabitToggle(String userHabitId, bool isCompleted) {
    if (isCompleted) {
      context.read<HabitBloc>().add(ToggleHabitCompletion(
        date: DateTime.now(),
        habitId: userHabitId,
        isCompleted: isCompleted,
      ));
    } else {
      // Handle uncomplete logic if needed
    }
  }

  void _onCategorySelected(String? categoryId) {
    _categoryAnimationController.reset();
    _categoryAnimationController.forward();
    setState(() {
      selectedCategoryId = categoryId;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _categoryAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Header section with enhanced styling
          _buildHeader(),
          
          // Search bar with improved design
          _buildSearchBar(),
          
          // Category tabs with animations
          _buildCategoryTabs(),
          
          // Habits list with enhanced cards
          Expanded(
            child: _buildHabitsList(),
          ),
          
          // Add habit button
          _buildAddHabitButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FAFC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ).createShader(bounds),
                child: Text(
                  'Mis Hábitos',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pequeñas acciones que fortalecen tu salud',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1D4ED8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFAFAFA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar hábitos...',
          hintStyle: TextStyle(
            color: const Color(0xFF6B7280).withOpacity(0.7),
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              color: const Color(0xFF6B7280).withOpacity(0.8),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 16,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        if (state is HabitLoaded) {
          return AnimatedBuilder(
            animation: _categoryAnimation,
            builder: (context, child) {
              return Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _onCategorySelected(null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedCategoryId == null
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF1D4ED8),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFF8FAFC),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: selectedCategoryId == null
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE5E7EB).withOpacity(0.5),
                                width: selectedCategoryId == null ? 2 : 1,
                              ),
                              boxShadow: selectedCategoryId == null
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: selectedCategoryId == null ? Colors.white : const Color(0xFF6B7280),
                                fontWeight: selectedCategoryId == null ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                              child: const Text('Todos'),
                            ),
                          ),
                        ),
                      );
                    }
                    final category = state.categories[index - 1];
                    final isSelected = selectedCategoryId == category.id;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _onCategorySelected(category.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF1D4ED8),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFF8FAFC),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFE5E7EB).withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                            child: Text(category.name),
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
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoryTab(String name, String? categoryId, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategorySelected(categoryId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF1F2937),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          child: Text(name),
        ),
      ),
    );
  }

  Widget _buildHabitsList() {
    return BlocListener<HabitBloc, HabitState>(
      listener: (context, state) {
        if (state is HabitLoaded) {
          _listAnimationController.forward();
        }
      },
      child: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          if (state is HabitLoading) {
          return const AnimatedStateWidget(
            state: 'loading',
            loadingWidget: AnimatedLoadingWidget(
              key: ValueKey('habit_loading'),
              message: 'Cargando hábitos...',
            ),
          );
          } else if (state is HabitError) {
            return AnimatedStateWidget(
              state: 'error',
              errorWidget: AnimatedErrorWidget(
                key: const ValueKey('habit_error'),
                message: 'Error al cargar hábitos: ${state.message}',
                onRetry: () => _loadHabits(),
              ),
            );
        } else if (state is HabitLoaded) {
          final filteredHabits = state.userHabits.where((habit) {
            final matchesCategory = selectedCategoryId == null ||
                true; // TODO: Implement category filtering with proper habit data
            final matchesSearch = searchQuery.isEmpty ||
                (habit.habitId != null && habit.habitId!.toLowerCase().contains(searchQuery.toLowerCase()));
            return matchesCategory && matchesSearch;
          }).toList();

          if (filteredHabits.isEmpty) {
            return _buildEmptyState();
          }

          return AnimatedBuilder(
            animation: _listAnimation,
            builder: (context, child) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filteredHabits.length,
                // Optimizaciones de performance
                cacheExtent: 200.0, // Pre-carga elementos cercanos
                addAutomaticKeepAlives: false, // Reduce uso de memoria
                addRepaintBoundaries: false, // Reduce overhead de repaint
                physics: const BouncingScrollPhysics(), // Animación nativa más fluida
                itemBuilder: (context, index) {
                  final userHabit = filteredHabits[index];
                  return RepaintBoundary(
                    key: ValueKey('habit_${userHabit.id}'),
                    child: AnimatedHabitCard(
                      userHabit: userHabit,
                      index: index,
                      animation: _listAnimation,
                      onToggle: (isCompleted) => _onHabitToggle(userHabit.id, isCompleted),
                      onEdit: () => _navigateToEditHabit(userHabit.habitId ?? ''),
                    ),
                  );
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const _EmptyStateWidget();
  }

  Widget _buildAddHabitButton() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF1D4ED8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToAddHabit,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Agregar nuevo hábito',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  void _navigateToAddHabit() {
    // Navigate to add habit page
    Navigator.pushNamed(context, '/add-habit');
  }

  void _navigateToEditHabit(String habitId) {
    // Navigate to edit habit page
    Navigator.pushNamed(context, '/edit-habit', arguments: habitId);
  }

  Widget _buildHabitItem(UserHabit userHabit) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToEditHabit(userHabit.id),
                  borderRadius: BorderRadius.circular(12),
                  splashColor: const Color(0xFF4CAF50).withOpacity(0.1),
                  highlightColor: const Color(0xFF4CAF50).withOpacity(0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, iconAnimValue, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * iconAnimValue),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.track_changes,
                                  color: Color(0xFF4CAF50),
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hábito ${userHabit.habitId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Frecuencia: ${userHabit.frequency}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              if (userHabit.scheduledTime != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Hora: ${userHabit.scheduledTime}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, checkAnimValue, child) {
                            return Transform.scale(
                              scale: 0.7 + (0.3 * checkAnimValue),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onHabitToggle(userHabit.id, true),
                                  borderRadius: BorderRadius.circular(8),
                                  splashColor: const Color(0xFF4CAF50).withOpacity(0.3),
                                  highlightColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget const optimizado para mejor performance
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Color(0xFF6B7280),
          ),
          SizedBox(height: 16),
          Text(
            'No tienes hábitos aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega tu primer hábito para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}