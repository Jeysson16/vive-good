import '../../domain/entities/habit.dart';
import '../../domain/entities/user_habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/entities/assistant/assistant_response.dart';
import 'habit_extraction_service.dart';

class HabitAutoCreationService {
  final HabitRepository habitRepository;
  final HabitExtractionService habitExtractionService;
  
  HabitAutoCreationService({
    required this.habitRepository,
    required this.habitExtractionService,
  });
  
  /// Crea hábitos automáticamente basados en el contexto de la conversación
  Future<List<Habit>> createContextualHabits({
    required AssistantResponse assistantResponse,
    required String userMessage,
    required String userId,
  }) async {
    try {
      // Extraer hábitos sugeridos de la respuesta del asistente
      final extractedHabits = habitExtractionService.extractHabitsFromResponse(
        assistantResponse,
        userId,
      );
      
      if (extractedHabits.isEmpty) {
        return [];
      }
      
      // Analizar contexto temporal del mensaje del usuario
      final temporalContext = _analyzeTemporalContext(userMessage);
      
      // Filtrar hábitos que ya existen para el usuario
      final existingHabitsResult = await habitRepository.getUserHabits(userId);
      final existingUserHabits = existingHabitsResult.fold(
        (failure) => <UserHabit>[],
        (habits) => habits,
      );
      
      final newHabits = <Habit>[];
      
      for (final habit in extractedHabits) {
        final exists = existingUserHabits.any((existing) => 
          (existing.customName ?? existing.habit?.name ?? '').toLowerCase() == habit.name.toLowerCase()
        );
        
        if (!exists) {
          // Enriquecer el hábito con información contextual
          final enrichedHabit = _enrichHabitWithContext(habit, userMessage, temporalContext);
          newHabits.add(enrichedHabit);
        }
      }
      
      // Crear los nuevos hábitos en la base de datos
      final createdHabits = <Habit>[];
      for (final habit in newHabits) {
        try {
          final result = await habitRepository.addHabit(habit);
          result.fold(
            (failure) => print('Error creating habit ${habit.name}: $failure'),
            (success) => createdHabits.add(habit),
          );
        } catch (e) {
          // Log error pero continúa con los demás hábitos
          print('Error creating habit ${habit.name}: $e');
        }
      }
      
      return createdHabits;
    } catch (e) {
      print('Error in createContextualHabits: $e');
      return [];
    }
  }
  

  
  /// Crea un hábito personalizado basado en texto libre
  Future<Habit?> createCustomHabit({
    required String habitText,
    required String userId,
    String? category,
    String? frequency,
  }) async {
    try {
      // Analizar el texto para extraer información del hábito
      final habitInfo = _parseHabitText(habitText);
      
      final habit = Habit(
        id: '',
        name: habitInfo['name'] ?? habitText,
        description: habitInfo['description'] ?? 'Hábito personalizado',
        categoryId: category ?? habitInfo['category'] ?? 'General',
        iconName: 'target',
        iconColor: '#607D8B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: false,
        createdBy: userId,
        userId: userId,
      );
      
      final result = await habitRepository.addHabit(habit);
      return result.fold(
        (failure) => null,
        (success) => habit,
      );
    } catch (e) {
      print('Error creating custom habit: $e');
      return null;
    }
  }
  
  /// Analiza texto libre para extraer información del hábito
  Map<String, dynamic> _parseHabitText(String text) {
    final result = <String, dynamic>{};
    final lowerText = text.toLowerCase();
    
    // Extraer nombre (primera parte de la oración)
    final sentences = text.split('.');
    if (sentences.isNotEmpty) {
      result['name'] = sentences.first.trim();
    }
    
    // Detectar categoría por palabras clave mejorada
    result['category'] = _detectCategory(lowerText);
    
    // Detectar frecuencia mejorada
    result['frequency'] = _detectFrequency(lowerText);
    
    // Detectar horarios específicos
    result['reminderTimes'] = _extractTimeSchedules(text);
    
    // Detectar intensidad/dificultad
    result['difficulty'] = _detectDifficulty(lowerText);
    
    // Detectar duración específica
    result['duration'] = _extractDuration(lowerText);
    
    return result;
  }
  
