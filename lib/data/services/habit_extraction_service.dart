import '../../domain/entities/habit.dart';
import '../../domain/entities/assistant/assistant_response.dart';

class HabitExtractionService {
  /// Extrae hábitos sugeridos de la respuesta del asistente
  List<Habit> extractHabitsFromResponse(AssistantResponse response, String userId) {
    final List<Habit> extractedHabits = [];
    
    // Analizar el contenido de la respuesta para extraer hábitos
    final content = response.content.toLowerCase();
    extractedHabits.addAll(_extractHabitsFromContent(content, userId));
    
    return extractedHabits;
  }
  

  /// Analiza el contenido de texto para extraer hábitos (método tradicional)
  List<Habit> _extractHabitsFromContent(String content, String userId) {
    final List<Habit> extractedHabits = [];
    
    // Patrones mejorados para identificar hábitos relacionados con gastritis y salud digestiva
    final habitPatterns = {
      // Alimentación específica para gastritis
      'comidas pequeñas': {
        'keywords': ['comidas pequeñas', 'porciones pequeñas', 'comer poco', 'pequeñas cantidades'],
        'name': 'Comidas pequeñas y frecuentes',
        'description': 'Comer porciones pequeñas cada 2-3 horas para reducir la carga gástrica',
        'category': 'Alimentación',
        'frequency': 'every_2_hours',
        'reminderTimes': ['08:00', '10:30', '13:00', '15:30', '18:00', '20:30'],
        'difficulty': 'medium',
      },
      'evitar irritantes': {
        'keywords': ['evitar café', 'no alcohol', 'sin picante', 'evitar cítricos', 'alimentos irritantes'],
        'name': 'Evitar alimentos irritantes',
        'description': 'Eliminar café, alcohol, cítricos, picantes y alimentos que irritan el estómago',
        'category': 'Restricciones',
        'frequency': 'daily',
        'reminderTimes': ['12:00', '18:00'],
        'difficulty': 'hard',
      },
      'masticar bien': {
        'keywords': ['masticar bien', 'comer despacio', 'masticar lento', 'tragar despacio'],
        'name': 'Masticar bien los alimentos',
        'description': 'Masticar lentamente y bien cada bocado para facilitar la digestión',
        'category': 'Alimentación',
        'frequency': 'daily',
        'reminderTimes': ['08:00', '13:00', '19:00'],
        'difficulty': 'easy',
      },
      'hidratación': {
        'keywords': ['beber agua', 'hidratación', 'tomar líquidos', 'agua regularmente'],
        'name': 'Hidratación adecuada',
        'description': 'Beber agua entre comidas para mantener una buena hidratación',
        'category': 'Hidratación',
        'frequency': 'daily',
        'reminderTimes': ['09:00', '11:00', '15:00', '17:00'],
        'difficulty': 'easy',
      },
      'ejercicio suave': {
        'keywords': ['ejercicio suave', 'caminar', 'actividad ligera', 'movimiento'],
        'name': 'Ejercicio suave',
        'description': 'Realizar actividad física ligera como caminar para mejorar la digestión',
        'category': 'Ejercicio',
        'frequency': 'daily',
        'reminderTimes': ['07:00', '18:00'],
        'difficulty': 'easy',
      },
      'manejo estrés': {
        'keywords': ['reducir estrés', 'relajación', 'respiración', 'calma', 'meditación'],
        'name': 'Técnicas de relajación',
        'description': 'Practicar técnicas de relajación y respiración para reducir el estrés',
        'category': 'Bienestar Mental',
        'frequency': 'daily',
        'reminderTimes': ['20:00'],
        'difficulty': 'medium',
      },
      'horarios regulares': {
        'keywords': ['horarios regulares', 'comer a la misma hora', 'rutina alimentaria'],
        'name': 'Horarios regulares de comida',
        'description': 'Mantener horarios fijos para las comidas principales',
        'category': 'Alimentación',
        'frequency': 'daily',
        'reminderTimes': ['08:00', '13:00', '19:00'],
        'difficulty': 'medium',
      },
      'evitar acostarse': {
        'keywords': ['no acostarse después', 'esperar para dormir', 'no dormir inmediatamente'],
        'name': 'Esperar antes de acostarse',
        'description': 'Esperar al menos 2-3 horas después de cenar antes de acostarse',
        'category': 'Descanso',
        'frequency': 'daily',
        'reminderTimes': ['21:00'],
        'difficulty': 'medium',
      },
      'probióticos': {
        'keywords': ['probióticos', 'yogur', 'kéfir', 'alimentos fermentados'],
        'name': 'Consumir probióticos',
        'description': 'Incluir alimentos con probióticos para mejorar la flora intestinal',
        'category': 'Alimentación',
        'frequency': 'daily',
        'reminderTimes': ['09:00', '15:00'],
        'difficulty': 'easy',
      },
    };
    
    // Buscar patrones en el contenido usando palabras clave mejoradas
    for (final entry in habitPatterns.entries) {
      final habitData = entry.value;
      final keywords = habitData['keywords'] as List<String>;
      
      if (_containsAnyKeywords(content, keywords)) {
        final habit = Habit(
          id: '', // Se asignará al guardar en la base de datos
          userId: userId,
          name: habitData['name'] as String,
          description: habitData['description'] as String,
          categoryId: habitData['category'] as String,
          iconName: _getIconForCategory(habitData['category'] as String),
          iconColor: _getColorForCategory(habitData['category'] as String),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isPublic: false,
          createdBy: 'assistant',
        );
        
        extractedHabits.add(habit);
      }
    }
    
    return extractedHabits;
  }
  
