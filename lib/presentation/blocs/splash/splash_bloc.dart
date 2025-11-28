import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/user/get_current_user.dart';
import '../../../domain/usecases/user/has_completed_onboarding.dart';
import '../../../domain/usecases/user/is_first_time_user.dart';
import '../../../domain/usecases/user/save_user.dart';
import '../../../domain/usecases/admin/check_admin_permissions_usecase.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../auth/auth_state.dart' as app_auth;
import '../habit/habit_bloc.dart';
import '../dashboard/dashboard_bloc.dart';
import '../dashboard/dashboard_event.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final IsFirstTimeUser isFirstTimeUser;
  final HasCompletedOnboarding hasCompletedOnboarding;
  final GetCurrentUser getCurrentUser;
  final SaveUser saveUser;
  final CheckAdminPermissionsUseCase checkAdminPermissions;
  final HabitBloc? habitBloc;
  final DashboardBloc? dashboardBloc;
  final AuthBloc? authBloc;

  SplashBloc({
    required this.isFirstTimeUser,
    required this.hasCompletedOnboarding,
    required this.getCurrentUser,
    required this.saveUser,
    required this.checkAdminPermissions,
    this.habitBloc,
    this.dashboardBloc,
    this.authBloc,
  }) : super(SplashInitial()) {
    on<CheckAppStatus>(_onCheckAppStatus);
  }

  Future<void> _onCheckAppStatus(
    CheckAppStatus event,
    Emitter<SplashState> emit,
  ) async {
    try {
      print('🚀 [SPLASH] Iniciando verificación de estado de la app');
      
      // Check if user has an active session
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      
      print('🔐 [SPLASH] Session: ${session != null ? "EXISTE" : "NULL"}');
      print('👤 [SPLASH] User: ${user != null ? "EXISTE (${user.id})" : "NULL"}');

      if (session != null && user != null) {
        print('✅ [SPLASH] Usuario autenticado detectado, ejecutando _preloadDataAndNavigateToMain');
        // User is authenticated, preload data before navigating to main
        await _preloadDataAndNavigateToMain(emit);
      } else {
        print('🚫 [SPLASH] Usuario no autenticado, ejecutando _checkFirstTimeAndOnboarding');
        // User is not authenticated, check first time and onboarding
        await _checkFirstTimeAndOnboarding(emit);
      }
    } catch (e) {
      print('💥 [SPLASH] Error en _onCheckAppStatus: $e');
      // If there's an error, treat as not authenticated
      await _checkFirstTimeAndOnboarding(emit);
    }
  }

  Future<void> _preloadDataAndNavigateToMain(Emitter<SplashState> emit) async {
    print('🚀 [SPLASH] Iniciando _preloadDataAndNavigateToMain');
    emit(SplashLoading());

    try {
      // Simulate splash screen delay
      await Future.delayed(const Duration(seconds: 1));

      // First, check and load current user data in AuthBloc
      if (authBloc != null) {
        print('🔐 [SPLASH] AuthBloc disponible, verificando estado de autenticación');
        authBloc!.add(const AuthCheckRequested());

        // Wait for auth state to be updated
        await Future.delayed(const Duration(milliseconds: 800));

        // Preload habits data if user is authenticated
        final authState = authBloc!.state;
        print('🔐 [SPLASH] Estado de autenticación: ${authState.runtimeType}');
        
        if (authState is app_auth.AuthAuthenticated) {
          final userId = authState.user.id;
          print('👤 [SPLASH] Usuario autenticado con ID: $userId');

          // Check if user is admin before deciding navigation
          print('🔍 [SPLASH] Verificando permisos de administrador...');
          final adminResult = await checkAdminPermissions(
            CheckAdminPermissionsParams(userId: userId),
          );

          final isAdmin = adminResult.fold(
            (failure) {
              print('❌ [SPLASH] Error al verificar permisos de admin: $failure');
              return false;
            },
            (hasPermissions) {
              print('✅ [SPLASH] Resultado de verificación de admin: $hasPermissions');
              return hasPermissions;
            },
          );

          print('🎯 [SPLASH] ¿Es administrador? $isAdmin');

          if (isAdmin) {
            // User is admin, navigate to admin dashboard
            print('🔄 [SPLASH] Navegando a vista de administrador');
            emit(SplashNavigateToAdmin());
            return;
          }

          print('👥 [SPLASH] Usuario regular, cargando datos del dashboard');
          // User is not admin, preload dashboard data
          if (dashboardBloc != null) {
            // Preload dashboard data during splash screen
            dashboardBloc!.add(LoadDashboardData(
              userId: userId, 
              date: DateTime.now(),
            ));

            // Wait for dashboard data to load
            await Future.delayed(const Duration(milliseconds: 2000));
          }
        } else {
          print('🚫 [SPLASH] Usuario no autenticado');
        }
      } else {
        print('❌ [SPLASH] AuthBloc no disponible');
      }

      print('🏠 [SPLASH] Navegando a vista principal');
      emit(SplashNavigateToMain());
    } catch (e) {
      print('💥 [SPLASH] Error en _preloadDataAndNavigateToMain: $e');
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
