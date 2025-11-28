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

      // Convertir severidad de string a integer para la base de datos
      final severityInt = _convertSeverityToInt(severity);

      final symptomData = {
        'user_id': user.id,
        'symptom_name': symptomName,
        'symptom_type': symptomName, // También llenar symptom_type para compatibilidad
        'severity': severityInt,
        'description': description,
        'body_part': bodyPart,
        'occurred_at': (occurredAt ?? DateTime.now()).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_tableName)
          .insert(symptomData)
          .select()
          .single();

      // Convertir la respuesta para que severity sea string
      response['severity'] = _convertSeverityToString(response['severity']);
    
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

      final symptoms = List<Map<String, dynamic>>.from(response);
      
      // Convertir severidad de integer a string en cada síntoma
      for (final symptom in symptoms) {
        if (symptom['severity'] != null) {
          symptom['severity'] = _convertSeverityToString(symptom['severity']);
        }
      }
      
      return symptoms;
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

      if (symptomName != null) {
        updateData['symptom_name'] = symptomName;
        updateData['symptom_type'] = symptomName; // También actualizar symptom_type
      }
      if (severity != null) updateData['severity'] = _convertSeverityToInt(severity);
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

      // Convertir la respuesta para que severity sea string
      if (response['severity'] != null) {
        response['severity'] = _convertSeverityToString(response['severity']);
      }

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

  /// Convierte severidad de string a integer para la base de datos
  static int _convertSeverityToInt(String severity) {
    switch (severity.toLowerCase()) {
      case 'leve':
        return 2;
      case 'moderado':
        return 5;
      case 'fuerte':
        return 7;
      case 'severo':
        return 9;
      default:
        return 2; // Default a leve
    }
  }

  /// Convierte severidad de integer a string para la aplicación
  static String _convertSeverityToString(dynamic severity) {
    if (severity == null) return 'Leve';
    
    final severityInt = severity is int ? severity : int.tryParse(severity.toString()) ?? 2;
    
    if (severityInt <= 3) return 'Leve';
    if (severityInt <= 6) return 'Moderado';
    if (severityInt <= 8) return 'Fuerte';
    return 'Severo';
  }
}