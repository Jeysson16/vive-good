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
  int _currentTabIndex = 0;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  Function(String?)? onCategoryChanged;

  bool get isScrolling => _isScrolling;
  bool get isTabScrolling => _isTabScrolling;
  int get currentTabIndex => _currentTabIndex;
  List<Category> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;

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
      _isScrolling = scrollController.position.isScrollingNotifier.value;
      notifyListeners();
    }
  }

  void _onTabChanged() {
    if (!_isTabScrolling && tabController.indexIsChanging) {
      _currentTabIndex = tabController.index;
      _onCategorySelected(_currentTabIndex);
      notifyListeners();
    }
  }

  void updateCategories(List<Category> categories) {
    _categories = categories;
    notifyListeners();
  }

  void _onCategorySelected(int index) {
    if (index == 0) {
      // "Todos" tab - show all habits
      _selectedCategoryId = null;
    } else if (index - 1 < _categories.length) {
      // Specific category tab
      _selectedCategoryId = _categories[index - 1].id;
    }

    // Notify category change through callback
    onCategoryChanged?.call(_selectedCategoryId);
  }

  void animateToTab(int index) {
    _isTabScrolling = true;
    tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    // Reset scrolling flag after animation duration
    Future.delayed(const Duration(milliseconds: 250), () {
      _isTabScrolling = false;
    });
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
    if (scrollController.hasClients) {
      scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
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
