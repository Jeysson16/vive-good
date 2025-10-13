import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

/// Servicio para procesar respuestas estructuradas de Gemini
class GeminiResponseProcessorService {
  final HabitRepository _habitRepository;

  GeminiResponseProcessorService({
    required HabitRepository habitRepository,
  })  : _habitRepository = habitRepository;

  /// Procesa una respuesta estructurada de Gemini
  Future<Either<Failure, GeminiProcessedResponse>> processGeminiResponse(
    String geminiResponse,
    String userId,
  ) async {
    try {
      // Extraer JSON de la respuesta
      final jsonResponse = _extractJsonFromResponse(geminiResponse);
      if (jsonResponse == null) {
        return Left(ServerFailure('No se pudo extraer JSON válido de la respuesta de Gemini'));
      }

      final parsedResponse = json.decode(jsonResponse) as Map<String, dynamic>;
      
      // Procesar acciones
      final actions = parsedResponse['actions'] as Map<String, dynamic>?;
      final processedActions = <String, dynamic>{};

      if (actions != null) {
        // Procesar completado de hábitos
        if (actions.containsKey('habit_completion')) {
          final completion = await _processHabitCompletion(
            actions['habit_completion'] as Map<String, dynamic>,
            userId,
          );
          processedActions['habit_completion'] = completion;
        }

        // Procesar modificación de hábitos
        if (actions.containsKey('habit_modification')) {
          final modification = await _processHabitModification(
            actions['habit_modification'] as Map<String, dynamic>,
            userId,
          );
          processedActions['habit_modification'] = modification;
        }

        // Procesar nuevos hábitos sugeridos
        if (actions.containsKey('new_habits')) {
          final newHabits = await _processNewHabits(
            actions['new_habits'] as List<dynamic>,
            userId,
          );
          processedActions['new_habits'] = newHabits;
        }
      }

      return Right(GeminiProcessedResponse(
        message: parsedResponse['message'] as String? ?? '',
        actions: processedActions,
        methodologyApplied: parsedResponse['methodology_applied'] as String? ?? '',
      ));

    } catch (e) {
      return Left(ServerFailure('Error procesando respuesta de Gemini: $e'));
    }
  }

  /// Extrae JSON de la respuesta de Gemini
  String? _extractJsonFromResponse(String response) {
    try {
      // Buscar el primer { y el último }
      final startIndex = response.indexOf('{');
      final lastIndex = response.lastIndexOf('}');
      
      if (startIndex != -1 && lastIndex != -1 && lastIndex > startIndex) {
        return response.substring(startIndex, lastIndex + 1);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Procesa el completado de hábitos
  Future<Map<String, dynamic>> _processHabitCompletion(
    Map<String, dynamic> completion,
    String userId,
  ) async {
    try {
      final habitId = completion['habit_id'] as String?;
      final status = completion['status'] as String?;
      final percentage = completion['completion_percentage'] as int?;
      final notes = completion['notes'] as String?;

      if (habitId != null && status != null && status != 'none') {
        // Registrar el completado del hábito
        final result = await _habitRepository.logHabitCompletion(
          habitId,
          DateTime.now(),
        );

        return result.fold(
          (failure) => {
            'success': false,
            'error': failure.toString(),
          },
          (success) => {
            'success': true,
            'habit_id': habitId,
            'status': status,
            'percentage': percentage,
            'notes': notes,
          },
        );
      }

      return {
        'success': false,
        'reason': 'No hay hábito válido para completar',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Procesa la modificación de hábitos
  Future<Map<String, dynamic>> _processHabitModification(
    Map<String, dynamic> modification,
    String userId,
  ) async {
    try {
      final habitId = modification['habit_id'] as String?;
      final action = modification['action'] as String?;
      final suggestion = modification['suggestion'] as String?;
      final methodology = modification['methodology'] as String?;

      if (habitId != null && action != null) {
        // Aquí se implementaría la lógica específica para cada tipo de modificación
        switch (action) {
          case 'extend':
            // Extender la duración del hábito
            return {
              'success': true,
              'action': 'extend',
              'habit_id': habitId,
              'suggestion': suggestion,
              'methodology': methodology,
              'requires_user_confirmation': true,
            };
          case 'adjust_frequency':
            // Ajustar la frecuencia del hábito
            return {
              'success': true,
              'action': 'adjust_frequency',
              'habit_id': habitId,
              'suggestion': suggestion,
              'methodology': methodology,
              'requires_user_confirmation': true,
            };
          case 'modify_schedule':
            // Modificar el horario del hábito
            return {
              'success': true,
              'action': 'modify_schedule',
              'habit_id': habitId,
              'suggestion': suggestion,
              'methodology': methodology,
              'requires_user_confirmation': true,
            };
        }
      }

      return {
        'success': false,
        'reason': 'Modificación no válida',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Procesa nuevos hábitos sugeridos
  Future<List<Map<String, dynamic>>> _processNewHabits(
    List<dynamic> newHabits,
    String userId,
  ) async {
    final processedHabits = <Map<String, dynamic>>[];

    for (final habitData in newHabits) {
      if (habitData is Map<String, dynamic>) {
        try {
          final name = habitData['name'] as String?;
          final description = habitData['description'] as String?;
          final frequency = habitData['frequency'] as String?;
          final methodology = habitData['methodology'] as String?;

          if (name != null && description != null) {
            processedHabits.add({
              'name': name,
              'description': description,
              'frequency': frequency ?? 'daily',
              'methodology': methodology ?? 'atomic_habits',
              'suggested': true,
              'requires_user_confirmation': true,
            });
          }
        } catch (e) {
          // Continuar con el siguiente hábito si hay error
          continue;
        }
      }
    }

    return processedHabits;
  }
}

/// Clase para representar una respuesta procesada de Gemini
class GeminiProcessedResponse {
  final String message;
  final Map<String, dynamic> actions;
  final String methodologyApplied;

  GeminiProcessedResponse({
    required this.message,
    required this.actions,
    required this.methodologyApplied,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'actions': actions,
    'methodology_applied': methodologyApplied,
  };
}