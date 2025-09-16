import 'package:vive_good_app/core/error/failures.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

abstract class GeminiAIDataSource {
  Future<Map<String, dynamic>> generateHabitSuggestions({
    required String habitName,
    String? category,
    String? description,
    String? userGoals,
  });

  Future<List<String>> generateScheduleSuggestions({
    required String habitName,
    String? category,
    String? userPreferences,
  });
}

class GeminiAIDataSourceImpl implements GeminiAIDataSource {
  late final GenerativeModel _model;

  GeminiAIDataSourceImpl() {
    // Try to get API key from environment first, then use fallback
    const apiKey = String.fromEnvironment('GOOGLE_API_KEY');
    String finalApiKey = apiKey;

    // If environment variable is not set, use the configured API key
    if (apiKey.isEmpty) {
      finalApiKey = 'AIzaSyAXlDOJOXjApYsIhoaj_iiogc3RBXEl2v4';
    }

    if (finalApiKey.isEmpty) {
      throw Exception('GOOGLE_API_KEY is not configured');
    }

    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: finalApiKey);
  }

  @override
  Future<Map<String, dynamic>> generateHabitSuggestions({
    required String habitName,
    String? category,
    String? description,
    String? userGoals,
  }) async {
    try {
      final prompt = _buildHabitSuggestionsPrompt(
        habitName: habitName,
        category: category,
        description: description,
        userGoals: userGoals,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw ServerFailure('No response from Gemini AI');
      }

      // Clean and parse the JSON response
      String cleanedResponse = response.text!.trim();

      // Remove any markdown code blocks if present
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse
            .replaceFirst('```json', '')
            .replaceFirst('```', '');
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse
            .replaceFirst('```', '')
            .replaceFirst('```', '');
      }

      cleanedResponse = cleanedResponse.trim();

      if (cleanedResponse.isEmpty) {
        throw ServerFailure('Empty response after cleaning');
      }

      try {
        final jsonResponse = jsonDecode(cleanedResponse);
        return jsonResponse as Map<String, dynamic>;
      } catch (jsonError) {
        // If JSON parsing fails, return a default structure
        return {
          'optimizedName': habitName,
          'suggestedDuration': '15',
          'bestTimes': ['09:00'],
          'difficulty': 'medio',
          'tips': ['Mantén la consistencia'],
          'frequency': 'diario',
          'motivation': 'Cada pequeño paso cuenta hacia tu objetivo',
        };
      }
    } catch (e) {
      throw ServerFailure(
        'Error generating habit suggestions: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<String>> generateScheduleSuggestions({
    required String habitName,
    String? category,
    String? userPreferences,
  }) async {
    try {
      final prompt = _buildScheduleSuggestionsPrompt(
        habitName: habitName,
        category: category,
        userPreferences: userPreferences,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw ServerFailure('No response from Gemini AI');
      }

      // Parse the response as a list of suggestions
      final lines = response.text!
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^[\d\-\*\•]\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return lines;
    } catch (e) {
      throw ServerFailure(
        'Error generating schedule suggestions: ${e.toString()}',
      );
    }
  }

  String _buildHabitSuggestionsPrompt({
    required String habitName,
    String? category,
    String? description,
    String? userGoals,
  }) {
    return '''
Actúa como un experto en formación de hábitos y bienestar personal. 
Genera sugerencias detalladas para el siguiente hábito:

Nombre del hábito: $habitName
Categoría: ${category ?? 'No especificada'}
Descripción: ${description ?? 'No especificada'}
Objetivos del usuario: ${userGoals ?? 'No especificados'}

Por favor, proporciona una respuesta en formato JSON con la siguiente estructura:
{
  "optimizedName": "Nombre optimizado del hábito",
  "suggestedDuration": "Duración recomendada en minutos",
  "bestTimes": ["Lista de mejores horarios para realizar el hábito"],
  "difficulty": "fácil|medio|difícil",
  "tips": ["Lista de consejos para mantener el hábito"],
  "frequency": "Frecuencia recomendada (diario, semanal, etc.)",
  "motivation": "Mensaje motivacional personalizado"
}

Asegúrate de que la respuesta sea únicamente JSON válido, sin texto adicional.''';
  }

  String _buildScheduleSuggestionsPrompt({
    required String habitName,
    String? category,
    String? userPreferences,
  }) {
    return '''
Actúa como un experto en productividad y gestión del tiempo.
Genera 5 sugerencias de horarios específicos para el siguiente hábito:

Nombre del hábito: $habitName
Categoría: ${category ?? 'No especificada'}
Preferencias del usuario: ${userPreferences ?? 'No especificadas'}

Proporciona horarios específicos en formato de 24 horas (ej: "07:00 - Ideal para empezar el día con energía").
Cada sugerencia debe incluir el horario y una breve explicación del por qué es recomendable.

Formato de respuesta:
- HH:MM - Explicación breve
- HH:MM - Explicación breve
- HH:MM - Explicación breve
- HH:MM - Explicación breve
- HH:MM - Explicación breve''';
  }
}
