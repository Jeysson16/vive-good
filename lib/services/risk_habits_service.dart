import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle risk eating habits operations with Supabase
class RiskHabitsService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'risk_eating_habits';

  /// Get risk habits assessment for the current user
  static Future<Map<String, dynamic>?> getUserRiskHabits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error getting risk habits: $e');
    }
  }

  /// Save or update risk habits assessment for the current user
  static Future<Map<String, dynamic>?> saveRiskHabits({
    required List<String> selectedHabits,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'user_id': user.id,
        'habits': selectedHabits,
        'total_risk': selectedHabits.length,
      };

      // Check if record exists
      final existingRecord = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        final response = await _supabase
            .from(_tableName)
            .update(data)
            .eq('user_id', user.id)
            .select()
            .single();
        return response;
      } else {
        // Insert new record
        final response = await _supabase
            .from(_tableName)
            .insert(data)
            .select()
            .single();
        return response;
      }
    } catch (e) {
      throw Exception('Error saving risk habits: $e');
    }
  }

  /// Delete risk habits assessment for the current user
  static Future<void> deleteRiskHabits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error deleting risk habits: $e');
    }
  }

  /// Check if user has completed risk habits assessment
  static Future<bool> hasCompletedAssessment() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get risk level based on number of selected habits
  static String getRiskLevel(int totalRisk) {
    if (totalRisk == 0) {
      return 'Bajo';
    } else if (totalRisk <= 3) {
      return 'Moderado';
    } else if (totalRisk <= 6) {
      return 'Alto';
    } else {
      return 'Muy Alto';
    }
  }

  /// Get risk level color based on number of selected habits
  static String getRiskLevelColor(int totalRisk) {
    if (totalRisk == 0) {
      return 'green';
    } else if (totalRisk <= 3) {
      return 'yellow';
    } else if (totalRisk <= 6) {
      return 'orange';
    } else {
      return 'red';
    }
  }

  /// Get predefined list of risky eating habits
  static List<String> getPredefinedRiskHabits() {
    return [
      'Saltarse comidas frecuentemente',
      'Comer muy rápido',
      'Consumo excesivo de alimentos procesados',
      'Comer tarde en la noche',
      'Consumo excesivo de azúcar',
      'Consumo excesivo de sal',
      'Comer mientras se ve TV o usa dispositivos',
      'Consumo frecuente de comida rápida',
      'No desayunar regularmente',
      'Comer por estrés o emociones',
      'Consumo excesivo de bebidas azucaradas',
      'Porciones muy grandes',
      'Consumo excesivo de grasas saturadas',
      'Comer sin horarios fijos',
      'Consumo frecuente de alcohol',
    ];
  }
}