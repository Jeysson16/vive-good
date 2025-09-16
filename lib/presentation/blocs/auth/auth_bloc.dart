import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth/sign_in_usecase.dart';
import '../../../domain/usecases/auth/sign_up_usecase.dart';
import '../../../domain/usecases/auth/sign_out_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final AuthRepository authRepository;
  
  late StreamSubscription _authStateSubscription;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthUserChanged>(_onUserChanged);

    // Escuchar cambios en el estado de autenticación
    _authStateSubscription = authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await signInUseCase(SignInParams(
      email: event.email,
      password: event.password,
    ));
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResult) {
        if (authResult.isSuccess && authResult.user != null) {
          emit(AuthAuthenticated(user: authResult.user!));
        } else {
          emit(AuthError(message: authResult.message ?? 'Error de autenticación'));
        }
      },
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await signUpUseCase(SignUpParams(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    ));
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResult) {
        if (authResult.isSuccess) {
          emit(const AuthSignUpSuccess(
            message: 'Cuenta creada exitosamente. Revisa tu email para confirmar tu cuenta.',
          ));
        } else {
          emit(AuthError(message: authResult.message ?? 'Error al crear la cuenta'));
        }
      },
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await signOutUseCase(NoParams());
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCurrentUserUseCase(NoParams());
    
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await resetPasswordUseCase(ResetPasswordParams(
      email: event.email,
    ));
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthPasswordResetSent(
        message: 'Se ha enviado un enlace de recuperación a tu email.',
      )),
    );
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}