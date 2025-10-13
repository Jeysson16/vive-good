import 'package:equatable/equatable.dart';
import 'package:vive_good_app/domain/entities/category_evolution.dart';

abstract class CategoryEvolutionState extends Equatable {
  const CategoryEvolutionState();

  @override
  List<Object> get props => [];
}

class CategoryEvolutionInitial extends CategoryEvolutionState {}

class CategoryEvolutionLoading extends CategoryEvolutionState {}

class CategoryEvolutionLoaded extends CategoryEvolutionState {
  final List<CategoryEvolution> evolution;
  final String? selectedCategoryId;

  const CategoryEvolutionLoaded(
    this.evolution, {
    this.selectedCategoryId,
  });

  @override
  List<Object> get props => [evolution, selectedCategoryId ?? ''];

  CategoryEvolutionLoaded copyWith({
    List<CategoryEvolution>? evolution,
    String? selectedCategoryId,
  }) {
    return CategoryEvolutionLoaded(
      evolution ?? this.evolution,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class CategoryEvolutionError extends CategoryEvolutionState {
  final String message;

  const CategoryEvolutionError(this.message);

  @override
  List<Object> get props => [message];
}

class CategoryEvolutionRefreshing extends CategoryEvolutionState {
  final List<CategoryEvolution> currentEvolution;
  final String? selectedCategoryId;

  const CategoryEvolutionRefreshing(
    this.currentEvolution, {
    this.selectedCategoryId,
  });

  @override
  List<Object> get props => [currentEvolution, selectedCategoryId ?? ''];
}