  /// Detecta la categoría más apropiada basada en palabras clave
  String _detectCategory(String lowerText) {
    // Categorías específicas para gastritis y salud digestiva
    if (_containsAnyKeyword(lowerText, ['comida', 'comer', 'alimentación', 'dieta', 'porción', 'masticar', 'tragar'])) {
      return 'Alimentación';
    }
    if (_containsAnyKeyword(lowerText, ['ejercicio', 'caminar', 'correr', 'actividad', 'movimiento', 'deporte', 'gimnasio'])) {
      return 'Ejercicio';
    }
    if (_containsAnyKeyword(lowerText, ['agua', 'beber', 'hidrat', 'líquido', 'infusión', 'té'])) {
      return 'Hidratación';
    }
    if (_containsAnyKeyword(lowerText, ['dormir', 'descansar', 'sueño', 'acostarse', 'levantarse', 'siesta'])) {
      return 'Descanso';
    }
    if (_containsAnyKeyword(lowerText, ['estrés', 'relajación', 'meditación', 'respiración', 'calma', 'ansiedad'])) {
      return 'Bienestar Mental';
    }
    if (_containsAnyKeyword(lowerText, ['medicamento', 'medicina', 'pastilla', 'tratamiento', 'tomar'])) {
      return 'Medicación';
    }
    if (_containsAnyKeyword(lowerText, ['evitar', 'no comer', 'eliminar', 'reducir', 'limitar'])) {
      return 'Restricciones';
    }
    
    return 'General';
  }
  
  /// Detecta la frecuencia basada en palabras clave
  String _detectFrequency(String lowerText) {
    if (_containsAnyKeyword(lowerText, ['diario', 'todos los días', 'cada día', 'a diario'])) {
      return 'daily';
    }
    if (_containsAnyKeyword(lowerText, ['cada 2 horas', 'cada dos horas', '2-3 horas', 'frecuente'])) {
      return 'every_2_hours';
    }
    if (_containsAnyKeyword(lowerText, ['cada 3 horas', 'cada tres horas', '3 veces al día'])) {
      return 'every_3_hours';
    }
    if (_containsAnyKeyword(lowerText, ['semanal', 'una vez por semana', 'cada semana'])) {
      return 'weekly';
    }
    if (_containsAnyKeyword(lowerText, ['días laborables', 'entre semana', 'lunes a viernes'])) {
      return 'weekdays';
    }
    if (_containsAnyKeyword(lowerText, ['fin de semana', 'sábado y domingo'])) {
      return 'weekends';
    }
    
    return 'daily'; // Por defecto
  }
  
  /// Extrae horarios específicos del texto
  List<String> _extractTimeSchedules(String text) {
    final times = <String>[];
    
    // Patrones de tiempo comunes
    final timePatterns = [
      RegExp(r'(\d{1,2}):(\d{2})'), // HH:MM
      RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false), // H am/pm
      RegExp(r'a las (\d{1,2})', caseSensitive: false), // a las H
    ];
    
