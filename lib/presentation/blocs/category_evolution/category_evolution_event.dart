import 'package:equatable/equatable.dart';

abstract class CategoryEvolutionEvent extends Equatable {
  const CategoryEvolutionEvent();

  @override
  List<Object> get props => [];
}

class LoadCategoryEvolution extends CategoryEvolutionEvent {
  final String userId;
  final int year;
  final int month;

  const LoadCategoryEvolution({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [userId, year, month];
}

class RefreshCategoryEvolution extends CategoryEvolutionEvent {
  final String userId;
  final int year;
  final int month;

  const RefreshCategoryEvolution({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [userId, year, month];
}

class SelectCategory extends CategoryEvolutionEvent {
  final String? categoryId;

  const SelectCategory(this.categoryId);

  @override
  List<Object> get props => [categoryId ?? ''];
}