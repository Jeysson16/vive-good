import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/domain/usecases/get_habit_statistics_usecase.dart';
import 'habit_statistics_event.dart';
import 'habit_statistics_state.dart';

class HabitStatisticsBloc extends Bloc<HabitStatisticsEvent, HabitStatisticsState> {
  final GetHabitStatisticsUseCase getHabitStatisticsUseCase;

  HabitStatisticsBloc({required this.getHabitStatisticsUseCase})
      : super(HabitStatisticsInitial()) {
    on<LoadHabitStatistics>(_onLoadHabitStatistics);
    on<RefreshHabitStatistics>(_onRefreshHabitStatistics);
  }

  Future<void> _onLoadHabitStatistics(
    LoadHabitStatistics event,
    Emitter<HabitStatisticsState> emit,
  ) async {
    emit(HabitStatisticsLoading());

    try {
      // Agregar timeout para evitar spinners infinitos
      final result = await getHabitStatisticsUseCase(
        GetHabitStatisticsParams(
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
          emit(HabitStatisticsError(errorMessage));
        },
        (statistics) => emit(HabitStatisticsLoaded(statistics)),
      );
    } catch (e) {
      // Manejar errores de timeout y otros errores no capturados
      final errorMessage = _getErrorMessage(e.toString());
      emit(HabitStatisticsError(errorMessage));
    }
  }

  Future<void> _onRefreshHabitStatistics(
    RefreshHabitStatistics event,
    Emitter<HabitStatisticsState> emit,
  ) async {
    // Mantener los datos actuales mientras se refresca
    if (state is HabitStatisticsLoaded) {
      final currentStatistics = (state as HabitStatisticsLoaded).statistics;
      emit(HabitStatisticsRefreshing(currentStatistics));
    } else {
      emit(HabitStatisticsLoading());
    }

    try {
      // Agregar timeout para evitar spinners infinitos
      final result = await getHabitStatisticsUseCase(
        GetHabitStatisticsParams(
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
          emit(HabitStatisticsError(errorMessage));
        },
        (statistics) => emit(HabitStatisticsLoaded(statistics)),
      );
    } catch (e) {
      print('HabitStatisticsBloc: Error loading statistics - $e');
      final errorMessage = _getErrorMessage(e.toString());
      print('HabitStatisticsBloc: Emitting error message - $errorMessage');
      emit(HabitStatisticsError(errorMessage));
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
    return 'No se pudieron cargar las estadísticas. Intenta nuevamente.';
  }
}