    for (final pattern in timePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        times.add(match.group(0) ?? '');
      }
    }
    
    // Si no se encuentran horarios específicos, usar horarios por defecto según contexto
    if (times.isEmpty) {
      times.addAll(_getDefaultTimesForContext(text.toLowerCase()));
    }
    
    return times.where((time) => time.isNotEmpty).toList();
  }
  
  /// Obtiene horarios por defecto según el contexto
  List<String> _getDefaultTimesForContext(String lowerText) {
    if (_containsAnyKeyword(lowerText, ['desayuno', 'mañana', 'levantarse'])) {
      return ['08:00'];
    }
    if (_containsAnyKeyword(lowerText, ['almuerzo', 'mediodía', 'comida'])) {
      return ['12:00'];
    }
    if (_containsAnyKeyword(lowerText, ['cena', 'noche', 'tarde'])) {
      return ['19:00'];
    }
    if (_containsAnyKeyword(lowerText, ['agua', 'hidrat', 'beber'])) {
      return ['09:00', '12:00', '15:00', '18:00'];
    }
    if (_containsAnyKeyword(lowerText, ['medicamento', 'pastilla'])) {
      return ['08:00', '20:00'];
    }
    if (_containsAnyKeyword(lowerText, ['ejercicio', 'caminar'])) {
      return ['07:00', '18:00'];
    }
    
    return ['09:00']; // Por defecto
  }
  
  /// Detecta la dificultad del hábito
  String _detectDifficulty(String lowerText) {
    if (_containsAnyKeyword(lowerText, ['fácil', 'simple', 'básico', 'poco'])) {
      return 'easy';
    }
    if (_containsAnyKeyword(lowerText, ['difícil', 'complejo', 'intenso', 'mucho'])) {
      return 'hard';
    }
    
    return 'medium'; // Por defecto
  }
  
  /// Extrae duración específica del texto
  String? _extractDuration(String lowerText) {
    final durationPatterns = [
      RegExp(r'(\d+)\s*minutos?'), // X minutos
      RegExp(r'(\d+)\s*horas?'), // X horas
      RegExp(r'media\s*hora'), // media hora
    ];
    
    for (final pattern in durationPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        return match.group(0);
      }
    }
    
    return null;
  }
  
  /// Verifica si el texto contiene alguna de las palabras clave
  bool _containsAnyKeyword(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Analiza el contexto temporal del mensaje del usuario
  Map<String, dynamic> _analyzeTemporalContext(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    final now = DateTime.now();
    final context = <String, dynamic>{
      'timeOfDay': _detectTimeOfDay(lowerMessage, now),
      'urgency': _detectUrgency(lowerMessage),
      'frequency': _detectFrequencyFromMessage(lowerMessage),
      'symptoms': _detectSymptoms(lowerMessage),
      'mealContext': _detectMealContext(lowerMessage),
    };
    
    return context;
  }
  
  /// Detecta la hora del día mencionada en el mensaje
  String _detectTimeOfDay(String lowerMessage, DateTime now) {
    if (_containsAnyKeyword(lowerMessage, ['mañana', 'desayuno', 'levantarme', 'madrugada'])) {
      return 'morning';
    }
    if (_containsAnyKeyword(lowerMessage, ['mediodía', 'almuerzo', 'tarde temprano'])) {
      return 'midday';
    }
    if (_containsAnyKeyword(lowerMessage, ['tarde', 'merienda', 'después del trabajo'])) {
      return 'afternoon';
    }
    if (_containsAnyKeyword(lowerMessage, ['noche', 'cena', 'antes de dormir', 'acostarme'])) {
      return 'evening';
    }
    
    // Si no se especifica, usar la hora actual
    final hour = now.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 15) return 'midday';
    if (hour >= 15 && hour < 19) return 'afternoon';
    return 'evening';
  }
  
  /// Detecta la urgencia del mensaje
  String _detectUrgency(String lowerMessage) {
    if (_containsAnyKeyword(lowerMessage, ['urgente', 'inmediato', 'ahora', 'ya', 'rápido', 'dolor fuerte'])) {
      return 'high';
    }
    if (_containsAnyKeyword(lowerMessage, ['pronto', 'cuanto antes', 'necesito', 'importante'])) {
      return 'medium';
    }
    return 'low';
  }
  
  /// Detecta frecuencia mencionada en el mensaje
  String? _detectFrequencyFromMessage(String lowerMessage) {
    if (_containsAnyKeyword(lowerMessage, ['siempre', 'constantemente', 'todo el tiempo'])) {
      return 'very_frequent';
    }
    if (_containsAnyKeyword(lowerMessage, ['frecuentemente', 'a menudo', 'varias veces'])) {
      return 'frequent';
    }
    if (_containsAnyKeyword(lowerMessage, ['a veces', 'ocasionalmente', 'de vez en cuando'])) {
      return 'occasional';
    }
    if (_containsAnyKeyword(lowerMessage, ['raramente', 'pocas veces', 'casi nunca'])) {
      return 'rare';
    }
    return null;
  }
  
  /// Detecta síntomas mencionados en el mensaje
  List<String> _detectSymptoms(String lowerMessage) {
    final symptoms = <String>[];
    
    if (_containsAnyKeyword(lowerMessage, ['dolor', 'duele', 'molestia'])) {
      symptoms.add('pain');
    }
    if (_containsAnyKeyword(lowerMessage, ['acidez', 'ácido', 'ardor'])) {
      symptoms.add('acidity');
    }
    if (_containsAnyKeyword(lowerMessage, ['náuseas', 'ganas de vomitar', 'mareo'])) {
      symptoms.add('nausea');
    }
    if (_containsAnyKeyword(lowerMessage, ['inflamación', 'hinchazón', 'distensión'])) {
      symptoms.add('inflammation');
    }
    if (_containsAnyKeyword(lowerMessage, ['gases', 'flatulencia', 'eructos'])) {
      symptoms.add('gas');
    }
    
    return symptoms;
  }
  
  /// Detecta contexto de comidas en el mensaje
  String? _detectMealContext(String lowerMessage) {
    if (_containsAnyKeyword(lowerMessage, ['después de comer', 'post comida', 'tras la comida'])) {
      return 'after_meal';
    }
    if (_containsAnyKeyword(lowerMessage, ['antes de comer', 'pre comida', 'en ayunas'])) {
      return 'before_meal';
    }
    if (_containsAnyKeyword(lowerMessage, ['durante la comida', 'mientras como'])) {
      return 'during_meal';
    }
    return null;
  }
  
  /// Enriquece un hábito con información contextual
  Habit _enrichHabitWithContext(Habit habit, String userMessage, Map<String, dynamic> context) {
    // Generar horarios inteligentes basados en el contexto
    final smartSchedule = _generateSmartSchedule(habit, context);
    
    // Ajustar descripción con contexto específico
    final enrichedDescription = _generateContextualDescription(habit, context);
    
    // Sugerir recordatorios personalizados
    final reminderSuggestions = _generateReminderSuggestions(habit, context);
    
    return Habit(
      id: habit.id,
      name: habit.name,
      description: enrichedDescription,
      categoryId: habit.categoryId,
      iconName: _selectContextualIcon(habit, context),
      iconColor: _selectContextualColor(habit, context),
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      isPublic: habit.isPublic,
      createdBy: habit.createdBy,
      userId: habit.userId,
    );
  }
  
  /// Genera horarios inteligentes basados en el contexto
  List<String> _generateSmartSchedule(Habit habit, Map<String, dynamic> context) {
    final timeOfDay = context['timeOfDay'] as String;
    final urgency = context['urgency'] as String;
    final symptoms = context['symptoms'] as List<String>;
    final mealContext = context['mealContext'] as String?;
    
    final schedule = <String>[];
    
    // Horarios basados en el tipo de hábito y contexto
    if (habit.categoryId == 'Alimentación') {
      if (mealContext == 'before_meal') {
        schedule.addAll(['07:30', '11:30', '18:30']);
      } else if (mealContext == 'after_meal') {
        schedule.addAll(['08:30', '12:30', '19:30']);
      } else {
        schedule.addAll(['08:00', '12:00', '19:00']);
      }
    } else if (habit.categoryId == 'Hidratación') {
      if (urgency == 'high') {
        schedule.addAll(['08:00', '10:00', '12:00', '14:00', '16:00', '18:00']);
      } else {
        schedule.addAll(['09:00', '12:00', '15:00', '18:00']);
      }
    } else if (habit.categoryId == 'Medicación') {
      if (symptoms.contains('pain') && urgency == 'high') {
        schedule.addAll(['08:00', '14:00', '20:00']);
      } else {
        schedule.addAll(['08:00', '20:00']);
      }
    } else if (habit.categoryId == 'Ejercicio') {
      if (timeOfDay == 'morning') {
        schedule.add('07:00');
      } else if (timeOfDay == 'evening') {
        schedule.add('18:00');
      } else {
        schedule.add('17:00');
      }
    }
    
    return schedule.isEmpty ? ['09:00'] : schedule;
  }
  
  /// Genera descripción contextual para el hábito
  String _generateContextualDescription(Habit habit, Map<String, dynamic> context) {
    final symptoms = context['symptoms'] as List<String>;
    final urgency = context['urgency'] as String;
    final mealContext = context['mealContext'] as String?;
    
    var description = habit.description;
    
    // Agregar contexto específico según síntomas
    if (symptoms.contains('pain')) {
      description += ' Especialmente importante para aliviar el dolor.';
    }
    if (symptoms.contains('acidity')) {
      description += ' Ayuda a reducir la acidez estomacal.';
    }
    if (symptoms.contains('inflammation')) {
      description += ' Contribuye a reducir la inflamación.';
    }
    
    // Agregar contexto de urgencia
    if (urgency == 'high') {
      description += ' ⚠️ Prioritario para tu bienestar.';
    }
    
    // Agregar contexto de comidas
    if (mealContext != null) {
      switch (mealContext) {
        case 'before_meal':
          description += ' Realizar antes de las comidas.';
          break;
        case 'after_meal':
          description += ' Realizar después de las comidas.';
          break;
        case 'during_meal':
          description += ' Practicar durante las comidas.';
          break;
      }
    }
    
    return description;
  }
  
  /// Genera sugerencias de recordatorios personalizados
  List<String> _generateReminderSuggestions(Habit habit, Map<String, dynamic> context) {
    final suggestions = <String>[];
    final urgency = context['urgency'] as String;
    final symptoms = context['symptoms'] as List<String>;
    
    if (urgency == 'high') {
      suggestions.add('Recordatorio cada 2 horas');
    }
    
    if (symptoms.contains('pain')) {
      suggestions.add('Recordatorio cuando sientas dolor');
    }
    
    if (habit.categoryId == 'Alimentación') {
      suggestions.add('Recordatorio 30 min antes de comer');
    }
    
    if (habit.categoryId == 'Hidratación') {
      suggestions.add('Recordatorio cada 3 horas');
    }
    
    return suggestions;
  }
  
  /// Selecciona icono contextual para el hábito
  String _selectContextualIcon(Habit habit, Map<String, dynamic> context) {
    final urgency = context['urgency'] as String;
    final symptoms = context['symptoms'] as List<String>;
    
    if (urgency == 'high') {
      return 'alert-circle';
    }
    
    if (symptoms.contains('pain')) {
      return 'heart-pulse';
    }
    
    // Iconos por categoría
    switch (habit.categoryId) {
      case 'Alimentación':
        return 'utensils';
      case 'Hidratación':
        return 'droplets';
      case 'Ejercicio':
        return 'activity';
      case 'Medicación':
        return 'pill';
      case 'Descanso':
        return 'moon';
      case 'Bienestar Mental':
        return 'brain';
      default:
        return 'target';
    }
  }
  
  /// Selecciona color contextual para el hábito
  String _selectContextualColor(Habit habit, Map<String, dynamic> context) {
    final urgency = context['urgency'] as String;
    final symptoms = context['symptoms'] as List<String>;
    
    if (urgency == 'high') {
      return '#F44336'; // Rojo para urgente
    }
    
    if (symptoms.contains('pain')) {
      return '#FF9800'; // Naranja para dolor
    }
    
    // Colores por categoría
    switch (habit.categoryId) {
      case 'Alimentación':
        return '#4CAF50'; // Verde
      case 'Hidratación':
        return '#2196F3'; // Azul
      case 'Ejercicio':
        return '#FF5722'; // Naranja rojizo
      case 'Medicación':
        return '#9C27B0'; // Púrpura
      case 'Descanso':
        return '#3F51B5'; // Índigo
      case 'Bienestar Mental':
        return '#00BCD4'; // Cian
      default:
        return '#607D8B'; // Gris azulado
    }
  }

}