import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_user_progress.dart';
import '../../../domain/usecases/get_daily_week_progress.dart';
import '../../../domain/usecases/get_user_streak.dart';
import 'progress_event.dart';
import 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final GetUserProgress getUserProgress;
  final GetDailyWeekProgress getDailyWeekProgress;
  final GetUserStreak getUserStreak;

  ProgressBloc({
    required this.getUserProgress,
    required this.getDailyWeekProgress,
    required this.getUserStreak,
  }) : super(ProgressInitial()) {
    on<LoadUserProgress>(_onLoadUserProgress);
    on<RefreshUserProgress>(_onRefreshUserProgress);
    on<UpdateUserProgress>(_onUpdateUserProgress);
    on<LoadDailyWeekProgress>(_onLoadDailyWeekProgress);
    on<LoadUserStreak>(_onLoadUserStreak);
  }

  Future<void> _onLoadUserProgress(
    LoadUserProgress event,
    Emitter<ProgressState> emit,
  ) async {
    emit(ProgressLoading());
    
    final progressResult = await getUserProgress(
      GetUserProgressParams(userId: event.userId),
    );
    
    final dailyProgressResult = await getDailyWeekProgress(
      GetDailyWeekProgressParams(userId: event.userId),
    );
    
    final streakResult = await getUserStreak(
      GetUserStreakParams(userId: event.userId),
    );
    
    progressResult.fold(
      (failure) => emit(ProgressError(message: _mapFailureToMessage(failure))),
      (progress) {
        dailyProgressResult.fold(
          (failure) => emit(ProgressLoaded(progress: progress)),
          (dailyProgress) {
            streakResult.fold(
              (failure) => emit(ProgressLoaded(progress: progress, dailyProgress: dailyProgress)),
              (streak) => emit(ProgressLoaded(progress: progress, dailyProgress: dailyProgress, userStreak: streak)),
            );
          },
        );
      },
    );
  }

  Future<void> _onRefreshUserProgress(
    RefreshUserProgress event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is ProgressLoaded) {
      final currentProgress = (state as ProgressLoaded).progress;
      emit(ProgressRefreshing(progress: currentProgress));
    } else {
      emit(ProgressLoading());
    }
    
    final result = await getUserProgress(
      GetUserProgressParams(userId: event.userId),
    );
    
    result.fold(
      (failure) => emit(ProgressError(message: _mapFailureToMessage(failure))),
      (progress) => emit(ProgressLoaded(progress: progress)),
    );
  }

  Future<void> _onUpdateUserProgress(
    UpdateUserProgress event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is ProgressLoaded) {
      final currentProgress = (state as ProgressLoaded).progress;
      emit(ProgressRefreshing(progress: currentProgress));
      
      final result = await getUserProgress(
        GetUserProgressParams(userId: event.userId),
      );
      
      result.fold(
        (failure) => emit(ProgressError(message: _mapFailureToMessage(failure))),
        (progress) => emit(ProgressLoaded(progress: progress)),
      );
    }
  }

  Future<void> _onLoadDailyWeekProgress(
    LoadDailyWeekProgress event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is ProgressLoaded) {
      final currentState = state as ProgressLoaded;
      
      final dailyProgressResult = await getDailyWeekProgress(
        GetDailyWeekProgressParams(userId: event.userId),
      );
      
      dailyProgressResult.fold(
        (failure) => emit(ProgressError(message: _mapFailureToMessage(failure))),
        (dailyProgress) => emit(ProgressLoaded(
          progress: currentState.progress,
          dailyProgress: dailyProgress,
        )),
      );
    }
  }

  Future<void> _onLoadUserStreak(
    LoadUserStreak event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is ProgressLoaded) {
      final currentState = state as ProgressLoaded;
      
      final streakResult = await getUserStreak(
        GetUserStreakParams(userId: event.userId),
      );
      
      streakResult.fold(
        (failure) => emit(ProgressError(message: _mapFailureToMessage(failure))),
        (streak) => emit(ProgressLoaded(
          progress: currentState.progress,
          dailyProgress: currentState.dailyProgress,
          userStreak: streak,
        )),
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'No se pudieron cargar tus datos de progreso. Verifica tu conexión a internet e inténtalo nuevamente.';
      case CacheFailure:
        return 'Problema al acceder a los datos guardados. Reinicia la aplicación e inténtalo de nuevo.';
      case NetworkFailure:
        return 'Sin conexión a internet. Verifica tu conexión y vuelve a intentar.';
      default:
        return 'Algo salió mal al cargar tu progreso. Por favor, inténtalo de nuevo en unos momentos.';
    }
  }
}