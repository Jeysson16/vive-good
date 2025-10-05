import 'package:equatable/equatable.dart';
import '../../../models/user_profile.dart';

/// Estados del BLoC de perfil
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Estado de carga
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Estado de perfil cargado exitosamente
class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Estado de error
class ProfileError extends ProfileState {
  final String message;
  final String? errorCode;

  const ProfileError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Estado de actualización en progreso
class ProfileUpdating extends ProfileState {
  final UserProfile currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Estado de perfil actualizado exitosamente
class ProfileUpdated extends ProfileState {
  final UserProfile profile;
  final String message;

  const ProfileUpdated(this.profile, this.message);

  @override
  List<Object?> get props => [profile, message];
}

/// Estado de imagen de perfil actualizándose
class ProfileImageUploading extends ProfileState {
  final UserProfile currentProfile;

  const ProfileImageUploading(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Estado de imagen de perfil actualizada
class ProfileImageUpdated extends ProfileState {
  final UserProfile profile;

  const ProfileImageUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Estado de exportación en progreso
class ProfileExporting extends ProfileState {
  final UserProfile currentProfile;

  const ProfileExporting(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Estado de exportación completada
class ProfileExported extends ProfileState {
  final UserProfile profile;
  final String filePath;

  const ProfileExported(this.profile, this.filePath);

  @override
  List<Object?> get props => [profile, filePath];
}

/// Estado de eliminación en progreso
class ProfileDeleting extends ProfileState {
  const ProfileDeleting();
}

/// Estado de perfil eliminado
class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}

/// Estado de configuraciones inteligentes actualizándose
class SmartSettingsUpdating extends ProfileState {
  final UserProfile currentProfile;

  const SmartSettingsUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Estado de configuraciones inteligentes actualizadas
class SmartSettingsUpdated extends ProfileState {
  final UserProfile profile;

  const SmartSettingsUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Estado de progreso de hábitos actualizándose
class HabitProgressUpdating extends ProfileState {
  final UserProfile currentProfile;

  const HabitProgressUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Estado de progreso de hábitos actualizado
class HabitProgressUpdated extends ProfileState {
  final UserProfile profile;

  const HabitProgressUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Estado de datos de salud actualizándose
class HealthDataUpdating extends ProfileState {
  final UserProfile currentProfile;

  const HealthDataUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// Estado de datos de salud actualizados
class HealthDataUpdated extends ProfileState {
  final UserProfile profile;

  const HealthDataUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}
