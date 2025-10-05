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
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isFirstTime = true,
    this.hasCompletedOnboarding = false,
    this.firstName = '',
    this.lastName = '',
    this.role,
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
       updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isFirstTime,
    bool? hasCompletedOnboarding,
    String? firstName,
    String? lastName,
    String? role,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

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
        avatarUrl,
        createdAt,
        updatedAt,
      ];
}