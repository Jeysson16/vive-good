part of 'welcome_bloc.dart';

abstract class WelcomeState extends Equatable {
  const WelcomeState();

  @override
  List<Object?> get props => [];
}

class WelcomeInitial extends WelcomeState {}

class WelcomeLoading extends WelcomeState {}

class WelcomeLoaded extends WelcomeState {
  final User? user;

  const WelcomeLoaded({this.user});

  @override
  List<Object?> get props => [user];
}

class WelcomeSessionStarted extends WelcomeState {}

class WelcomeUserRegistered extends WelcomeState {
  final User user;

  const WelcomeUserRegistered({required this.user});

  @override
  List<Object> get props => [user];
}

class WelcomeError extends WelcomeState {
  final String message;

  const WelcomeError({required this.message});

  @override
  List<Object> get props => [message];
}