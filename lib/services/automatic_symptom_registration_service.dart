import 'package:vive_good_app/services/symptoms_service.dart';

/// Servicio para registrar automáticamente síntomas detectados por Gemini
class AutomaticSymptomRegistrationService {
  
  /// Procesa un mensaje y registra automáticamente los síntomas detectados
  static Future<List<Map<String, dynamic>>> processMessageForSymptoms({
    required String message,
    required String userId,
  }) async {
    try {
      print('🔥 DEBUG: Procesando mensaje para síntomas automáticos: $message');
      
      final detectedSymptoms = _extractSymptomsFromMessage(message);
      final registeredSymptoms = <Map<String, dynamic>>[];
      
      for (final symptom in detectedSymptoms) {
        try {
          final registeredSymptom = await SymptomsService.registerSymptom(
            symptomName: symptom['name'],
            severity: symptom['severity'],
            description: symptom['description'],
            bodyPart: symptom['bodyPart'],
            occurredAt: DateTime.now(),
          );
          
          if (registeredSymptom != null) {
            registeredSymptoms.add(registeredSymptom);
            print('✅ Síntoma registrado automáticamente: ${symptom['name']}');
          }
        } catch (e) {
          print('❌ Error registrando síntoma ${symptom['name']}: $e');
        }
      }
      
      return registeredSymptoms;
    } catch (e) {
      print('❌ Error en procesamiento automático de síntomas: $e');
      return [];
    }
  }
  
  /// Extrae síntomas del mensaje del usuario
  static List<Map<String, dynamic>> _extractSymptomsFromMessage(String message) {
    final symptoms = <Map<String, dynamic>>[];
    final lowerMessage = message.toLowerCase();
    
    // Detectar dolor de estómago
    if (_containsAnyKeyword(lowerMessage, ['dolor de estómago', 'dolor estomacal', 'duele el estómago', 'dolor en el estómago'])) {
      symptoms.add({
        'name': 'Dolor de estómago',
        'severity': _extractSeverity(lowerMessage, 'dolor'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Estómago',
      });
    }
    
    // Detectar acidez
    if (_containsAnyKeyword(lowerMessage, ['acidez', 'agruras', 'reflujo', 'ardor estomacal'])) {
      symptoms.add({
        'name': 'Acidez estomacal',
        'severity': _extractSeverity(lowerMessage, 'acidez'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Estómago',
      });
    }
    
    // Detectar náuseas
    if (_containsAnyKeyword(lowerMessage, ['náuseas', 'nauseas', 'ganas de vomitar', 'mareo', 'vómito'])) {
      symptoms.add({
        'name': 'Náuseas',
        'severity': _extractSeverity(lowerMessage, 'náuseas'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Estómago',
      });
    }
    
    // Detectar hinchazón
    if (_containsAnyKeyword(lowerMessage, ['hinchazón', 'inflamado', 'distensión', 'pesadez estomacal'])) {
      symptoms.add({
        'name': 'Hinchazón abdominal',
        'severity': _extractSeverity(lowerMessage, 'hinchazón'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Abdomen',
      });
    }
    
    // Detectar gases
    if (_containsAnyKeyword(lowerMessage, ['gases', 'flatulencia', 'eructos', 'ventosidades'])) {
      symptoms.add({
        'name': 'Gases intestinales',
        'severity': _extractSeverity(lowerMessage, 'gases'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Intestino',
      });
    }
    
    // Detectar pérdida de apetito
    if (_containsAnyKeyword(lowerMessage, ['sin apetito', 'no tengo hambre', 'inapetencia', 'pérdida de apetito'])) {
      symptoms.add({
        'name': 'Pérdida de apetito',
        'severity': 'Leve',
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'General',
      });
    }
    
    // Detectar diarrea
    if (_containsAnyKeyword(lowerMessage, ['diarrea', 'deposiciones líquidas', 'heces líquidas', 'evacuaciones frecuentes'])) {
      symptoms.add({
        'name': 'Diarrea',
        'severity': _extractSeverity(lowerMessage, 'diarrea'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Intestino',
      });
    }
    
    // Detectar estreñimiento
    if (_containsAnyKeyword(lowerMessage, ['estreñimiento', 'constipación', 'no puedo evacuar', 'dificultad para defecar'])) {
      symptoms.add({
        'name': 'Estreñimiento',
        'severity': _extractSeverity(lowerMessage, 'estreñimiento'),
        'description': 'Detectado automáticamente: $message',
        'bodyPart': 'Intestino',
      });
    }
    
    return symptoms;
  }
  
  /// Extrae la severidad del síntoma basándose en el contexto
  static String _extractSeverity(String message, String symptomType) {
    final lowerMessage = message.toLowerCase();
    
    // Palabras que indican severidad alta
    if (_containsAnyKeyword(lowerMessage, ['mucho', 'intenso', 'fuerte', 'insoportable', 'terrible', 'muy'])) {
      return 'Severo';
    }
    
    // Palabras que indican severidad media
    if (_containsAnyKeyword(lowerMessage, ['moderado', 'regular', 'bastante', 'considerable'])) {
      return 'Moderado';
    }
    
    // Palabras que indican severidad baja
    if (_containsAnyKeyword(lowerMessage, ['poco', 'leve', 'ligero', 'suave', 'apenas'])) {
      return 'Leve';
    }
    
    // Por defecto, asignar severidad moderada
    return 'Moderado';
  }
  
  /// Verifica si el texto contiene alguna palabra clave
  static bool _containsAnyKeyword(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Obtiene un resumen de los síntomas registrados automáticamente
  static String generateSymptomsRegistrationSummary(List<Map<String, dynamic>> registeredSymptoms) {
    if (registeredSymptoms.isEmpty) {
      return '';
    }
    
    final symptomNames = registeredSymptoms
        .map((symptom) => symptom['symptom_name'] as String)
        .join(', ');
    
    return '\n\n📝 **Síntomas registrados automáticamente:** $symptomNames\n'
           'Estos síntomas han sido guardados en tu historial médico para seguimiento.';
  }
}