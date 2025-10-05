import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC para manejar el estado del perfil del usuario
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final SupabaseClient _supabaseClient;

  ProfileBloc({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient,
      super(const ProfileInitial()) {
    // Registrar manejadores de eventos
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<UpdateSmartSettings>(_onUpdateSmartSettings);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<UpdateProfilePictureEvent>(_onUpdateProfilePictureEvent);
    on<ExportUserHistory>(_onExportUserHistory);
    on<DeleteUserProfile>(_onDeleteUserProfile);
    on<UpdateHabitProgress>(_onUpdateHabitProgress);
    on<UpdateHealthData>(_onUpdateHealthData);
  }

  /// Cargar el perfil del usuario actual
  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(const ProfileLoading());

      // Obtener el usuario actual
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        emit(const ProfileError('Usuario no autenticado'));
        return;
      }

      // Cargar el perfil desde Supabase
      final profile = await ProfileService.getProfileById(user.id);

      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        // Si no existe perfil, crear uno básico
        final newProfile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          firstName: user.userMetadata?['first_name'] ?? '',
          lastName: user.userMetadata?['last_name'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdProfile = await ProfileService.createProfile(
          firstName: newProfile.firstName,
          lastName: newProfile.lastName,
          email: newProfile.email,
          age: newProfile.age,
          institution: newProfile.institution,
          phone: newProfile.phone,
          heightCm: newProfile.heightCm,
          weightKg: newProfile.weightKg,
          riskFactors: newProfile.riskFactors,
        );
        emit(ProfileLoaded(createdProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al cargar el perfil: ${e.toString()}'));
    }
  }

  /// Actualizar el perfil del usuario
  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(ProfileUpdating(currentProfile));

        final updatedProfile = await ProfileService.updateProfile(
          event.profile,
        );
        emit(ProfileUpdated(updatedProfile, 'Perfil actualizado exitosamente'));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(seconds: 1));
        emit(ProfileLoaded(updatedProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al actualizar el perfil: ${e.toString()}'));
    }
  }

  /// Actualizar configuraciones inteligentes
  Future<void> _onUpdateSmartSettings(
    UpdateSmartSettings event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(SmartSettingsUpdating(currentProfile));

        // Crear perfil actualizado con nuevas configuraciones
        final updatedProfile = currentProfile.copyWith(
          autoSuggestionsEnabled:
              event.autoSuggestionsEnabled ??
              currentProfile.autoSuggestionsEnabled,
          morningReminderTime:
              event.morningReminderTime ?? currentProfile.morningReminderTime,
          eveningReminderTime:
              event.eveningReminderTime ?? currentProfile.eveningReminderTime,
          updatedAt: DateTime.now(),
        );

        final savedProfile = await ProfileService.updateProfile(updatedProfile);
        emit(SmartSettingsUpdated(savedProfile));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        emit(ProfileLoaded(savedProfile));
      }
    } catch (e) {
      emit(
        ProfileError('Error al actualizar configuraciones: ${e.toString()}'),
      );
    }
  }

  /// Actualizar imagen de perfil
  Future<void> _onUpdateProfileImage(
    UpdateProfileImage event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(ProfileImageUploading(currentProfile));

        // Subir imagen y obtener URL
        final savedProfile = await ProfileService.uploadProfileImage(
          event.imagePath,
        );
        emit(ProfileImageUpdated(savedProfile));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        emit(ProfileLoaded(savedProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al actualizar imagen: ${e.toString()}'));
    }
  }

  /// Exportar historial del usuario
  Future<void> _onExportUserHistory(
    ExportUserHistory event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(ProfileExporting(currentProfile));

        final filePath = await ProfileService.exportUserHistory(
          currentProfile.id,
        );
        emit(ProfileExported(currentProfile, filePath));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(seconds: 2));
        emit(ProfileLoaded(currentProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al exportar historial: ${e.toString()}'));
    }
  }

  /// Eliminar perfil del usuario
  Future<void> _onDeleteUserProfile(
    DeleteUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(const ProfileDeleting());

        await ProfileService.deleteUserProfile(currentProfile.id);
        emit(const ProfileDeleted());
      }
    } catch (e) {
      emit(ProfileError('Error al eliminar perfil: ${e.toString()}'));
    }
  }

  /// Actualizar progreso de hábitos
  Future<void> _onUpdateHabitProgress(
    UpdateHabitProgress event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(HabitProgressUpdating(currentProfile));

        // Crear perfil actualizado con nuevo progreso
        final updatedProfile = currentProfile.copyWith(
          hydrationProgress:
              event.hydrationProgress ?? currentProfile.hydrationProgress,
          sleepProgress: event.sleepProgress ?? currentProfile.sleepProgress,
          activityProgress:
              event.activityProgress ?? currentProfile.activityProgress,
          updatedAt: DateTime.now(),
        );

        final savedProfile = await ProfileService.updateProfile(updatedProfile);
        emit(HabitProgressUpdated(savedProfile));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        emit(ProfileLoaded(savedProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al actualizar progreso: ${e.toString()}'));
    }
  }

  /// Actualizar datos de salud
  Future<void> _onUpdateHealthData(
    UpdateHealthData event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(HealthDataUpdating(currentProfile));

        // Crear perfil actualizado con nuevos datos de salud
        final updatedProfile = currentProfile.copyWith(
          heightCm: event.height ?? currentProfile.heightCm,
          weightKg: event.weight ?? currentProfile.weightKg,
          riskFactors: event.riskFactors ?? currentProfile.riskFactors,
          updatedAt: DateTime.now(),
        );

        final savedProfile = await ProfileService.updateProfile(updatedProfile);
        emit(HealthDataUpdated(savedProfile));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        emit(ProfileLoaded(savedProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al actualizar datos de salud: ${e.toString()}'));
    }
  }

  /// Actualizar URL de la foto de perfil
  Future<void> _onUpdateProfilePictureEvent(
    UpdateProfilePictureEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        emit(ProfileImageUploading(currentProfile));

        // Crear perfil actualizado con nueva URL de imagen
        final updatedProfile = currentProfile.copyWith(
          profileImageUrl: event.profilePictureUrl,
          updatedAt: DateTime.now(),
        );

        final savedProfile = await ProfileService.updateProfile(updatedProfile);
        emit(ProfileImageUpdated(savedProfile));

        // Emitir estado cargado después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        emit(ProfileLoaded(savedProfile));
      }
    } catch (e) {
      emit(ProfileError('Error al actualizar foto de perfil: ${e.toString()}'));
    }
  }

  /// Obtener el perfil actual si está cargado
  UserProfile? get currentProfile {
    if (state is ProfileLoaded) {
      return (state as ProfileLoaded).profile;
    }
    return null;
  }

  /// Verificar si el perfil está cargado
  bool get isProfileLoaded => state is ProfileLoaded;

  /// Verificar si hay una operación en progreso
  bool get isLoading {
    return state is ProfileLoading ||
        state is ProfileUpdating ||
        state is ProfileImageUploading ||
        state is ProfileExporting ||
        state is ProfileDeleting ||
        state is SmartSettingsUpdating ||
        state is HabitProgressUpdating ||
        state is HealthDataUpdating;
  }
}
