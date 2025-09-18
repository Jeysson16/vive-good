import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

/// Servicio para manejar operaciones CRUD del perfil de usuario con Supabase
class ProfileService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'profiles';

  /// Obtiene el perfil del usuario actual autenticado
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener el perfil: $e');
    }
  }

  /// Obtiene un perfil por ID específico
  static Future<UserProfile?> getProfileById(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener el perfil por ID: $e');
    }
  }

  /// Crea un nuevo perfil para el usuario autenticado
  static Future<UserProfile> createProfile({
    required String firstName,
    required String lastName,
    required String email,
    int? age,
    String? institution,
    String? phone,
    double? heightCm,
    double? weightKg,
    List<String>? riskFactors,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final profileData = {
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'age': age,
        'institution': institution ?? 'UCV',
        'phone': phone,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'risk_factors': riskFactors ?? [],
        'is_profile_complete': _isProfileComplete(
          firstName: firstName,
          lastName: lastName,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
        ),
      };

      final response = await _supabase
          .from(_tableName)
          .insert(profileData)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear el perfil: $e');
    }
  }

  /// Actualiza el perfil del usuario actual
  static Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Preparar datos para actualización (sin incluir campos de solo lectura)
      final updateData = profile.toJson();
      updateData.remove('created_at');
      updateData.remove('updated_at');
      updateData.remove('last_profile_update');

      // Verificar si el perfil está completo
      updateData['is_profile_complete'] = _isProfileComplete(
        firstName: profile.firstName,
        lastName: profile.lastName,
        age: profile.age,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
      );

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar el perfil: $e');
    }
  }

  /// Actualiza campos específicos del perfil
  static Future<UserProfile> updateProfileFields(
    Map<String, dynamic> fields,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from(_tableName)
          .update(fields)
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar campos del perfil: $e');
    }
  }

  /// Actualiza el progreso de un hábito específico
  static Future<UserProfile> updateHabitProgress({
    required String habitType, // 'hydration', 'sleep', 'activity'
    required int progress,
    int? goal,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final updateData = <String, dynamic>{'${habitType}_progress': progress};

      if (goal != null) {
        updateData['${habitType}_goal'] = goal;
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar progreso del hábito: $e');
    }
  }

  /// Actualiza las configuraciones inteligentes
  static Future<UserProfile> updateSmartSettings({
    bool? autoSuggestionsEnabled,
    String? morningReminderTime,
    String? eveningReminderTime,
    bool? dailyRemindersEnabled,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final updateData = <String, dynamic>{};

      if (autoSuggestionsEnabled != null) {
        updateData['auto_suggestions_enabled'] = autoSuggestionsEnabled;
      }
      if (morningReminderTime != null) {
        updateData['morning_reminder_time'] = morningReminderTime;
      }
      if (eveningReminderTime != null) {
        updateData['evening_reminder_time'] = eveningReminderTime;
      }
      if (dailyRemindersEnabled != null) {
        updateData['daily_reminders_enabled'] = dailyRemindersEnabled;
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar configuraciones: $e');
    }
  }

  /// Actualiza los factores de riesgo
  static Future<UserProfile> updateRiskFactors(List<String> riskFactors) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from(_tableName)
          .update({'risk_factors': riskFactors})
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar factores de riesgo: $e');
    }
  }

  /// Sube una imagen de perfil y actualiza la URL
  static Future<UserProfile> uploadProfileImage(String filePath) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Generar nombre único para la imagen
      final fileName =
          'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Leer el archivo como bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Subir imagen al storage de Supabase
      await _supabase.storage
          .from('profile-images')
          .uploadBinary(fileName, bytes);

      // Obtener URL pública de la imagen
      final imageUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // Actualizar el perfil con la nueva URL
      final response = await _supabase
          .from(_tableName)
          .update({'profile_image_url': imageUrl})
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error al subir imagen de perfil: $e');
    }
  }

  /// Elimina el perfil del usuario por ID
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', userId);
    } catch (e) {
      throw Exception('Error al eliminar el perfil: $e');
    }
  }

  /// Elimina el perfil del usuario actual (soft delete)
  static Future<void> deleteProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase.from(_tableName).delete().eq('id', user.id);
    } catch (e) {
      throw Exception('Error al eliminar el perfil: $e');
    }
  }

  /// Verifica si el usuario tiene un perfil creado
  static Future<bool> hasProfile() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// Exporta el historial del usuario y devuelve la ruta del archivo
  static Future<String> exportUserHistory(String userId) async {
    try {
      final historyData = await _exportUserHistoryData(userId);
      // En una implementación real, aquí se guardaría el archivo
      // Por ahora retornamos una ruta simulada
      return '/downloads/user_history_${DateTime.now().millisecondsSinceEpoch}.json';
    } catch (e) {
      throw Exception('Error al exportar historial: $e');
    }
  }

  /// Obtiene los datos del historial del usuario en formato JSON
  static Future<Map<String, dynamic>> _exportUserHistoryData(
    String userId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener perfil
      final profile = await getCurrentUserProfile();

      // Obtener hábitos del usuario
      final userHabits = await _supabase
          .from('user_habits')
          .select('*, habits(*)')
          .eq('user_id', user.id);

      // Obtener logs de hábitos
      final habitLogs = await _supabase
          .from('user_habit_logs')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Obtener progreso del usuario
      final userProgress = await _supabase
          .from('user_progress')
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false);

      return {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': user.id,
        'profile': profile?.toJson(),
        'habits': userHabits,
        'habit_logs': habitLogs,
        'progress': userProgress,
      };
    } catch (e) {
      throw Exception('Error al exportar historial: $e');
    }
  }

  /// Función auxiliar para determinar si un perfil está completo
  static bool _isProfileComplete({
    required String firstName,
    required String lastName,
    int? age,
    double? heightCm,
    double? weightKg,
  }) {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        age != null &&
        heightCm != null &&
        weightKg != null;
  }

  /// Obtiene estadísticas del perfil
  static Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw Exception('Perfil no encontrado');
      }

      // Calcular estadísticas de hábitos
      final totalHabits =
          profile.hydrationGoal + profile.sleepGoal + profile.activityGoal;
      final completedHabits =
          profile.hydrationProgress +
          profile.sleepProgress +
          profile.activityProgress;
      final completionRate = totalHabits > 0
          ? (completedHabits / totalHabits * 100)
          : 0.0;

      return {
        'completion_rate': completionRate,
        'total_habits': totalHabits,
        'completed_habits': completedHabits,
        'hydration_rate': profile.hydrationGoal > 0
            ? (profile.hydrationProgress / profile.hydrationGoal * 100)
            : 0.0,
        'sleep_rate': profile.sleepGoal > 0
            ? (profile.sleepProgress / profile.sleepGoal * 100)
            : 0.0,
        'activity_rate': profile.activityGoal > 0
            ? (profile.activityProgress / profile.activityGoal * 100)
            : 0.0,
        'risk_factors_count': profile.riskFactors.length,
        'profile_complete': profile.isProfileComplete,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
