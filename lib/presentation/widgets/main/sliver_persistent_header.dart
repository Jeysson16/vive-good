import 'package:flutter/material.dart';
import '../../controllers/sliver_scroll_controller.dart';
import '../../../domain/entities/category.dart';

class SliverPersistentHeaderWidget extends SliverPersistentHeaderDelegate {
  final SliverScrollController controller;
  final List<Category> categories;
  final TabController tabController;
  
  SliverPersistentHeaderWidget({
    required this.controller,
    required this.categories,
    required this.tabController,
  });
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate opacity based on scroll position for smooth transitions
    final opacity = (1.0 - (shrinkOffset / maxExtent)).clamp(0.0, 1.0);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      height: 80,
      decoration: BoxDecoration(
        color: Color.lerp(
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          shrinkOffset / maxExtent,
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: shrinkOffset > 0 ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF4CAF50),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF4CAF50),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: _buildTabs(),
      ),
    );
  }
  
  List<Widget> _buildTabs() {
    List<Widget> tabs = [
      const Tab(text: 'Todos'),
    ];
    
    // Add category tabs
    for (Category category in categories) {
      tabs.add(Tab(text: category.name));
    }
    
    return tabs;
  }
  
  @override
  double get maxExtent => 80;
  
  @override
  double get minExtent => 80;
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is! SliverPersistentHeaderWidget) return true;
    return oldDelegate.categories.length != categories.length ||
           oldDelegate.tabController != tabController;
  }
  
  // Removed configurations that are not available in current Flutter version
  // FloatingHeaderSnapConfiguration, OverScrollHeaderStretchConfiguration,
  // and PersistentHeaderShowOnScreenConfiguration are not supported
}