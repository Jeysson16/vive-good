part of 'welcome_bloc.dart';

abstract class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object> get props => [];
}

class LoadWelcomeData extends WelcomeEvent {
  const LoadWelcomeData();
}

class StartSession extends WelcomeEvent {
  const StartSession();
}

class RegisterUser extends WelcomeEvent {
  final String name;
  final String email;

  const RegisterUser({
    required this.name,
    required this.email,
  });

  @override
  List<Object> get props => [name, email];
}