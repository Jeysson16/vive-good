import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/user.dart';

part 'local_user_model.g.dart';

@HiveType(typeId: 3)
class LocalUserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? email;

  @HiveField(2)
  final String? name;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final DateTime? birthDate;

  @HiveField(5)
  final String? gender;

  @HiveField(6)
  final String? timezone;

  @HiveField(7)
  final Map<String, dynamic>? preferences;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final bool isLocalOnly;

  @HiveField(11)
  final bool needsSync;

  @HiveField(12)
  final DateTime? lastSyncAt;

  @HiveField(13)
  final bool isActive;

  @HiveField(14)
  final DateTime? lastLoginAt;

  LocalUserModel({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.birthDate,
    this.gender,
    this.timezone,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.isLocalOnly = false,
    this.needsSync = false,
    this.lastSyncAt,
    this.isActive = true,
    this.lastLoginAt,
  });

  // Convertir desde entidad de dominio
  factory LocalUserModel.fromEntity(User user) {
    return LocalUserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      // Propiedades específicas del modelo local con valores por defecto
      birthDate: null,
      gender: null,
      timezone: null,
      preferences: null,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isActive: true,
      lastLoginAt: null,
    );
  }

  // Convertir a entidad de dominio
  User toEntity() {
    final safeName = name ?? '';
    final nameParts = safeName.split(' ');
    return User(
      id: id,
      name: safeName,
      email: email ?? '',
      isFirstTime: false, // Valor por defecto
      hasCompletedOnboarding: true, // Valor por defecto
      firstName: nameParts.isNotEmpty ? nameParts.first : '',
      lastName: nameParts.length > 1 ? nameParts.last : '',
      role: null,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Marcar como que necesita sincronización
  LocalUserModel markAsNeedsSync() {
    return LocalUserModel(
      id: id,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      birthDate: birthDate,
      gender: gender,
      timezone: timezone,
      preferences: preferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isLocalOnly: isLocalOnly,
      needsSync: true,
      lastSyncAt: lastSyncAt,
      isActive: isActive,
      lastLoginAt: lastLoginAt,
    );
  }

  // Marcar como sincronizado
  LocalUserModel markAsSynced() {
    return LocalUserModel(
      id: id,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      birthDate: birthDate,
      gender: gender,
      timezone: timezone,
      preferences: preferences,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocalOnly: false,
      needsSync: false,
      lastSyncAt: DateTime.now(),
      isActive: isActive,
      lastLoginAt: lastLoginAt,
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'timezone': timezone,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }
}