import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/habit/habit_bloc.dart';
import '../blocs/habit/habit_event.dart';
import '../blocs/habit/habit_state.dart';
import '../../domain/entities/category.dart';

class SliverScrollController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TabController tabController;
  final BuildContext context;

  bool _isScrolling = false;
  bool _isTabScrolling = false;
  bool _isHeaderAnimating = false;
  int _currentTabIndex = 0;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  Function(String?)? onCategoryChanged;
  double _lastScrollOffset = 0.0;
  bool _isScrollingUp = false;

  bool get isScrolling => _isScrolling;
  bool get isTabScrolling => _isTabScrolling;
  bool get isHeaderAnimating => _isHeaderAnimating;
  int get currentTabIndex => _currentTabIndex;
  List<Category> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isScrollingUp => _isScrollingUp;

  SliverScrollController({
    required this.tabController,
    required this.context,
    this.onCategoryChanged,
  }) {
    _initializeController();
  }

  void _initializeController() {
    scrollController.addListener(_onScrollChanged);
    tabController.addListener(_onTabChanged);
  }

  void _onScrollChanged() {
    if (scrollController.hasClients) {
      final currentOffset = scrollController.offset;
      _isScrolling = scrollController.position.isScrollingNotifier.value;

      // Detectar dirección del scroll
      _isScrollingUp = currentOffset < _lastScrollOffset;
      _lastScrollOffset = currentOffset;

      // Detectar si el header está en animación (zona crítica entre 0 y 200 pixels)
      const headerAnimationZone = 200.0;
      final wasHeaderAnimating = _isHeaderAnimating;
      _isHeaderAnimating =
          currentOffset > 0 &&
          currentOffset < headerAnimationZone &&
          _isScrolling;

      // Solo notificar si hay cambios significativos para evitar rebuilds innecesarios
      if (wasHeaderAnimating != _isHeaderAnimating ||
          (_isHeaderAnimating && (currentOffset % 10 == 0))) {
        notifyListeners();
      }
    }
  }

  void _onTabChanged() {
    // Evitar cambios de tab durante animaciones del header para prevenir bugs visuales
    if (!_isTabScrolling &&
        !_isHeaderAnimating &&
        tabController.indexIsChanging) {
      _currentTabIndex = tabController.index;
      _onCategorySelected(_currentTabIndex);
      notifyListeners();
    }
  }

  void updateCategories(List<Category> categories) {
    try {
      _categories = categories;

      // Validate current tab index after category update
      final totalTabs = categories.length + 1; // +1 for "Todos" tab
      if (_currentTabIndex >= totalTabs) {
        _currentTabIndex = 0; // Reset to first tab if current index is invalid
        _selectedCategoryId = null; // Reset selected category
      }

      notifyListeners();
    } catch (e) {
    }
  }

  void _onCategorySelected(int index) {
    // Validate TabController state and index range to prevent errors
    if (tabController.length == 0) {
      return;
    }

    final totalTabs = _categories.length + 1; // +1 for "Todos" tab
    if (index < 0 || index >= totalTabs || tabController.length == 0) {
      return;
    }

    if (index == 0) {
      // "Todos" tab - show all habits
      _selectedCategoryId = null;
    } else {
      // Specific category tab
      final categoryIndex = index - 1;
      if (categoryIndex >= 0 && categoryIndex < _categories.length) {
        _selectedCategoryId = _categories[categoryIndex].id;
      } else {
        return;
      }
    }

    // Notify category change through callback with scroll to first option
    onCategoryChanged?.call(_selectedCategoryId);

    // If a specific category is selected (not "Todos"), trigger scroll to first habit
    if (_selectedCategoryId != null) {
      // This will be handled by the parent widget to trigger scroll animation
    }
  }

  void animateToTab(int index) {
    if (tabController.length == 0) {
      return;
    }

    final totalTabs = _categories.length + 1; // +1 for "Todos" tab
    if (index < 0 || index >= totalTabs) {
      return;
    }

    // Prevent tab change during header animation
    if (_isHeaderAnimating) {
      return;
    }

    // Clamp target index to available TabController range to avoid transient mismatches
    final maxIndex = tabController.length - 1;
    final targetIndex = index.clamp(0, maxIndex);
    tabController.animateTo(targetIndex);
  }

  /// Sincroniza el índice del TabBar según el scroll (sin disparar selección de categoría)
  void syncTabWithScroll(int index) {
    final totalTabs = _categories.length + 1;
    if (index < 0 || index >= totalTabs) return;
    if (tabController.length != totalTabs) return;
    // Evitar bucles con el listener de tabs
    _isTabScrolling = true;
    try {
      tabController.index = index;
      _currentTabIndex = index;
    } finally {
      // Liberar la bandera en el siguiente microtask
      Future.microtask(() => _isTabScrolling = false);
    }
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void smoothScrollTo(double offset) {
    if (scrollController.hasClients && !_isHeaderAnimating) {
      _isScrolling = true;
      scrollController
          .animateTo(
            offset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          )
          .then((_) {
            // Pequeño delay para asegurar que la animación termine completamente
            Future.delayed(const Duration(milliseconds: 100), () {
              _isScrolling = false;
              notifyListeners();
            });
          });
    }
  }

  void scrollToFirstHabitOfCategory(String categoryId) {
    print('🔍 [DEBUG] scrollToFirstHabitOfCategory called for category: $categoryId');
    
    // Trigger the DashboardBloc to handle the scroll and highlight animation
    // This will be picked up by the HabitList widget which will handle both scroll and highlight
    if (context.mounted) {
      // The HabitList will detect the selectedCategoryId change and trigger its own scroll + highlight
      // No need to manually scroll here as HabitList handles it better with proper positioning
      print('🔍 [DEBUG] Category selection will be handled by HabitList');
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollChanged);
    tabController.removeListener(_onTabChanged);
    scrollController.dispose();
    super.dispose();
  }
}
