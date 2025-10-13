import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/domain/usecases/get_category_evolution_usecase.dart';
import 'category_evolution_event.dart';
import 'category_evolution_state.dart';

class CategoryEvolutionBloc extends Bloc<CategoryEvolutionEvent, CategoryEvolutionState> {
  final GetCategoryEvolutionUseCase getCategoryEvolutionUseCase;

  CategoryEvolutionBloc({required this.getCategoryEvolutionUseCase})
      : super(CategoryEvolutionInitial()) {
    on<LoadCategoryEvolution>(_onLoadCategoryEvolution);
    on<RefreshCategoryEvolution>(_onRefreshCategoryEvolution);
    on<SelectCategory>(_onSelectCategory);
  }

  Future<void> _onLoadCategoryEvolution(
    LoadCategoryEvolution event,
    Emitter<CategoryEvolutionState> emit,
  ) async {
    emit(CategoryEvolutionLoading());

    try {
      // Agregar timeout para evitar spinners infinitos
      final result = await getCategoryEvolutionUseCase(
        GetCategoryEvolutionParams(
          userId: event.userId,
          year: event.year,
          month: event.month,
        ),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout: La operación tardó demasiado'),
      );

      result.fold(
        (failure) {
          // Emitir error con mensaje más amigable
          final errorMessage = _getErrorMessage(failure.toString());
          emit(CategoryEvolutionError(errorMessage));
        },
        (evolution) => emit(CategoryEvolutionLoaded(evolution)),
      );
    } catch (e) {
      // Manejar errores de timeout y otros errores no capturados
      final errorMessage = _getErrorMessage(e.toString());
      emit(CategoryEvolutionError(errorMessage));
    }
  }

  Future<void> _onRefreshCategoryEvolution(
    RefreshCategoryEvolution event,
    Emitter<CategoryEvolutionState> emit,
  ) async {
    // Mantener los datos actuales y la selección mientras se refresca
    if (state is CategoryEvolutionLoaded) {
      final currentState = state as CategoryEvolutionLoaded;
      emit(CategoryEvolutionRefreshing(
        currentState.evolution,
        selectedCategoryId: currentState.selectedCategoryId,
      ));
    } else {
      emit(CategoryEvolutionLoading());
    }

    try {
      // Agregar timeout para evitar spinners infinitos
      final result = await getCategoryEvolutionUseCase(
        GetCategoryEvolutionParams(
          userId: event.userId,
          year: event.year,
          month: event.month,
        ),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout: La operación tardó demasiado'),
      );

      result.fold(
        (failure) {
          final errorMessage = _getErrorMessage(failure.toString());
          emit(CategoryEvolutionError(errorMessage));
        },
        (evolution) {
          // Mantener la categoría seleccionada si existe
          String? selectedCategoryId;
          if (state is CategoryEvolutionRefreshing) {
            selectedCategoryId = (state as CategoryEvolutionRefreshing).selectedCategoryId;
          }
          emit(CategoryEvolutionLoaded(evolution, selectedCategoryId: selectedCategoryId));
        },
      );
    } catch (e) {
      print('CategoryEvolutionBloc: Error loading evolution - $e');
      final errorMessage = _getErrorMessage(e.toString());
      print('CategoryEvolutionBloc: Emitting error message - $errorMessage');
      emit(CategoryEvolutionError(errorMessage));
    }
  }

  void _onSelectCategory(
    SelectCategory event,
    Emitter<CategoryEvolutionState> emit,
  ) {
    if (state is CategoryEvolutionLoaded) {
      final currentState = state as CategoryEvolutionLoaded;
      emit(currentState.copyWith(selectedCategoryId: event.categoryId));
    }
  }

  /// Convierte mensajes de error técnicos en mensajes amigables para el usuario
  String _getErrorMessage(String error) {
    if (error.contains('Timeout') || error.contains('timeout')) {
      return 'La operación tardó demasiado. Verifica tu conexión e intenta nuevamente.';
    }
    if (error.contains('PostgrestException') || error.contains('PGRST202')) {
      return 'Servicio temporalmente no disponible. Intenta nuevamente en unos momentos.';
    }
    if (error.contains('ServerException') || error.contains('server')) {
      return 'Error de conexión con el servidor. Verifica tu conexión a internet.';
    }
    if (error.contains('NetworkException') || error.contains('network')) {
      return 'Sin conexión a internet. Verifica tu conexión y vuelve a intentar.';
    }
    // Mensaje genérico para otros errores
    return 'No se pudo cargar la evolución de categorías. Intenta nuevamente.';
  }
}