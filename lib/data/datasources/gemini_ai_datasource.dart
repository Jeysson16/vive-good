import 'package:vive_good_app/core/error/failures.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

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
      finalApiKey = 'AIzaSyAJ0SdbXQTyxjQ9IpPjKD97rNzFB2zJios';
    }

    if (finalApiKey.isEmpty) {
      throw Exception('GOOGLE_API_KEY is not configured');
    }

    _model = GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: finalApiKey);
  }

  @override
  Future<Map<String, dynamic>> generateHabitSuggestions({
    required String habitName,
    String? category,
    String? description,
    String? userGoals,
  }) async {
    developer.log('🤖 Iniciando generación de sugerencias para hábito: $habitName');
    
    try {
      // Validar conectividad a internet
      await _validateInternetConnection();
      
      final prompt = _buildHabitSuggestionsPrompt(
        habitName: habitName,
        category: category,
        description: description,
        userGoals: userGoals,
      );

      developer.log('📝 Enviando prompt a Gemini AI...');
      final content = [Content.text(prompt)];
      
      // Agregar timeout de 30 segundos
      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ServerFailure('Timeout: La IA no respondió en 30 segundos. Verifica tu conexión.');
        },
      );

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
      developer.log('❌ Error en generateHabitSuggestions: $e', name: 'GeminiAI');
      
      // Manejo específico de errores de Gemini
      if (e is ServerException) {
        final errorMessage = e.message ?? e.toString();
        
        if (errorMessage.contains('quota') || errorMessage.contains('QUOTA_EXCEEDED')) {
          throw ServerFailure('La cuota de la API de Gemini se ha agotado. Intenta más tarde o verifica tu plan de facturación.');
        } else if (errorMessage.contains('API_KEY_INVALID')) {
          throw ServerFailure('La clave de API de Gemini es inválida. Verifica la configuración.');
        } else if (errorMessage.contains('PERMISSION_DENIED')) {
          throw ServerFailure('Sin permisos para usar la API de Gemini. Verifica tu cuenta.');
        } else if (errorMessage.contains('not found') || errorMessage.contains('not supported')) {
          throw ServerFailure('El modelo de Gemini no está disponible. Contacta al soporte.');
        } else if (errorMessage.contains('UNAVAILABLE') || errorMessage.contains('503')) {
          throw ServerFailure('El servicio de Gemini está temporalmente no disponible. Intenta en unos minutos.');
        }
      }
      
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        throw ServerFailure('Error de conexión. Verifica tu internet e intenta de nuevo.');
      }
      
      if (e is ServerFailure) {
        throw e; // Re-lanzar ServerFailure ya formateados
      }
      
      throw ServerFailure(
        'Error inesperado al generar sugerencias: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<String>> generateScheduleSuggestions({
    required String habitName,
    String? category,
    String? userPreferences,
  }) async {
    developer.log('🕐 Iniciando generación de horarios para: $habitName');
    
    try {
      // Validar conectividad a internet
      await _validateInternetConnection();
      
      final prompt = _buildScheduleSuggestionsPrompt(
        habitName: habitName,
        category: category,
        userPreferences: userPreferences,
      );

      developer.log('📝 Enviando prompt de horarios a Gemini AI...');
      final content = [Content.text(prompt)];
      
      // Agregar timeout de 30 segundos
      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ServerFailure('Timeout: La IA no respondió en 30 segundos. Verifica tu conexión.');
        },
      );

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
      developer.log('❌ Error en generateScheduleSuggestions: $e', name: 'GeminiAI');
      
      // Manejo específico de errores de Gemini
      if (e is ServerException) {
        final errorMessage = e.message ?? e.toString();
        
        if (errorMessage.contains('quota') || errorMessage.contains('QUOTA_EXCEEDED')) {
          throw ServerFailure('La cuota de la API de Gemini se ha agotado. Intenta más tarde o verifica tu plan de facturación.');
        } else if (errorMessage.contains('API_KEY_INVALID')) {
          throw ServerFailure('La clave de API de Gemini es inválida. Verifica la configuración.');
        } else if (errorMessage.contains('PERMISSION_DENIED')) {
          throw ServerFailure('Sin permisos para usar la API de Gemini. Verifica tu cuenta.');
        } else if (errorMessage.contains('not found') || errorMessage.contains('not supported')) {
          throw ServerFailure('El modelo de Gemini no está disponible. Contacta al soporte.');
        } else if (errorMessage.contains('UNAVAILABLE') || errorMessage.contains('503')) {
          throw ServerFailure('El servicio de Gemini está temporalmente no disponible. Intenta en unos minutos.');
        }
      }
      
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        throw ServerFailure('Error de conexión. Verifica tu internet e intenta de nuevo.');
      }
      
      if (e is ServerFailure) {
        throw e; // Re-lanzar ServerFailure ya formateados
      }
      
      throw ServerFailure(
        'Error inesperado al generar horarios: ${e.toString()}',
      );
    }
  }

  /// Valida la conectividad a internet antes de hacer llamadas a la API
  Future<void> _validateInternetConnection() async {
    try {
      developer.log('🌐 Verificando conectividad a internet...');
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 10),
      );
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        developer.log('✅ Conectividad a internet confirmada');
      } else {
        throw ServerFailure('Sin conexión a internet. Verifica tu red.');
      }
    } catch (e) {
      developer.log('❌ Error de conectividad: $e');
      throw ServerFailure('Sin conexión a internet. Verifica tu red e intenta de nuevo.');
    }
  }

  String _buildHabitSuggestionsPrompt({
    required String habitName,
    String? category,
    String? description,
    String? userGoals,
  }) {
    return '''
Experto en hábitos. Genera JSON para:
Hábito: $habitName
Categoría: ${category ?? 'General'}
Descripción: ${description ?? 'N/A'}
Objetivos: ${userGoals ?? 'N/A'}

Respuesta JSON:
{
  "optimizedName": "nombre optimizado",
  "suggestedDuration": "minutos",
  "bestTimes": ["horarios"],
  "difficulty": "fácil|medio|difícil",
  "tips": ["consejos breves"],
  "frequency": "frecuencia",
  "motivation": "mensaje corto"
}

Solo JSON válido.''';
  }

  String _buildScheduleSuggestionsPrompt({
    required String habitName,
    String? category,
    String? userPreferences,
  }) {
    return '''
Genera 5 horarios para: $habitName
Categoría: ${category ?? 'General'}
Preferencias: ${userPreferences ?? 'N/A'}

Formato:
- HH:MM - Razón breve
- HH:MM - Razón breve
- HH:MM - Razón breve
- HH:MM - Razón breve
- HH:MM - Razón breve''';
  }
}
