import 'package:equatable/equatable.dart';

abstract class CategoryScrollEvent extends Equatable {
  const CategoryScrollEvent();

  @override
  List<Object?> get props => [];
}

class ScrollToCategory extends CategoryScrollEvent {
  final String? categoryId;
  final int categoryIndex;
  final bool animate;

  const ScrollToCategory({
    required this.categoryId,
    required this.categoryIndex,
    this.animate = true,
  });

  @override
  List<Object?> get props => [categoryId, categoryIndex, animate];
}

class UpdateScrollPosition extends CategoryScrollEvent {
  final double scrollOffset;
  final String? visibleCategoryId;

  const UpdateScrollPosition({
    required this.scrollOffset,
    this.visibleCategoryId,
  });

  @override
  List<Object?> get props => [scrollOffset, visibleCategoryId];
}

class TriggerCategoryBounce extends CategoryScrollEvent {
  final String categoryId;
  final bool bounceLeft;

  const TriggerCategoryBounce({
    required this.categoryId,
    required this.bounceLeft,
  });

  @override
  List<Object?> get props => [categoryId, bounceLeft];
}

class InitializeCategoryScroll extends CategoryScrollEvent {
  const InitializeCategoryScroll();

  @override
  List<Object?> get props => [];
}