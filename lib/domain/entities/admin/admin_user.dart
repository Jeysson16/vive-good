import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String roleName;
  final String roleId;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.roleName,
    required this.roleId,
    required this.createdAt,
    this.lastSignInAt,
    required this.isActive,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        roleName,
        roleId,
        createdAt,
        lastSignInAt,
        isActive,
        metadata,
      ];

  AdminUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? roleName,
    String? roleId,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roleName: roleName ?? this.roleName,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}