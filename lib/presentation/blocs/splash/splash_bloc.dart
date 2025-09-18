import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/usecases/user/is_first_time_user.dart';
import '../../../domain/usecases/user/has_completed_onboarding.dart';
import '../../../domain/usecases/user/get_current_user.dart';
import '../../../domain/usecases/user/save_user.dart';
import '../../../core/usecases/usecase.dart';
import '../habit/habit_bloc.dart';
import '../habit/habit_event.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart' as app_auth;

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final IsFirstTimeUser isFirstTimeUser;
  final HasCompletedOnboarding hasCompletedOnboarding;
  final GetCurrentUser getCurrentUser;
  final SaveUser saveUser;
  final HabitBloc? habitBloc;
  final AuthBloc? authBloc;

  SplashBloc({
    required this.isFirstTimeUser,
    required this.hasCompletedOnboarding,
    required this.getCurrentUser,
    required this.saveUser,
    this.habitBloc,
    this.authBloc,
  }) : super(SplashInitial()) {
    on<CheckAppStatus>(_onCheckAppStatus);
  }

  Future<void> _onCheckAppStatus(
    CheckAppStatus event,
    Emitter<SplashState> emit,
  ) async {
    try {
      // Check if user has an active session
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        // User is authenticated, preload data before navigating to main
        await _preloadDataAndNavigateToMain(emit);
      } else {
        // User is not authenticated, check first time and onboarding
        await _checkFirstTimeAndOnboarding(emit);
      }
    } catch (e) {
      // If there's an error, treat as not authenticated
      await _checkFirstTimeAndOnboarding(emit);
    }
  }
  
  Future<void> _preloadDataAndNavigateToMain(Emitter<SplashState> emit) async {
    emit(SplashLoading());
    
    try {
      // Simulate splash screen delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Preload habits data if blocs are available
      if (habitBloc != null && authBloc != null) {
        final authState = authBloc!.state;
        if (authState is app_auth.AuthAuthenticated) {
          final userId = authState.user.id;
          
          // Load habits and categories
          habitBloc!.add(LoadDashboardHabits(userId: userId, date: DateTime.now()));
          habitBloc!.add(LoadCategories());
          
          // Wait a bit for data to load
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      emit(SplashNavigateToMain());
    } catch (e) {
      // If preloading fails, still navigate to main
      emit(SplashNavigateToMain());
    }
  }

  Future<void> _checkFirstTimeAndOnboarding(Emitter<SplashState> emit) async {
    try {
      final isFirstTime = await isFirstTimeUser(NoParams());
      
      if (isFirstTime.isRight()) {
        final isFirst = isFirstTime.getOrElse(() => false);
        
        if (isFirst) {
          emit(SplashNavigateToOnboarding());
        } else {
          final hasOnboarded = await hasCompletedOnboarding(NoParams());
          
          if (hasOnboarded.isRight()) {
            final completed = hasOnboarded.getOrElse(() => false);
            
            if (completed) {
              emit(SplashNavigateToWelcome());
            } else {
              emit(SplashNavigateToOnboarding());
            }
          } else {
            emit(SplashNavigateToOnboarding());
          }
        }
      } else {
        emit(SplashNavigateToOnboarding());
      }
    } catch (e) {
      emit(SplashError(message: 'Error checking app status: ${e.toString()}'));
    }
  }
}