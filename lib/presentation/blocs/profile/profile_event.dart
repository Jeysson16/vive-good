import 'package:equatable/equatable.dart';
import '../../../models/user_profile.dart';

/// Eventos del BLoC de perfil
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar el perfil del usuario
class LoadUserProfile extends ProfileEvent {
  const LoadUserProfile();
}

/// Actualizar el perfil del usuario
class UpdateUserProfile extends ProfileEvent {
  final UserProfile profile;

  const UpdateUserProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Actualizar configuraciones inteligentes
class UpdateSmartSettings extends ProfileEvent {
  final bool? autoSuggestionsEnabled;
  final String? morningReminderTime;
  final String? eveningReminderTime;

  const UpdateSmartSettings({
    this.autoSuggestionsEnabled,
    this.morningReminderTime,
    this.eveningReminderTime,
  });

  @override
  List<Object?> get props => [
    autoSuggestionsEnabled,
    morningReminderTime,
    eveningReminderTime,
  ];
}

/// Actualizar imagen de perfil
class UpdateProfileImage extends ProfileEvent {
  final String imagePath;

  const UpdateProfileImage(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

/// Actualizar URL de la foto de perfil
class UpdateProfilePictureEvent extends ProfileEvent {
  final String profilePictureUrl;

  const UpdateProfilePictureEvent({required this.profilePictureUrl});

  @override
  List<Object?> get props => [profilePictureUrl];
}

/// Exportar historial del usuario
class ExportUserHistory extends ProfileEvent {
  const ExportUserHistory();
}

/// Eliminar perfil del usuario
class DeleteUserProfile extends ProfileEvent {
  const DeleteUserProfile();
}

/// Actualizar progreso de hábitos
class UpdateHabitProgress extends ProfileEvent {
  final int? hydrationProgress;
  final int? sleepProgress;
  final int? activityProgress;

  const UpdateHabitProgress({
    this.hydrationProgress,
    this.sleepProgress,
    this.activityProgress,
  });

  @override
  List<Object?> get props => [
    hydrationProgress,
    sleepProgress,
    activityProgress,
  ];
}

/// Actualizar datos de salud
class UpdateHealthData extends ProfileEvent {
  final double? height;
  final double? weight;
  final List<String>? riskFactors;

  const UpdateHealthData({this.height, this.weight, this.riskFactors});

  @override
  List<Object?> get props => [height, weight, riskFactors];
}
