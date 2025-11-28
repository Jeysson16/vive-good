import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../controllers/sliver_scroll_controller.dart';

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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: maxExtent,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          controller: tabController,
          isScrollable: true,
          physics: const BouncingScrollPhysics(),
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
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: (index) {
            // Animate tab change
            controller.animateToTab(index);

            // Notify category selection immediately to ensure highlight+scroll
            // even if TabController is in a transient state on mobile.
            String? selectedCategoryId;
            if (index == 0) {
              selectedCategoryId = null; // "Todos"
            } else {
              final categoryIndex = index - 1;
              if (categoryIndex >= 0 && categoryIndex < categories.length) {
                selectedCategoryId = categories[categoryIndex].id;
              }
            }
            controller.onCategoryChanged?.call(selectedCategoryId);
          },
          tabs: _buildTabs(),
        ),
      ),
    );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [const Tab(text: 'Todos')];

    // Add category tabs
    for (Category category in categories) {
      tabs.add(Tab(text: category.name));
    }

    // Ensure tabs count matches TabController length to prevent errors
    final expectedLength = tabController.length;
    if (tabs.length > expectedLength) {
      // Truncate tabs to match controller length
      tabs = tabs.take(expectedLength).toList();
    } else if (tabs.length < expectedLength) {
      // Pad with invisible placeholders to match controller length (transitional frames)
      final deficit = expectedLength - tabs.length;
      for (int i = 0; i < deficit; i++) {
        tabs.add(const Tab(text: ''));
      }
    }

    return tabs;
  }

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

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
