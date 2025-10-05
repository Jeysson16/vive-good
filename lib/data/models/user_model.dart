import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends User {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String name;

  @HiveField(2)
  @override
  final String email;

  @HiveField(3)
  @override
  final bool isFirstTime;

  @HiveField(4)
  @override
  final bool hasCompletedOnboarding;

  @HiveField(5)
  final String firstName;

  @HiveField(6)
  final String lastName;

  @HiveField(7)
  final String? role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isFirstTime = true,
    this.hasCompletedOnboarding = false,
    this.firstName = '',
    this.lastName = '',
    this.role,
  }) : super(
         id: id,
         name: name,
         email: email,
         isFirstTime: isFirstTime,
         hasCompletedOnboarding: hasCompletedOnboarding,
       );

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      isFirstTime: user.isFirstTime,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isFirstTime: json['isFirstTime'] ?? true,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'],
    );
  }

  factory UserModel.fromSupabaseUser(supabase.User user, {Map<String, dynamic>? profile}) {
    final firstName = profile?['first_name'] ?? user.userMetadata?['first_name'] ?? '';
    final lastName = profile?['last_name'] ?? user.userMetadata?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    return UserModel(
      id: user.id,
      name: fullName.isNotEmpty ? fullName : user.email?.split('@').first ?? '',
      email: user.email ?? '',
      isFirstTime: true,
      hasCompletedOnboarding: false,
      firstName: firstName,
      lastName: lastName,
      role: profile?['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isFirstTime': isFirstTime,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }

  @override
  UserModel copyWith({
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
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      isFirstTime: isFirstTime,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }
}
