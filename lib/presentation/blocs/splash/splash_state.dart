part of 'splash_bloc.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashNavigateToOnboarding extends SplashState {}

class SplashNavigateToWelcome extends SplashState {}

class SplashNavigateToMain extends SplashState {}

class SplashError extends SplashState {
  final String message;

  const SplashError({required this.message});

  @override
  List<Object> get props => [message];
}