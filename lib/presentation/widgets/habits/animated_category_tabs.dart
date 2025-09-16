import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category.dart' as entities;
import '../../blocs/category_scroll/category_scroll_bloc.dart';
import '../../blocs/category_scroll/category_scroll_event.dart';
import '../../blocs/category_scroll/category_scroll_state.dart';

class AnimatedCategoryTabs extends StatefulWidget {
  final List<entities.Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const AnimatedCategoryTabs({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<AnimatedCategoryTabs> createState() => _AnimatedCategoryTabsState();
}

class _AnimatedCategoryTabsState extends State<AnimatedCategoryTabs>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late Map<String, AnimationController> _bounceControllers;
  late Map<String, Animation<double>> _bounceAnimations;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeBounceAnimations();
    
    // Inicializar el BLoC
    context.read<CategoryScrollBloc>().add(InitializeCategoryScroll());
  }

  void _initializeBounceAnimations() {
    _bounceControllers = {};
    _bounceAnimations = {};
    
    // Crear animaciones para "Todos"
    _createBounceAnimation('all');
    
    // Crear animaciones para cada categoría
    for (final category in widget.categories) {
      _createBounceAnimation(category.id);
    }
  }

  void _createBounceAnimation(String categoryId) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
    
    _bounceControllers[categoryId] = controller;
    _bounceAnimations[categoryId] = animation;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _bounceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToCategory(int index) {
    if (_scrollController.hasClients) {
      final itemWidth = 120.0; // Ancho aproximado de cada tab
      final targetOffset = (index * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _triggerBounce(String categoryId, bool bounceLeft) {
    final controller = _bounceControllers[categoryId];
    if (controller != null) {
      controller.reset();
      controller.forward();
      
      // Notificar al BLoC sobre el rebote
      context.read<CategoryScrollBloc>().add(
        TriggerCategoryBounce(
          categoryId: categoryId,
          bounceLeft: bounceLeft,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryScrollBloc, CategoryScrollState>(
      listener: (context, state) {
        if (state is CategoryScrollAnimating) {
          _scrollToCategory(state.targetCategoryIndex);
        }
        
        if (state is CategoryScrollLoaded) {
          // Activar animaciones de rebote según el estado
          for (final entry in state.categoryBounceStates.entries) {
            if (entry.value) {
              final controller = _bounceControllers[entry.key];
              if (controller != null && !controller.isAnimating) {
                controller.reset();
                controller.forward();
              }
            }
          }
        }
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 20),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: widget.categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAnimatedCategoryTab(
                'Todos',
                'all',
                widget.selectedCategoryId == null,
                index,
              );
            }
            
            final category = widget.categories[index - 1];
            return _buildAnimatedCategoryTab(
              category.name,
              category.id,
              widget.selectedCategoryId == category.id,
              index,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedCategoryTab(
    String title,
    String categoryId,
    bool isSelected,
    int index,
  ) {
    final animation = _bounceAnimations[categoryId];
    
    return AnimatedBuilder(
      animation: animation ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final bounceValue = animation?.value ?? 0.0;
        final bounceOffset = Offset(
          (bounceValue * 10 * (index % 2 == 0 ? 1 : -1)), // Alternar dirección
          0,
        );
        
        return Transform.translate(
          offset: bounceOffset,
          child: AnimatedScale(
            scale: isSelected ? 1.05 : (1.0 + (bounceValue * 0.1)),
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () {
                widget.onCategorySelected(categoryId == 'all' ? null : categoryId);
                _triggerBounce(categoryId, index % 2 == 0);
                
                // Notificar al BLoC sobre el scroll
                context.read<CategoryScrollBloc>().add(
                  ScrollToCategory(
                    categoryId: categoryId == 'all' ? null : categoryId,
                    categoryIndex: index,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF219540) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF219540) : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF219540).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                  child: Text(title),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
