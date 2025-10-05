import 'dart:io';

class DocumentationService {
  static const String _documentationPath = 'gastritis_prevention_system_documentation.md';
  static String? _cachedDocumentation;

  /// Lee y cachea la documentación del sistema de prevención de gastritis
  static Future<String> getDocumentation() async {
    if (_cachedDocumentation != null) {
      return _cachedDocumentation!;
    }

    try {
      final file = File(_documentationPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _cachedDocumentation = _extractRelevantSections(content);
        return _cachedDocumentation!;
      } else {
        return _getDefaultDocumentation();
      }
    } catch (e) {
      return _getDefaultDocumentation();
    }
  }

  /// Extrae las secciones más relevantes de la documentación
  static String _extractRelevantSections(String fullContent) {
    final buffer = StringBuffer();
    
    // Extraer secciones clave
    final sections = [
      'Sistema de Prevención de Gastritis',
      'Características Principales',
      'Síntomas de Gastritis',
      'Factores de Riesgo',
      'Alimentos Protectores',
      'Hábitos Preventivos',
      'Recomendaciones Médicas',
    ];

    final lines = fullContent.split('\n');
    bool inRelevantSection = false;
    String currentSection = '';
    
    for (final line in lines) {
      // Detectar inicio de sección relevante
      for (final section in sections) {
        if (line.toLowerCase().contains(section.toLowerCase())) {
          inRelevantSection = true;
          currentSection = section;
          buffer.writeln('## $section');
          break;
        }
      }
      
      // Si estamos en una sección relevante, agregar contenido
      if (inRelevantSection) {
        if (line.startsWith('#') && !line.toLowerCase().contains(currentSection.toLowerCase())) {
          // Nueva sección, verificar si es relevante
          bool isRelevant = false;
          for (final section in sections) {
            if (line.toLowerCase().contains(section.toLowerCase())) {
              isRelevant = true;
              currentSection = section;
              break;
            }
          }
          inRelevantSection = isRelevant;
        }
        
        if (inRelevantSection) {
          buffer.writeln(line);
        }
      }
    }

    // Si no se encontró contenido relevante, usar documentación por defecto
    if (buffer.isEmpty) {
      return _getDefaultDocumentation();
    }

    return buffer.toString();
  }

  /// Documentación por defecto en caso de que no se pueda leer el archivo
  static String _getDefaultDocumentation() {
    return '''
## Sistema de Prevención de Gastritis

### Síntomas Comunes de Gastritis:
- Dolor o ardor en el estómago (especialmente entre comidas o por la noche)
- Náuseas y vómitos
- Sensación de llenura en la parte superior del abdomen después de comer
- Indigestión
- Heces oscuras o vómito con sangre (requiere atención médica inmediata)

### Factores de Riesgo:
- Infección por Helicobacter pylori
- Uso prolongado de antiinflamatorios no esteroideos (AINEs)
- Consumo excesivo de alcohol
- Estrés crónico
- Comidas picantes o ácidas
- Fumar
- Edad avanzada

### Alimentos Protectores:
- Avena y cereales integrales
- Plátanos maduros
- Manzanas (sin cáscara)
- Yogur con probióticos
- Jengibre fresco
- Miel natural
- Verduras cocidas (brócoli, zanahoria)
- Pescado magro

### Hábitos Preventivos:
- Comer en horarios regulares
- Masticar bien los alimentos
- Evitar acostarse inmediatamente después de comer
- Reducir el estrés mediante técnicas de relajación
- Mantener un peso saludable
- Evitar el tabaco y limitar el alcohol
- Beber suficiente agua durante el día

### Cuándo Consultar un Médico:
- Dolor abdominal severo o persistente
- Vómito con sangre o material que parece café molido
- Heces negras o con sangre
- Pérdida de peso inexplicable
- Síntomas que no mejoran con cambios en la dieta
''';
  }

  /// Limpia el caché de documentación
  static void clearCache() {
    _cachedDocumentation = null;
  }
}