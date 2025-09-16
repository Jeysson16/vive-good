import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/user/get_current_user.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/user/save_user.dart';
import '../../../domain/usecases/user/set_first_time_user.dart';
import '../../../domain/usecases/user/set_onboarding_completed.dart';

part 'welcome_event.dart';
part 'welcome_state.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  final GetCurrentUser getCurrentUser;
  final SaveUser saveUser;
  final SetFirstTimeUser setFirstTimeUser;
  final SetOnboardingCompleted setOnboardingCompleted;

  WelcomeBloc({
    required this.getCurrentUser,
    required this.saveUser,
    required this.setFirstTimeUser,
    required this.setOnboardingCompleted,
  }) : super(WelcomeInitial()) {
    on<LoadWelcomeData>(_onLoadWelcomeData);
    on<StartSession>(_onStartSession);
    on<RegisterUser>(_onRegisterUser);
  }

  Future<void> _onLoadWelcomeData(
    LoadWelcomeData event,
    Emitter<WelcomeState> emit,
  ) async {
    emit(WelcomeLoading());

    try {
      final userResult = await getCurrentUser.call(NoParams());
      
      userResult.fold(
        (failure) => emit(WelcomeError(message: failure.message)),
        (user) {
          if (user != null) {
            emit(WelcomeLoaded(user: user));
          } else {
            emit(WelcomeLoaded(user: null));
          }
        },
      );
    } catch (e) {
      emit(WelcomeError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onStartSession(
    StartSession event,
    Emitter<WelcomeState> emit,
  ) async {
    try {
      // Mark as not first time user and onboarding completed
      final firstTimeResult = await setFirstTimeUser.call(false);
      final onboardingResult = await setOnboardingCompleted.call(true);
      
      firstTimeResult.fold(
        (failure) => emit(WelcomeError(message: failure.message)),
        (_) {
          onboardingResult.fold(
            (failure) => emit(WelcomeError(message: failure.message)),
            (_) => emit(WelcomeSessionStarted()),
          );
        },
      );
    } catch (e) {
      emit(WelcomeError(message: 'Failed to start session: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterUser(
    RegisterUser event,
    Emitter<WelcomeState> emit,
  ) async {
    emit(WelcomeLoading());

    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        email: event.email,
        isFirstTime: false,
        hasCompletedOnboarding: true,
      );

      final saveResult = await saveUser.call(user);
      
      saveResult.fold(
        (failure) => emit(WelcomeError(message: failure.message)),
        (_) async {
          // Mark as not first time user and onboarding completed
          final firstTimeResult = await setFirstTimeUser.call(false);
          final onboardingResult = await setOnboardingCompleted.call(true);
          
          firstTimeResult.fold(
            (failure) => emit(WelcomeError(message: failure.message)),
            (_) {
              onboardingResult.fold(
                (failure) => emit(WelcomeError(message: failure.message)),
                (_) => emit(WelcomeUserRegistered(user: user)),
              );
            },
          );
        },
      );
    } catch (e) {
      emit(WelcomeError(message: 'Failed to register user: ${e.toString()}'));
    }
  }
}