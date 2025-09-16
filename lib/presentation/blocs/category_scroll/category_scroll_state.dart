import 'package:equatable/equatable.dart';

abstract class CategoryScrollState extends Equatable {
  const CategoryScrollState();

  @override
  List<Object?> get props => [];
}

class CategoryScrollInitial extends CategoryScrollState {}

class CategoryScrollLoaded extends CategoryScrollState {
  final String? activeCategoryId;
  final int activeCategoryIndex;
  final double scrollOffset;
  final Map<String, bool> categoryBounceStates;
  final List<String> categoryIds;

  const CategoryScrollLoaded({
    this.activeCategoryId,
    required this.activeCategoryIndex,
    required this.scrollOffset,
    required this.categoryBounceStates,
    required this.categoryIds,
  });

  @override
  List<Object?> get props => [
        activeCategoryId,
        activeCategoryIndex,
        scrollOffset,
        categoryBounceStates,
        categoryIds,
      ];

  CategoryScrollLoaded copyWith({
    String? activeCategoryId,
    int? activeCategoryIndex,
    double? scrollOffset,
    Map<String, bool>? categoryBounceStates,
    List<String>? categoryIds,
  }) {
    return CategoryScrollLoaded(
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      activeCategoryIndex: activeCategoryIndex ?? this.activeCategoryIndex,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      categoryBounceStates: categoryBounceStates ?? this.categoryBounceStates,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}

class CategoryScrollAnimating extends CategoryScrollState {
  final String targetCategoryId;
  final int targetCategoryIndex;

  const CategoryScrollAnimating({
    required this.targetCategoryId,
    required this.targetCategoryIndex,
  });

  @override
  List<Object?> get props => [targetCategoryId, targetCategoryIndex];
}