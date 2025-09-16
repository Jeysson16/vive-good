import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/usecases/user/is_first_time_user.dart';
import '../../../domain/usecases/user/has_completed_onboarding.dart';
import '../../../domain/usecases/user/get_current_user.dart';
import '../../../domain/usecases/user/save_user.dart';
import '../../../core/usecases/usecase.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final IsFirstTimeUser isFirstTimeUser;
  final HasCompletedOnboarding hasCompletedOnboarding;
  final GetCurrentUser getCurrentUser;
  final SaveUser saveUser;

  SplashBloc({
    required this.isFirstTimeUser,
    required this.hasCompletedOnboarding,
    required this.getCurrentUser,
    required this.saveUser,
  }) : super(SplashInitial()) {
    on<CheckAppStatus>(_onCheckAppStatus);
  }

  Future<void> _onCheckAppStatus(
    CheckAppStatus event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());

    try {
      // Simular retraso de pantalla de splash
      await Future.delayed(const Duration(seconds: 2));

      // 1. Verificar si hay una sesión activa en Supabase
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      print('🔍 Verificando sesión: ${supabaseUser?.id}');
      
      if (supabaseUser != null) {
        print('✅ Sesión activa encontrada, navegando directamente al main');
        
        // Si hay sesión activa en Supabase, ir directo al main
        if (!emit.isDone) emit(SplashNavigateToMain());
        return;
      }
      
      print('ℹ️ No hay sesión activa, verificando estado de onboarding');
      await _checkFirstTimeAndOnboarding(emit);
      
    } catch (e) {
      print('❌ Error en verificación de estado: $e');
      emit(SplashError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
  
  Future<void> _checkFirstTimeAndOnboarding(Emitter<SplashState> emit) async {
    final isFirstTimeResult = await isFirstTimeUser.call(const NoParams());
    final hasCompletedOnboardingResult = await hasCompletedOnboarding.call(const NoParams());

    // Verificar si el emitter sigue activo antes de emitir
    if (emit.isDone) return;

    isFirstTimeResult.fold(
      (failure) {
        if (!emit.isDone) emit(SplashError(message: failure.message));
      },
      (isFirstTime) {
        hasCompletedOnboardingResult.fold(
          (failure) {
            if (!emit.isDone) emit(SplashError(message: failure.message));
          },
          (hasCompleted) {
            if (!emit.isDone) {
              if (isFirstTime || !hasCompleted) {
                emit(SplashNavigateToOnboarding());
              } else {
                emit(SplashNavigateToWelcome());
              }
            }
          },
        );
      },
    );
  }
}