import 'package:flutter/material.dart';
import 'package:vive_good_app/domain/entities/category.dart';

class AnimatedCategoryTabsWithLine extends StatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color lineColor;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color inactiveTextColor;
  final Function(String)? onProgrammaticCategoryChange;

  const AnimatedCategoryTabsWithLine({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.selectedColor = Colors.black,
    this.unselectedColor = const Color(0xFF6B7280),
    this.lineColor = Colors.black,
    this.primaryColor = const Color(0xFF219540),
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF111827),
    this.inactiveTextColor = const Color(0xFF6B7280),
    this.onProgrammaticCategoryChange,
  });

  @override
  State<AnimatedCategoryTabsWithLine> createState() =>
      _AnimatedCategoryTabsWithLineState();
}

class _AnimatedCategoryTabsWithLineState
    extends State<AnimatedCategoryTabsWithLine>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _lineAnimationController;
  late Animation<double> _lineAnimation;

  final List<GlobalKey> _tabKeys = [];
  final List<double> _tabOffsets = [];
  double _lineOffset = 0;
  double _lineWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize tab keys
    _tabKeys.addAll(
      List.generate(widget.categories.length, (index) => GlobalKey()),
    );
    _tabOffsets.addAll(List.generate(widget.categories.length, (index) => 0.0));

    // Calculate initial positions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTabPositions();
      _updateLinePosition(animate: false);
    });
  }

  @override
  void didUpdateWidget(AnimatedCategoryTabsWithLine oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update tab keys and offsets if categories changed
    if (oldWidget.categories.length != widget.categories.length) {
      _tabKeys.clear();
      _tabOffsets.clear();

      if (widget.categories.isNotEmpty) {
        _tabKeys.addAll(
          List.generate(widget.categories.length, (index) => GlobalKey()),
        );
        _tabOffsets.addAll(
          List.generate(widget.categories.length, (index) => 0.0),
        );
      }
    }

    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.categories.length != widget.categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.categories.isNotEmpty) {
          _calculateTabPositions();
          _updateLinePosition(animate: true);
          _scrollToSelectedTab();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _lineAnimationController.dispose();
    super.dispose();
  }



  void _calculateTabPositions() {
    if (widget.categories.isEmpty || _tabKeys.isEmpty) return;

    for (int i = 0; i < _tabKeys.length && i < widget.categories.length; i++) {
      final RenderBox? renderBox =
          _tabKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && i < _tabOffsets.length) {
        final position = renderBox.localToGlobal(Offset.zero);
        _tabOffsets[i] = position.dx;
      }
    }
  }

  void _updateLinePosition({required bool animate}) {
    final selectedIndex = widget.categories.indexWhere(
      (category) => category.id == widget.selectedCategoryId,
    );
    
    if (widget.categories.isEmpty ||
        selectedIndex < 0 ||
        selectedIndex >= _tabKeys.length ||
        selectedIndex >= widget.categories.length) {
      return;
    }

    final RenderBox? renderBox =
        _tabKeys[selectedIndex].currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      
      // Get the scroll offset to adjust the line position
      final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;

      setState(() {
        // Calculate the correct offset considering scroll position and padding
        _lineOffset = position.dx - 20 - scrollOffset;
        _lineWidth = size.width;
      });

      if (animate) {
        _lineAnimationController.forward(from: 0);
      }
    }
  }

  void _scrollToSelectedTab() {
    final selectedIndex = widget.categories.indexWhere(
      (category) => category.id == widget.selectedCategoryId,
    );
    
    if (widget.categories.isEmpty ||
        selectedIndex < 0 ||
        selectedIndex >= _tabOffsets.length ||
        selectedIndex >= widget.categories.length) {
      return;
    }

    // Position the selected tab to the left with some padding
    const leftPadding = 20.0;
    final targetOffset = _tabOffsets[selectedIndex] - leftPadding;

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onTabTap(String categoryId) {
    if (categoryId != widget.selectedCategoryId) {
      widget.onCategorySelected(categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty categories case
    if (widget.categories.isEmpty) {
      return Container(
        height: 60,
        color: Colors.transparent,
        child: const Center(
          child: Text(
            'No hay categorías disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 20),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: widget.categories.map((category) => _buildTab(category)).toList(),
        ),
      ),
    );
  }



  Widget _buildTab(Category category) {
    final isSelected = category.id == widget.selectedCategoryId;
    final index = widget.categories.indexOf(category);

    return GestureDetector(
      key: _tabKeys.length > index ? _tabKeys[index] : null,
      onTap: () => _onTabTap(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
          child: Text(category.name),
        ),
      ),
    );
  }
}

// Controller class for managing tab animations and state
class CategoryTabsController {
  final List<Category> categories;
  final ValueNotifier<String?> selectedCategoryNotifier;
  final ValueNotifier<bool> isAnimatingNotifier;

  late ScrollController scrollController;
  late AnimationController lineAnimationController;

  CategoryTabsController({required this.categories, String? initialSelectedId})
    : selectedCategoryNotifier = ValueNotifier(initialSelectedId),
      isAnimatingNotifier = ValueNotifier(false);

  void init(TickerProvider vsync) {
    scrollController = ScrollController();
    lineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
  }

  void dispose() {
    scrollController.dispose();
    lineAnimationController.dispose();
    selectedCategoryNotifier.dispose();
    isAnimatingNotifier.dispose();
  }

  void selectCategory(String categoryId) {
    if (selectedCategoryNotifier.value != categoryId) {
      selectedCategoryNotifier.value = categoryId;
      isAnimatingNotifier.value = true;

      lineAnimationController.forward(from: 0).then((_) {
        isAnimatingNotifier.value = false;
      });
    }
  }

  int get selectedIndex {
    return categories.indexWhere(
      (category) => category.id == selectedCategoryNotifier.value,
    );
  }
}