  /// Verifica si el contenido contiene alguna de las palabras clave
  bool _containsAnyKeywords(String content, List<String> keywords) {
    return keywords.any((keyword) => content.toLowerCase().contains(keyword.toLowerCase()));
  }
  
  /// Obtiene los días objetivo según la frecuencia
  List<String> _getTargetDaysForFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      case 'weekdays':
        return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
      case 'weekends':
        return ['saturday', 'sunday'];
      default:
        return ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    }
  }
  
  /// Parsea los horarios de recordatorio desde diferentes formatos
  List<String> _parseReminderTimes(dynamic reminderTimes) {
    if (reminderTimes == null) return [];
    
    if (reminderTimes is List) {
      return reminderTimes.map((time) => time.toString()).toList();
    }
    
    if (reminderTimes is String) {
      // Si es una cadena, intentar dividir por comas
      return reminderTimes.split(',').map((time) => time.trim()).toList();
    }
    
    return [];
  }
  
  /// Determina el color basado en la categoría del hábito
  String _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'alimentación':
      case 'nutrition':
        return '#4CAF50'; // Verde
      case 'ejercicio':
      case 'exercise':
        return '#2196F3'; // Azul
      case 'descanso':
      case 'sueño':
      case 'sleep':
        return '#9C27B0'; // Púrpura
      case 'hidratación':
      case 'hydration':
        return '#00BCD4'; // Cian
      case 'bienestar mental':
      case 'estrés':
      case 'stress':
        return '#FF9800'; // Naranja
      case 'restricciones':
        return '#F44336'; // Rojo
      case 'medicación':
        return '#795548'; // Marrón
      default:
        return '#607D8B'; // Gris azulado
    }
  }
  
  /// Obtiene el icono según la categoría
  String _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'alimentación':
        return 'utensils';
      case 'hidratación':
        return 'droplets';
      case 'ejercicio':
        return 'activity';
      case 'bienestar mental':
        return 'brain';
      case 'descanso':
        return 'moon';
      case 'restricciones':
        return 'x-circle';
      case 'medicación':
        return 'pill';
      default:
        return 'target';
    }
  }
}