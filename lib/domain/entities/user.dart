import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final bool isFirstTime;
  final bool hasCompletedOnboarding;
  final String firstName;
  final String lastName;
  final String? role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isFirstTime = true,
    this.hasCompletedOnboarding = false,
    this.firstName = '',
    this.lastName = '',
    this.role,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isFirstTime,
    bool? hasCompletedOnboarding,
    String? firstName,
    String? lastName,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        isFirstTime,
        hasCompletedOnboarding,
        firstName,
        lastName,
        role,
      ];
}