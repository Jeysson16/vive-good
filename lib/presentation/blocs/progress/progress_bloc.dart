import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/cache/monthly_data_cache.dart';
import '../../../domain/usecases/get_user_progress.dart';
import '../../../domain/usecases/get_daily_week_progress.dart';
import '../../../domain/usecases/get_user_streak.dart';
import '../../../domain/usecases/get_monthly_progress.dart';
import '../../../domain/usecases/get_monthly_indicators.dart';
import 'progress_event.dart';
import 'progress_state.dart';
import '../../../domain/entities/progress.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final GetUserProgress getUserProgress;
  final GetDailyWeekProgress getDailyWeekProgress;
  final GetUserStreak getUserStreak;
  final GetMonthlyProgress getMonthlyProgress;
  final GetMonthlyIndicators getMonthlyIndicators;

  ProgressBloc({
    required this.getUserProgress,
    required this.getDailyWeekProgress,
    required this.getUserStreak,
    required this.getMonthlyProgress,
    required this.getMonthlyIndicators,
  }) : super(ProgressInitial()) {
    on<LoadUserProgress>(_onLoadUserProgress);
    on<RefreshUserProgress>(_onRefreshUserProgress);
    on<UpdateUserProgress>(_onUpdateUserProgress);
    on<LoadDailyWeekProgress>(_onLoadDailyWeekProgress);
    on<LoadUserStreak>(_onLoadUserStreak);
    on<LoadMonthlyProgress>(_onLoadMonthlyProgress);
    on<LoadMonthlyProgressForDate>(_onLoadMonthlyProgressForDate);
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
    final monthlySeriesResult = await getMonthlyProgress(
      GetMonthlyProgressParams(userId: event.userId),
    );
    final now = DateTime.now();
    final monthlyIndicatorsResult = await getMonthlyIndicators(
      GetMonthlyIndicatorsParams(
        userId: event.userId,
        year: now.year,
        month: now.month,
      ),
    );

    // Debug logs
    print('🔍 ProgressBloc: Loading user progress for userId: ${event.userId}');
    print('🔍 ProgressBloc: Monthly indicators result: ${monthlyIndicatorsResult.isRight() ? 'SUCCESS' : 'FAILURE'}');
    
    progressResult.fold(
      (failure) => emit(ProgressError(message: _mapFailureToMessage(failure))),
      (progress) {
        Map<String, double>? daily;
        int? streak;
        List<Progress>? monthlyProgressList;
        Map<String, String>? monthlyIndicatorsMap;

        dailyProgressResult.fold((_) => daily = null, (d) => daily = d);
        streakResult.fold((_) => streak = null, (s) => streak = s);
        monthlySeriesResult.fold(
          (_) => monthlyProgressList = null,
          (list) => monthlyProgressList = list,
        );
        monthlyIndicatorsResult.fold(
          (failure) {
            print('❌ ProgressBloc: Monthly indicators failed: $failure');
            monthlyIndicatorsMap = null;
          },
          (m) {
            monthlyIndicatorsMap = m;
            print('✅ ProgressBloc: Monthly indicators loaded: ${m.keys.length} indicators');
            print('🔍 ProgressBloc: Monthly indicators keys: ${m.keys.toList()}');
            print('🔍 ProgressBloc: Sample values: ${m.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ')}');
          },
        );

        emit(
          ProgressLoaded(
            progress: progress,
            dailyProgress: daily,
            userStreak: streak,
            monthlyProgress: monthlyProgressList,
            monthlyIndicators: monthlyIndicatorsMap,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshUserProgress(
    RefreshUserProgress event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is ProgressLoaded) {
      final currentState = state as ProgressLoaded;
      emit(ProgressRefreshing(
        progress: currentState.progress,
        dailyProgress: currentState.dailyProgress,
        userStreak: currentState.userStreak,
        monthlyProgress: currentState.monthlyProgress,
        monthlyIndicators: currentState.monthlyIndicators,
      ));
    } else {
      emit(ProgressLoading());
    }

    // Load all data including streak when refreshing
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
        Map<String, double>? daily;
        int? streak;

        dailyProgressResult.fold((_) => daily = null, (d) => daily = d);
        streakResult.fold((_) => streak = null, (s) => streak = s);

        emit(
          ProgressLoaded(
            progress: progress,
            dailyProgress: daily,
            userStreak: streak,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMonthlyProgress(
    LoadMonthlyProgress event,
    Emitter<ProgressState> emit,
  ) async {
    // Solo actualiza campos mensuales si ya tenemos progreso cargado
    final current = state;
    if (current is ProgressLoaded) {
      final now = DateTime.now();
      final cache = MonthlyDataCache.instance;
      
      // Try to get cached data first
      List<Progress>? cachedProgress = await cache.getCachedProgress(
        event.userId, now.year, now.month);
      Map<String, String>? cachedIndicators = await cache.getCachedIndicators(
        event.userId, now.year, now.month);
      
      // If we have valid cache, use it immediately
      if (cachedProgress != null && cachedIndicators != null) {
        emit(
          ProgressLoaded(
            progress: current.progress,
            dailyProgress: current.dailyProgress,
            userStreak: current.userStreak,
            monthlyProgress: cachedProgress,
            monthlyIndicators: cachedIndicators,
          ),
        );
        return;
      }
      
      // If no cache, load from network and cache the results
      final results = await Future.wait([
        getMonthlyProgress(GetMonthlyProgressParams(userId: event.userId)),
        getMonthlyIndicators(GetMonthlyIndicatorsParams(
          userId: event.userId,
          year: now.year,
          month: now.month,
        )),
      ]);
      
      List<Progress>? monthlyProgressList;
      Map<String, String>? monthlyIndicatorsMap;
      
      results[0].fold(
        (_) => monthlyProgressList = current.monthlyProgress,
        (list) {
          monthlyProgressList = list as List<Progress>;
          // Cache the progress data
          cache.cacheProgress(event.userId, now.year, now.month, monthlyProgressList ?? []);
        },
      );
      
      results[1].fold(
        (_) => monthlyIndicatorsMap = current.monthlyIndicators,
        (m) {
          monthlyIndicatorsMap = m as Map<String, String>;
          // Cache the indicators data
          if (monthlyIndicatorsMap?.isNotEmpty == true) {
            cache.cacheIndicators(event.userId, now.year, now.month, monthlyIndicatorsMap!);
          }
        },
      );

      emit(
        ProgressLoaded(
          progress: current.progress,
          dailyProgress: current.dailyProgress,
          userStreak: current.userStreak,
          monthlyProgress: monthlyProgressList,
          monthlyIndicators: monthlyIndicatorsMap,
        ),
      );
    }
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
        (failure) =>
            emit(ProgressError(message: _mapFailureToMessage(failure))),
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
        (failure) =>
            emit(ProgressError(message: _mapFailureToMessage(failure))),
        (dailyProgress) => emit(
          ProgressLoaded(
            progress: currentState.progress,
            dailyProgress: dailyProgress,
          ),
        ),
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
        (failure) =>
            emit(ProgressError(message: _mapFailureToMessage(failure))),
        (streak) => emit(
          ProgressLoaded(
            progress: currentState.progress,
            dailyProgress: currentState.dailyProgress,
            userStreak: streak,
          ),
        ),
      );
    }
  }

  Future<void> _onLoadMonthlyProgressForDate(
    LoadMonthlyProgressForDate event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is! ProgressLoaded) return;
    
    final current = state as ProgressLoaded;
    
    print('🔍 ProgressBloc: Loading monthly progress for ${event.year}/${event.month}');
    
    // Load data for specific month
    final results = await Future.wait([
      getMonthlyProgress(GetMonthlyProgressParams(userId: event.userId)),
      getMonthlyIndicators(GetMonthlyIndicatorsParams(
        userId: event.userId,
        year: event.year,
        month: event.month,
      )),
    ]);
    
    List<Progress>? monthlyProgressList;
    Map<String, String>? monthlyIndicatorsMap;
    
    results[0].fold(
      (_) => monthlyProgressList = current.monthlyProgress,
      (list) => monthlyProgressList = list as List<Progress>,
    );
    
    results[1].fold(
      (failure) {
        print('❌ ProgressBloc: Monthly indicators failed for ${event.year}/${event.month}: $failure');
        monthlyIndicatorsMap = current.monthlyIndicators;
      },
      (m) {
        monthlyIndicatorsMap = m as Map<String, String>;
        print('✅ ProgressBloc: Monthly indicators loaded for ${event.year}/${event.month}: ${m.keys.length} indicators');
      },
    );

    emit(
      ProgressLoaded(
        progress: current.progress,
        dailyProgress: current.dailyProgress,
        userStreak: current.userStreak,
        monthlyProgress: monthlyProgressList,
        monthlyIndicators: monthlyIndicatorsMap,
      ),
    );
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
