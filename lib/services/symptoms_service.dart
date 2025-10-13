import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar operaciones CRUD de síntomas del usuario con Supabase
class SymptomsService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'user_symptoms';

  /// Registra un nuevo síntoma para el usuario actual
  static Future<Map<String, dynamic>?> registerSymptom({
    required String symptomName,
    required String severity,
    String? description,
    String? bodyPart,
    DateTime? occurredAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final symptomData = {
        'user_id': user.id,
        'symptom_name': symptomName,
        'severity': severity,
        'description': description,
        'body_part': bodyPart,
        'occurred_at': (occurredAt ?? DateTime.now()).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_tableName)
          .insert(symptomData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al registrar síntoma: $e');
    }
  }

  /// Obtiene los síntomas del usuario actual
  static Future<List<Map<String, dynamic>>> getUserSymptoms({
    int? limit,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Build query based on parameters
      dynamic response;
      
      if (fromDate != null && toDate != null) {
        // Both dates provided
        if (limit != null) {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .gte('occurred_at', fromDate.toIso8601String())
              .lte('occurred_at', toDate.toIso8601String())
              .order('occurred_at', ascending: false)
              .limit(limit);
        } else {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .gte('occurred_at', fromDate.toIso8601String())
              .lte('occurred_at', toDate.toIso8601String())
              .order('occurred_at', ascending: false);
        }
      } else if (fromDate != null) {
        // Only from date provided
        if (limit != null) {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .gte('occurred_at', fromDate.toIso8601String())
              .order('occurred_at', ascending: false)
              .limit(limit);
        } else {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .gte('occurred_at', fromDate.toIso8601String())
              .order('occurred_at', ascending: false);
        }
      } else if (toDate != null) {
        // Only to date provided
        if (limit != null) {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .lte('occurred_at', toDate.toIso8601String())
              .order('occurred_at', ascending: false)
              .limit(limit);
        } else {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .lte('occurred_at', toDate.toIso8601String())
              .order('occurred_at', ascending: false);
        }
      } else {
        // No date filters
        if (limit != null) {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .order('occurred_at', ascending: false)
              .limit(limit);
        } else {
          response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', user.id)
              .order('occurred_at', ascending: false);
        }
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener síntomas: $e');
    }
  }

  /// Obtiene los síntomas del día actual
  static Future<List<Map<String, dynamic>>> getTodaySymptoms() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getUserSymptoms(
      fromDate: startOfDay,
      toDate: endOfDay,
    );
  }

  /// Actualiza un síntoma existente
  static Future<Map<String, dynamic>?> updateSymptom({
    required String symptomId,
    String? symptomName,
    String? severity,
    String? description,
    String? bodyPart,
    DateTime? occurredAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (symptomName != null) updateData['symptom_name'] = symptomName;
      if (severity != null) updateData['severity'] = severity;
      if (description != null) updateData['description'] = description;
      if (bodyPart != null) updateData['body_part'] = bodyPart;
      if (occurredAt != null) updateData['occurred_at'] = occurredAt.toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', symptomId)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al actualizar síntoma: $e');
    }
  }

  /// Elimina un síntoma
  static Future<void> deleteSymptom(String symptomId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', symptomId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error al eliminar síntoma: $e');
    }
  }

  /// Obtiene estadísticas de síntomas del usuario
  static Future<Map<String, dynamic>> getSymptomsStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final symptoms = await getUserSymptoms(
        fromDate: fromDate,
        toDate: toDate,
      );

      final stats = <String, dynamic>{
        'total_symptoms': symptoms.length,
        'symptoms_by_severity': <String, int>{},
        'symptoms_by_body_part': <String, int>{},
        'most_common_symptom': null,
        'average_severity': 0.0,
      };

      if (symptoms.isEmpty) return stats;

      // Contar por severidad
      final severityCounts = <String, int>{};
      final bodyPartCounts = <String, int>{};
      final symptomCounts = <String, int>{};
      int totalSeverityScore = 0;

      for (final symptom in symptoms) {
        final severity = symptom['severity'] as String? ?? 'unknown';
        final bodyPart = symptom['body_part'] as String? ?? 'unknown';
        final symptomName = symptom['symptom_name'] as String? ?? 'unknown';

        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        bodyPartCounts[bodyPart] = (bodyPartCounts[bodyPart] ?? 0) + 1;
        symptomCounts[symptomName] = (symptomCounts[symptomName] ?? 0) + 1;

        // Convertir severidad a número para promedio
        switch (severity.toLowerCase()) {
          case 'leve':
            totalSeverityScore += 1;
            break;
          case 'moderado':
            totalSeverityScore += 2;
            break;
          case 'severo':
            totalSeverityScore += 3;
            break;
          default:
            totalSeverityScore += 1;
        }
      }

      stats['symptoms_by_severity'] = severityCounts;
      stats['symptoms_by_body_part'] = bodyPartCounts;
      stats['average_severity'] = totalSeverityScore / symptoms.length;

      // Encontrar síntoma más común
      if (symptomCounts.isNotEmpty) {
        final mostCommon = symptomCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        stats['most_common_symptom'] = mostCommon.key;
      }

      return stats;
    } catch (e) {
      throw Exception('Error al obtener estadísticas de síntomas: $e');
    }
  }
}