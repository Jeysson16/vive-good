import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/assistant/assistant_response.dart';
import '../../../domain/entities/chat/chat_message.dart';
import 'deep_learning_datasource.dart';
import '../../../domain/entities/deep_learning_analysis.dart';
import '../../models/assistant/assistant_response_model.dart';
import '../../services/habit_auto_creation_service.dart';
import '../../services/gemini_response_processor_service.dart';
import '../../../core/config/app_config.dart';

class GeminiAssistantDatasource {
  final String _apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final http.Client _httpClient;
  final DeepLearningDatasource? _deepLearningDatasource;
  final HabitAutoCreationService _habitAutoCreationService;
  final GeminiResponseProcessorService? _responseProcessor;
  final Uuid _uuid = const Uuid();

  GeminiAssistantDatasource({
    String? apiKey,
    http.Client? httpClient,
    DeepLearningDatasource? deepLearningDatasource,
    required HabitAutoCreationService habitAutoCreationService,
    GeminiResponseProcessorService? responseProcessor,
  }) : _apiKey = apiKey ?? AppConfig.geminiApiKey,
       _httpClient = httpClient ?? http.Client(),
       _deepLearningDatasource = deepLearningDatasource,
       _habitAutoCreationService = habitAutoCreationService,
       _responseProcessor = responseProcessor;

  Future<AssistantResponseModel> sendMessage({
    required String message,
    required String userId,
    required List<ChatMessage> conversationHistory,
    String? sessionId,
    bool isInitialResponse = false,
  }) async {
    try {
      // Decidir qué tipo de respuesta generar basado en isInitialResponse
      String geminiResponse;
      bool geminiAvailable = true;

      try {
        if (isInitialResponse) {
          // Generar respuesta inicial rápida
          print('🚀 Generando respuesta inicial rápida...');
          geminiResponse = await _getInitialGeminiResponse(
            message,
            userId,
            conversationHistory,
          );
        } else {
          // Para respuesta completa, primero obtener análisis de deep learning
          print('🔍 Obteniendo análisis de deep learning antes de Gemini...');
          Map<String, dynamic>? deepLearningAnalysis;

          try {
            if (_deepLearningDatasource != null) {
              deepLearningAnalysis = await _deepLearningDatasource
                  .analyzeMedicalSymptoms(
                    message: message,
                    userId: userId,
                    additionalContext: {
                      'conversation_history': conversationHistory
                          .take(3)
                          .map(
                            (msg) => {
                              'type': msg.type.toString(),
                              'content': msg.content,
                              'timestamp': msg.createdAt.toIso8601String(),
                            },
                          )
                          .toList(),
                      'session_id': sessionId,
                    },
                  )
                  .timeout(const Duration(seconds: 10));
              print('✅ Análisis de deep learning obtenido exitosamente');
            }
          } catch (e) {
            print('⚠️ Error obteniendo análisis de deep learning: $e');
            // Continuar sin análisis de deep learning
          }

          // Generar respuesta completa con análisis de deep learning
          geminiResponse = await _getGeminiResponse(
            message,
            userId,
            conversationHistory,
            deepLearningAnalysis: deepLearningAnalysis,
          );
        }
        print('✅ Respuesta de Gemini obtenida exitosamente');
      } catch (e) {
        print('❌ Error en API de Gemini: $e');
        geminiAvailable = false;
        if (isInitialResponse) {
          geminiResponse = _createInitialFallbackResponse(message);
        } else {
          geminiResponse = _createGeminiFallbackResponse(
            message,
            userId,
            e.toString(),
          );
        }
      }

      // CAMBIO: Devolver SOLO la respuesta de Gemini primero
      // El Deep Learning se procesará en segundo plano desde assistant_bloc.dart
      print(
        '🔥 DEBUG: Devolviendo respuesta de Gemini sin Deep Learning para procesamiento inmediato',
      );

      // Procesar respuesta estructurada de Gemini si está disponible el procesador
      String finalMessage = geminiResponse;
      Map<String, dynamic> processedActions = {};
      List<Map<String, dynamic>> suggestedHabits = [];

      if (_responseProcessor != null) {
        try {
          print('🔥 DEBUG: Procesando respuesta estructurada de Gemini');
          final processedResponse = await _responseProcessor
              .processGeminiResponse(geminiResponse, userId);

          processedResponse.fold(
            (failure) {
              print('❌ Error procesando respuesta estructurada: $failure');
              // Usar respuesta original como fallback
              finalMessage = _formatGeminiResponse(geminiResponse);
            },
            (processed) {
              print('✅ Respuesta estructurada procesada exitosamente');
              finalMessage = processed.message;
              processedActions = processed.actions;

              // Extraer hábitos sugeridos de las acciones procesadas
              if (processedActions.containsKey('new_habits')) {
                suggestedHabits = List<Map<String, dynamic>>.from(
                  processedActions['new_habits'] as List<dynamic>,
                );
              }
            },
          );
        } catch (e) {
          print('❌ Error en procesamiento estructurado: $e');
          finalMessage = _formatGeminiResponse(geminiResponse);
        }
      } else {
        // Fallback al procesamiento tradicional
        finalMessage = _formatGeminiResponse(geminiResponse);

        // Crear objeto AssistantResponse temporal para creación de hábitos
        final tempResponse = AssistantResponseModel(
          id: _uuid.v4(),
          sessionId: sessionId ?? '',
          content: finalMessage,
          type: ResponseType.text,
          timestamp: DateTime.now(),
        );

        // Extraer hábitos sugeridos para mostrar en desplegable (sin crear automáticamente)
        try {
          print(
            '🔥 DEBUG GEMINI: Iniciando extracción de hábitos sugeridos (método tradicional)',
          );

          final extractedHabits = await _habitAutoCreationService
              .extractSuggestedHabits(
                assistantResponse: tempResponse,
                userMessage: message,
                userId: userId,
              );
          suggestedHabits = extractedHabits
              .map((habit) => habit.toMap())
              .toList();

          print(
            '🔥 DEBUG GEMINI: Se extrajeron ${suggestedHabits.length} hábitos sugeridos para desplegable',
          );
        } catch (e) {
          print('🔥 ERROR GEMINI: Error extracting suggested habits: $e');
        }
      }

      return AssistantResponseModel(
        id: _uuid.v4(),
        sessionId: sessionId ?? '',
        content: finalMessage,
        type: ResponseType.text,
        timestamp: DateTime.now(),
        confidence: 0.8, // Confianza base de Gemini
        suggestions: [], // Se llenarán con Deep Learning en segundo plano
        extractedHabits: _extractHabitsFromResponse(finalMessage),
        analysisData: null, // Se llenará con Deep Learning en segundo plano
        suggestedHabits: suggestedHabits,
        dlChatResponse: null, // Se llenará con Deep Learning en segundo plano
        processedActions: processedActions, // Acciones procesadas de Gemini
      );
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  Future<AssistantResponseModel> processVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      // Primero convertir audio a texto (esto requeriría integración con Speech-to-Text)
      final transcribedText = await _speechToText(audioPath);

      // Luego procesar el texto con Gemini
      return await sendMessage(
        message: transcribedText,
        userId: userId,
        conversationHistory: conversationHistory ?? [],
      );
    } catch (e) {
      throw Exception('Error al procesar mensaje de voz: $e');
    }
  }

  /// Procesa Deep Learning por separado y devuelve el análisis
  Future<Map<String, dynamic>> processDeepLearningAnalysis({
    required String message,
    required String userId,
    String? sessionId,
  }) async {
    try {
      print('🔥 DEBUG: ===== INICIANDO PROCESAMIENTO DE DEEP LEARNING =====');

      // Obtener respuesta del backend de deep learning con manejo robusto de errores
      Map<String, dynamic>? dlChatResponse;
      DeepLearningAnalysis? deepLearningAnalysis;
      Map<String, dynamic>? medicalAnalysis;
      bool dlServiceAvailable = false;

      if (_deepLearningDatasource != null) {
        // Verificar salud del servicio primero
        try {
          dlServiceAvailable = await _deepLearningDatasource
              .checkModelHealth();
          print(
            '🔍 Estado del servicio Deep Learning: ${dlServiceAvailable ? "Disponible" : "No disponible"}',
          );
        } catch (e) {
          print('⚠️ Error verificando salud del servicio DL: $e');
          dlServiceAvailable = false;
        }

        // Intentar obtener respuesta de chat si el servicio está disponible
        if (dlServiceAvailable) {
          try {
            dlChatResponse = await _getDeepLearningChatResponse(
              message,
              userId,
              sessionId,
            );
            print('✅ Respuesta de chat DL obtenida exitosamente');
          } catch (e) {
            print('❌ Error en chat de deep learning: $e');
            // Crear respuesta de fallback con contexto del error
            dlChatResponse = _createEnhancedFallbackResponse(
              message,
              userId,
              e.toString(),
            );
          }
        } else {
          // Crear respuesta de fallback cuando el servicio no está disponible
          dlChatResponse = _createEnhancedFallbackResponse(
            message,
            userId,
            'Servicio no disponible',
          );
        }

        // Intentar obtener análisis médico usando el nuevo endpoint
        if (dlServiceAvailable) {
          try {
            medicalAnalysis = await _deepLearningDatasource
                .analyzeMedicalSymptoms(
                  message: message,
                  userId: userId,
                  additionalContext: {
                    'session_id': sessionId,
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
            print('✅ Análisis médico obtenido exitosamente');

            // Convertir análisis médico a formato legacy si es necesario
            deepLearningAnalysis = _convertMedicalAnalysisToLegacy(
              medicalAnalysis,
            );
                    } catch (e) {
            print('❌ Error en análisis médico: $e');
            // Continuar sin análisis pero registrar el error para métricas
            _logDeepLearningError('medical_analysis', e.toString());
          }
        }
      } else {
        print('⚠️ Deep Learning datasource no configurado');
        // Crear respuesta básica cuando no hay datasource configurado
        dlChatResponse = _createEnhancedFallbackResponse(
          message,
          userId,
          'Servicio no configurado',
        );
      }

      print('🔥 DEBUG: ===== DEEP LEARNING PROCESAMIENTO COMPLETADO =====');

      return {
        'dlChatResponse': dlChatResponse,
        'deepLearningAnalysis': deepLearningAnalysis,
        'medicalAnalysis': medicalAnalysis ?? {},
        'serviceAvailable': dlServiceAvailable,
      };
    } catch (e) {
      print('❌ Error en procesamiento de Deep Learning: $e');
      return {
        'dlChatResponse': null,
        'deepLearningAnalysis': null,
        'medicalAnalysis': null,
        'serviceAvailable': false,
        'error': e.toString(),
      };
    }
  }

  /// Genera respuesta inicial rápida de Gemini para mostrar mientras se procesa deep learning
  Future<AssistantResponseModel> generateInitialResponse({
    required String message,
    required String userId,
    required List<ChatMessage> conversationHistory,
    String? sessionId,
  }) async {
    try {
      print('🚀 [GEMINI] Generando respuesta inicial rápida...');

      // Prompt optimizado para respuesta rápida
      final quickPrompt =
          '''
Eres un asistente especializado en prevención de gastritis para estudiantes universitarios.

Mensaje del usuario: "$message"

Proporciona una respuesta inicial breve y útil (máximo 2-3 párrafos) que:
1. Reconozca el mensaje del usuario
2. Ofrezca consejos generales inmediatos sobre prevención de gastritis
3. Indique que se está analizando más información para dar recomendaciones personalizadas

Mantén un tono empático y profesional. Enfócate en estudiantes universitarios.
''';

      final response = await _httpClient.post(
        Uri.parse(
          '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': quickPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 300, // Limitado para respuesta rápida
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        print('✅ [GEMINI] Respuesta inicial generada exitosamente');

        return AssistantResponseModel(
          id: _uuid.v4(),
          sessionId: sessionId ?? '',
          content: content,
          type: ResponseType.text,
          timestamp: DateTime.now(),
          confidence: 0.7, // Confianza menor para respuesta inicial
          suggestions: [],
          extractedHabits: [],
          analysisData: null,
          suggestedHabits: [],
          dlChatResponse: null,
          processedActions: {},
          isInitialResponse:
              true, // Marcador para identificar respuesta inicial
        );
      } else {
        throw Exception('Error en API de Gemini: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [GEMINI] Error generando respuesta inicial: $e');

      // Fallback para respuesta inicial
      return AssistantResponseModel(
        id: _uuid.v4(),
        sessionId: sessionId ?? '',
        content: _createInitialFallbackResponse(message),
        type: ResponseType.text,
        timestamp: DateTime.now(),
        confidence: 0.5,
        suggestions: [],
        extractedHabits: [],
        analysisData: null,
        suggestedHabits: [],
        dlChatResponse: null,
        processedActions: {},
        isInitialResponse: true,
      );
    }
  }

  /// Genera respuesta completa integrando análisis de deep learning
  Future<AssistantResponseModel> generateEnhancedResponse({
    required String message,
    required String userId,
    required List<ChatMessage> conversationHistory,
    required Map<String, dynamic> deepLearningData,
    String? sessionId,
    String? initialResponse,
  }) async {
    try {
      print('🧠 [GEMINI] Generando respuesta mejorada con deep learning...');

      // Extraer datos del análisis de deep learning
      final dlAnalysis = deepLearningData['dlChatResponse'];
      final medicalAnalysis = deepLearningData['medicalAnalysis'];
      final serviceAvailable = deepLearningData['serviceAvailable'] ?? false;

      String enhancedPrompt;

      if (serviceAvailable && dlAnalysis != null) {
        // Prompt con integración de deep learning
        enhancedPrompt =
            '''
Eres un asistente especializado en prevención de gastritis para estudiantes universitarios.

Mensaje del usuario: "$message"

ANÁLISIS MÉDICO DISPONIBLE:
${_formatMedicalAnalysisForPrompt(medicalAnalysis)}

RESPUESTA INICIAL PREVIA: "$initialResponse"

Genera una respuesta completa y personalizada que:
1. Integre el análisis médico proporcionado
2. Proporcione recomendaciones específicas basadas en los síntomas detectados
3. Incluya consejos dietéticos y de estilo de vida personalizados
4. Mantenga coherencia con la respuesta inicial
5. Enfoque en prevención de gastritis para estudiantes universitarios

Estructura la respuesta de manera clara y profesional.
''';
      } else {
        // Prompt sin deep learning (fallback)
        enhancedPrompt =
            '''
Eres un asistente especializado en prevención de gastritis para estudiantes universitarios.

Mensaje del usuario: "$message"

RESPUESTA INICIAL PREVIA: "$initialResponse"

El análisis médico no está disponible temporalmente. Genera una respuesta completa que:
1. Amplíe la información de la respuesta inicial
2. Proporcione consejos detallados de prevención de gastritis
3. Incluya recomendaciones específicas para estudiantes universitarios
4. Ofrezca información sobre cuándo buscar atención médica

Mantén un enfoque profesional y empático.
''';
      }

      final response = await _httpClient.post(
        Uri.parse(
          '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': enhancedPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1000,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        print('✅ [GEMINI] Respuesta mejorada generada exitosamente');

        // Procesar respuesta para extraer hábitos sugeridos
        List<Map<String, dynamic>> suggestedHabits = [];
        Map<String, dynamic> processedActions = {};

        if (_responseProcessor != null) {
          try {
            final processedResponse = await _responseProcessor
                .processGeminiResponse(content, userId);

            processedResponse.fold(
              (failure) => print('❌ Error procesando respuesta: $failure'),
              (processed) {
                processedActions = processed.actions;
                if (processedActions.containsKey('new_habits')) {
                  suggestedHabits = List<Map<String, dynamic>>.from(
                    processedActions['new_habits'] as List<dynamic>,
                  );
                }
              },
            );
          } catch (e) {
            print('❌ Error en procesamiento: $e');
          }
        }

        return AssistantResponseModel(
          id: _uuid.v4(),
          sessionId: sessionId ?? '',
          content: content,
          type: ResponseType.text,
          timestamp: DateTime.now(),
          confidence: serviceAvailable ? 0.9 : 0.8,
          suggestions: [],
          extractedHabits: _extractHabitsFromResponse(content),
          analysisData: medicalAnalysis,
          suggestedHabits: suggestedHabits,
          dlChatResponse: dlAnalysis,
          processedActions: processedActions,
          isInitialResponse: false,
        );
      } else {
        throw Exception('Error en API de Gemini: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [GEMINI] Error generando respuesta mejorada: $e');
      throw Exception('Error al generar respuesta mejorada: $e');
    }
  }

  /// Formatea el análisis médico para incluir en el prompt de Gemini
  String _formatMedicalAnalysisForPrompt(Map<String, dynamic>? analysis) {
    if (analysis == null) return 'No disponible';

    final buffer = StringBuffer();

    if (analysis.containsKey('symptom_analysis')) {
      final symptoms = analysis['symptom_analysis'];
      buffer.writeln(
        'Síntomas detectados: ${symptoms['detected_symptoms']?.join(', ') ?? 'Ninguno'}',
      );
      buffer.writeln(
        'Nivel de severidad: ${symptoms['severity_level'] ?? 'No especificado'}',
      );
      buffer.writeln('Urgencia: ${symptoms['urgency'] ?? 'No especificada'}');
    }

    if (analysis.containsKey('recommendations')) {
      final recommendations = analysis['recommendations'];
      if (recommendations['dietary'] != null) {
        buffer.writeln(
          'Recomendaciones dietéticas: ${recommendations['dietary'].join(', ')}',
        );
      }
      if (recommendations['lifestyle'] != null) {
        buffer.writeln(
          'Recomendaciones de estilo de vida: ${recommendations['lifestyle'].join(', ')}',
        );
      }
    }

    if (analysis.containsKey('risk_assessment')) {
      final risk = analysis['risk_assessment'];
      buffer.writeln(
        'Nivel de riesgo: ${risk['risk_level'] ?? 'No especificado'}',
      );
      buffer.writeln('Seguimiento: ${risk['follow_up'] ?? 'No especificado'}');
    }

    return buffer.toString();
  }

  /// Crea respuesta de fallback para respuesta inicial
  String _createInitialFallbackResponse(String message) {
    return '''
Hola, he recibido tu mensaje sobre "$message".

Como asistente especializado en prevención de gastritis para estudiantes universitarios, puedo ayudarte con información y consejos generales.

Estoy analizando tu consulta para proporcionarte recomendaciones más específicas. Mientras tanto, recuerda que mantener horarios regulares de comida y evitar el estrés excesivo son fundamentales para prevenir la gastritis.

¿Hay algo específico sobre prevención de gastritis que te gustaría saber?
''';
  }

  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  }) async {
    try {
      final prompt =
          '''
Contexto: "$currentContext"

3 sugerencias para gastritis (máximo 4 palabras cada una):
Formato: sugerencia1, sugerencia2, sugerencia3''';

      final response = await _httpClient.post(
        Uri.parse(
          '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 100},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        return content
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(3)
            .toList();
      } else {
        return ['Beber más agua', 'Comer despacio', 'Reducir estrés'];
      }
    } catch (e) {
      // Sugerencias por defecto en caso de error
      return ['Beber más agua', 'Comer despacio', 'Reducir estrés'];
    }
  }

  Future<String> _buildPrompt({
    required String message,
    String? userId,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? deepLearningAnalysis,
  }) async {
    return 'Vive Good gastritis. "$message" - Consejos: máx 120 palabras.';
  }

  /// Verifica si el texto contiene alguna palabra clave
  bool _containsAnyKeyword(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  Future<String> _getGeminiResponse(
    String message,
    String userId,
    List<ChatMessage> conversationHistory, {
    Map<String, dynamic>? deepLearningAnalysis,
  }) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print(
          '🚀 Intento $attempt/$maxRetries - Enviando solicitud a Gemini API...',
        );

        final response = await _makeGeminiRequest(
          message,
          userId,
          conversationHistory,
          deepLearningAnalysis: deepLearningAnalysis,
        );
        return response;
      } catch (e) {
        print('❌ Intento $attempt falló: $e');

        if (attempt == maxRetries) {
          print('💥 Todos los intentos fallaron');
          rethrow;
        }

        // Solo reintentar en ciertos tipos de errores
        if (_shouldRetry(e)) {
          print(
            '⏳ Esperando ${retryDelay.inSeconds} segundos antes del siguiente intento...',
          );
          await Future.delayed(retryDelay);
        } else {
          print('🚫 Error no recuperable, no se reintentará');
          rethrow;
        }
      }
    }

    throw Exception('Error inesperado en el sistema de reintentos');
  }

  bool _shouldRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503');
  }

  /// Genera respuesta inicial rápida de Gemini optimizada para velocidad
  Future<String> _getInitialGeminiResponse(
    String message,
    String userId,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      print('🚀 Generando respuesta inicial rápida de Gemini...');

      // Prompt ultra-optimizado para reducir tokens
      final quickPrompt =
          'Asistente gastritis estudiantes. "$message" - Respuesta: máx 80 palabras, consejos básicos.';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': quickPrompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens':
              300, // Aumentado para dar espacio a los tokens internos de Gemini 2.5
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      // Log completo del request a Gemini
      print('🚀 ===== GEMINI REQUEST LOG COMPLETO =====');
      print('🔗 URL: $_baseUrl/models/gemini-2.0-flash-lite:generateContent');
      print('📝 PROMPT ENVIADO: "$quickPrompt"');
      print('⚙️ CONFIGURACIÓN:');
      final genConfig = requestBody['generationConfig'] as Map<String, dynamic>;
      final safetySettings = requestBody['safetySettings'] as List<dynamic>;
      print('   - temperature: ${genConfig['temperature']}');
      print('   - maxOutputTokens: ${genConfig['maxOutputTokens']}');
      print(
        '🛡️ SAFETY SETTINGS: ${safetySettings.length} categorías configuradas',
      );
      print('📦 REQUEST BODY COMPLETO:');
      print(jsonEncode(requestBody));
      print('🚀 ==========================================');

      final response = await _httpClient
          .post(
            Uri.parse(
              '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
          ); // Timeout más corto para respuesta rápida

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Respuesta completa de Gemini: ${response.body}');

        final geminiText =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (geminiText == null || geminiText.isEmpty) {
          print('❌ ERROR: Gemini devolvió respuesta vacía o nula');
          print('📄 Estructura de respuesta: $responseData');

          // Verificar si hay errores específicos en la respuesta
          if (responseData['candidates']?[0]?['finishReason'] == 'SAFETY') {
            print('⚠️ Respuesta bloqueada por filtros de seguridad');
            return 'Entiendo tu consulta. Como asistente especializado en prevención de gastritis, puedo ayudarte con recomendaciones generales de salud digestiva. ¿Podrías reformular tu pregunta para que pueda asistirte mejor?';
          }

          if (responseData['candidates']?[0]?['finishReason'] == 'MAX_TOKENS') {
            print(
              '⚠️ Respuesta truncada por límite de tokens - usando fallback mejorado',
            );
            // Respuesta de fallback específica y útil para gastritis
            return '''Hola, entiendo tu consulta sobre gastritis. Como estudiante universitario, es fundamental:

🍽️ **Alimentación**: Mantén horarios regulares, evita comidas picantes, grasosas y muy condimentadas.

⏰ **Rutina**: Come cada 3-4 horas, no saltees comidas por estudiar.

😌 **Estrés**: Practica técnicas de relajación durante épocas de exámenes.

¿Te gustaría consejos específicos sobre algún síntoma que estés experimentando?''';
          }

          if (responseData['error'] != null) {
            print('❌ Error específico de API: ${responseData['error']}');
            throw Exception(
              'Error de API de Gemini: ${responseData['error']['message']}',
            );
          }

          throw Exception('Gemini devolvió una respuesta vacía');
        }

        print(
          '✅ Respuesta inicial rápida generada: ${geminiText.length} caracteres',
        );
        return geminiText;
      } else {
        throw Exception('Error en API de Gemini: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error generando respuesta inicial: $e');
      throw Exception('Error al generar respuesta inicial: $e');
    }
  }

  Future<String> _makeGeminiRequest(
    String message,
    String userId,
    List<ChatMessage> conversationHistory, {
    Map<String, dynamic>? deepLearningAnalysis,
  }) async {
    final prompt = await _buildPrompt(
      message: message,
      userId: userId,
      conversationHistory: conversationHistory,
      deepLearningAnalysis: deepLearningAnalysis,
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens':
            500, // Aumentado para dar espacio a los tokens internos de Gemini 2.5
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    // Log completo del request a Gemini (método principal)
    print('🚀 ===== GEMINI REQUEST LOG COMPLETO (MÉTODO PRINCIPAL) =====');
    print('🔗 URL: $_baseUrl/models/gemini-2.0-flash-lite:generateContent');
    print('📝 PROMPT ENVIADO (${prompt.length} caracteres):');
    print('--- INICIO PROMPT ---');
    print(prompt);
    print('--- FIN PROMPT ---');
    print('⚙️ CONFIGURACIÓN:');
    final genConfig = requestBody['generationConfig'] as Map<String, dynamic>;
    final safetySettings = requestBody['safetySettings'] as List<dynamic>;
    print('   - temperature: ${genConfig['temperature']}');
    print('   - topK: ${genConfig['topK']}');
    print('   - topP: ${genConfig['topP']}');
    print('   - maxOutputTokens: ${genConfig['maxOutputTokens']}');
    print(
      '🛡️ SAFETY SETTINGS: ${safetySettings.length} categorías configuradas',
    );
    print('📦 REQUEST BODY COMPLETO:');
    print(jsonEncode(requestBody));
    print('🚀 ========================================================');

    try {
      print('📝 Prompt length: ${prompt.length} characters');
      print('🔑 API Key configured: ${_apiKey.isNotEmpty ? "Yes" : "No"}');

      final response = await _httpClient
          .post(
            Uri.parse(
              '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      print('📡 Gemini API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔍 DEBUG: Respuesta completa de Gemini: ${response.body}');

        final geminiText =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (geminiText == null || geminiText.isEmpty) {
          print('❌ ERROR: Gemini devolvió respuesta vacía o nula');
          print('📄 Estructura de respuesta: $responseData');

          // Verificar si hay errores específicos en la respuesta
          if (responseData['candidates']?[0]?['finishReason'] == 'SAFETY') {
            print('⚠️ Respuesta bloqueada por filtros de seguridad');
            return 'Entiendo tu consulta sobre salud digestiva. Como asistente especializado en prevención de gastritis, puedo ayudarte con recomendaciones generales. ¿Podrías reformular tu pregunta para que pueda asistirte mejor?';
          }

          if (responseData['candidates']?[0]?['finishReason'] == 'MAX_TOKENS') {
            print(
              '⚠️ Respuesta truncada por límite de tokens en respuesta completa - usando fallback mejorado',
            );
            // Respuesta de fallback más completa y estructurada para gastritis
            return '''Entiendo tu consulta sobre gastritis. Como estudiante universitario, aquí tienes recomendaciones clave:

## 🍽️ **Alimentación Saludable**
- Mantén horarios regulares de comida (cada 3-4 horas)
- Evita alimentos irritantes: picantes, grasosos, cítricos en exceso
- Incluye alimentos suaves: avena, plátano, arroz, pollo hervido

## ⏰ **Rutina Estudiantil**
- No saltees comidas por estudiar
- Lleva snacks saludables (galletas integrales, frutas)
- Evita el café en exceso, especialmente en ayunas

## 😌 **Manejo del Estrés**
- Practica técnicas de respiración durante exámenes
- Mantén un horario de sueño regular (7-8 horas)
- Haz pausas activas cada 2 horas de estudio

## 🚨 **Cuándo Consultar al Médico**
- Dolor persistente por más de 3 días
- Náuseas frecuentes o vómitos
- Pérdida de peso inexplicable

¿Hay algún síntoma específico que te preocupe o quieres más detalles sobre algún aspecto?''';
          }

          if (responseData['error'] != null) {
            print('❌ Error específico de API: ${responseData['error']}');
            throw Exception(
              'Error de API de Gemini: ${responseData['error']['message']}',
            );
          }

          throw Exception('Gemini devolvió una respuesta vacía');
        }

        print('✅ Gemini response received: ${geminiText.length} characters');
        return geminiText;
      } else {
        // Logging detallado del error
        print('❌ Gemini API Error - Status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');

        _logError(
          'gemini_api',
          'generateContent',
          'HTTP ${response.statusCode}',
          {
            'status_code': response.statusCode,
            'response_body': response.body,
            'api_endpoint':
                '$_baseUrl/models/gemini-2.0-flash-lite:generateContent',
            'has_api_key': _apiKey.isNotEmpty,
          },
        );

        // Manejo específico de errores
        switch (response.statusCode) {
          case 400:
            throw Exception(
              'Solicitud inválida a la API de Gemini. Verifica el formato del mensaje.',
            );
          case 401:
            throw Exception(
              'API key de Gemini inválida o expirada. Contacta al administrador.',
            );
          case 403:
            throw Exception(
              'Sin permisos para usar la API de Gemini. Verifica tu cuenta.',
            );
          case 404:
            throw Exception(
              'Endpoint de la API de Gemini no encontrado. Verifica la configuración.',
            );
          case 429:
            throw Exception(
              'Límite de solicitudes excedido. Intenta de nuevo en unos minutos.',
            );
          case 500:
          case 502:
          case 503:
            throw Exception(
              'Servicio de Gemini temporalmente no disponible. Intenta más tarde.',
            );
          default:
            throw Exception(
              'Error en la API de Gemini: ${response.statusCode} - ${response.body}',
            );
        }
      }
    } catch (e) {
      print('💥 Gemini API Exception: $e');

      if (e.toString().contains('TimeoutException')) {
        print('⏰ Timeout error detected');
        _logError('gemini_api', 'generateContent', 'Timeout', {
          'error_type': 'timeout',
          'timeout_duration': '60 seconds',
        });
        throw Exception(
          'Timeout al conectar con la API de Gemini. Verifica tu conexión.',
        );
      }
      if (e.toString().contains('SocketException')) {
        print('🌐 Socket/Connection error detected');
        _logError('gemini_api', 'generateContent', 'Connection Error', {
          'error_type': 'socket_exception',
          'error_details': e.toString(),
        });
        throw Exception(
          'Error de conexión con la API de Gemini. Verifica tu internet.',
        );
      }

      // Log de error general
      _logError('gemini_api', 'generateContent', 'Unexpected Error', {
        'error_type': 'unexpected',
        'error_details': e.toString(),
      });
      rethrow;
    }
  }

  Future<DeepLearningAnalysis> _getDeepLearningAnalysis(
    String message,
    String userId,
  ) async {
    if (_deepLearningDatasource == null) {
      throw Exception('Deep Learning datasource no disponible');
    }

    // Extraer información relevante del mensaje para el análisis
    final userHabits = _extractHabitsFromMessage(message);

    // Usar el nuevo método predictGastritisRisk en lugar de analyzeGastritisRisk
    final prediction = await _deepLearningDatasource.predictGastritisRisk(
      userId: userId,
      userHabits: userHabits,
    );

    // Convertir GastritisRiskPrediction a DeepLearningAnalysis
    return DeepLearningAnalysis(
      id: _uuid.v4(),
      userId: prediction.userId,
      type: AnalysisType.gastritisRisk,
      inputData: userHabits,
      results: {
        'risk_level': prediction.riskLevel,
        'risk_category': prediction.riskCategory,
        'factor_contributions': prediction.factorContributions,
        'risk_factors': prediction.riskFactors,
      },
      riskLevel: _mapRiskLevel(prediction.riskCategory),
      confidence: prediction.confidence,
      recommendations: [], // Se obtendrán por separado
      timestamp: prediction.timestamp,
      modelVersion: '1.0.0',
    );
  }

  /// Obtiene respuesta del backend de deep learning usando predicción y recomendaciones
  Future<Map<String, dynamic>?> _getDeepLearningChatResponse(
    String message,
    String userId,
    String? sessionId,
  ) async {
    if (_deepLearningDatasource == null) {
      print('⚠️ Deep Learning datasource no disponible');
      return null;
    }

    try {
      print('🤖 Iniciando análisis de Deep Learning para usuario: $userId');

      final extractedSymptoms = _extractSymptomsFromMessage(message);
      final extractedHabits = _extractHabitsFromMessage(message);

      print('📊 Síntomas extraídos: ${extractedSymptoms.keys.join(", ")}');
      print('🔍 Hábitos detectados: ${extractedHabits.keys.join(", ")}');

      // Obtener predicción de riesgo de gastritis
      final prediction = await _deepLearningDatasource
          .predictGastritisRisk(userId: userId, userHabits: extractedHabits)
          .timeout(const Duration(seconds: 15));

      // Obtener recomendaciones de hábitos
      final recommendations = await _deepLearningDatasource
          .getHabitRecommendations(
            userId: userId,
            currentHabits: extractedHabits,
            riskLevel: prediction.riskLevel,
          )
          .timeout(const Duration(seconds: 10));

      print('✅ Respuesta de Deep Learning recibida exitosamente');

      // Crear respuesta estructurada similar al formato anterior
      return {
        'response_type': 'prediction',
        'message': 'Análisis de riesgo de gastritis completado',
        'risk_assessment': {
          'level': prediction.riskCategory,
          'score': prediction.riskLevel,
          'factors': prediction.riskFactors,
          'confidence': prediction.confidence,
        },
        'suggested_actions': recommendations.map((r) => r.title).toList(),
        'detailed_recommendations': recommendations
            .map(
              (r) => {
                'title': r.title,
                'description': r.description,
                'category': r.category,
                'priority': r.priority,
                'impact_score': r.impactScore,
                'action_steps': r.actionSteps,
                'timeframe': r.timeframe,
              },
            )
            .toList(),
        'timestamp': prediction.timestamp.toIso8601String(),
        'status': 'success',
      };
    } on TimeoutException {
      print('⏰ Timeout en llamada a Deep Learning backend (15s)');
      return _createFallbackDLResponse(
        message,
        extractedSymptoms: _extractSymptomsFromMessage(message),
      );
    } on SocketException catch (e) {
      print('🌐 Error de conexión con Deep Learning backend: $e');
      return _createFallbackDLResponse(
        message,
        extractedSymptoms: _extractSymptomsFromMessage(message),
      );
    } catch (e, stackTrace) {
      print('❌ Error inesperado en Deep Learning: $e');
      print('📍 Stack trace: $stackTrace');
      return _createFallbackDLResponse(
        message,
        extractedSymptoms: _extractSymptomsFromMessage(message),
      );
    }
  }

  /// Extrae síntomas del mensaje del usuario con análisis mejorado
  Map<String, dynamic> _extractSymptomsFromMessage(String message) {
    final symptoms = <String, dynamic>{};
    final lowerMessage = message.toLowerCase();

    // Detectar dolor de estómago con intensidad
    if (lowerMessage.contains('dolor') &&
        (lowerMessage.contains('estómago') ||
            lowerMessage.contains('estomago'))) {
      symptoms['stomach_pain'] = true;
      symptoms['pain_duration'] = _extractDuration(lowerMessage);
      symptoms['pain_intensity'] = _extractIntensity(lowerMessage);
    }

    // Acidez y agruras
    if (lowerMessage.contains('acidez') ||
        lowerMessage.contains('agruras') ||
        lowerMessage.contains('reflujo')) {
      symptoms['heartburn'] = true;
      symptoms['heartburn_frequency'] = _extractFrequency(lowerMessage);
    }

    // Náuseas y vómitos
    if (lowerMessage.contains('náusea') ||
        lowerMessage.contains('nausea') ||
        lowerMessage.contains('ganas de vomitar') ||
        lowerMessage.contains('vómito')) {
      symptoms['nausea'] = true;
    }

    // Hinchazón e inflamación
    if (lowerMessage.contains('hinchazón') ||
        lowerMessage.contains('inflamado') ||
        lowerMessage.contains('distensión') ||
        lowerMessage.contains('pesadez')) {
      symptoms['bloating'] = true;
    }

    // Síntomas adicionales
    if (lowerMessage.contains('ardor') || lowerMessage.contains('quemazón')) {
      symptoms['burning_sensation'] = true;
    }

    if (lowerMessage.contains('inapetencia') ||
        lowerMessage.contains('sin apetito') ||
        lowerMessage.contains('no tengo hambre')) {
      symptoms['loss_of_appetite'] = true;
    }

    return symptoms;
  }

  /// Extrae duración de síntomas del mensaje
  String _extractDuration(String message) {
    if (message.contains('semana')) return 'weekly';
    if (message.contains('día') || message.contains('dias')) return 'daily';
    if (message.contains('mes')) return 'monthly';
    if (message.contains('hora')) return 'hourly';
    if (message.contains('momento') || message.contains('ahora')) {
      return 'current';
    }
    if (message.contains('crónico') || message.contains('siempre')) {
      return 'chronic';
    }
    return 'unknown';
  }

  /// Extrae intensidad del dolor del mensaje
  String _extractIntensity(String message) {
    if (message.contains('mucho') ||
        message.contains('intenso') ||
        message.contains('fuerte')) {
      return 'high';
    }
    if (message.contains('poco') ||
        message.contains('leve') ||
        message.contains('ligero')) {
      return 'low';
    }
    if (message.contains('moderado') || message.contains('regular')) {
      return 'medium';
    }
    return 'unknown';
  }

  /// Extrae frecuencia de síntomas del mensaje
  String _extractFrequency(String message) {
    if (message.contains('siempre') || message.contains('constantemente')) {
      return 'constant';
    }
    if (message.contains('frecuente') || message.contains('seguido')) {
      return 'frequent';
    }
    if (message.contains('ocasional') || message.contains('a veces')) {
      return 'occasional';
    }
    if (message.contains('rara vez') || message.contains('pocas veces')) {
      return 'rare';
    }
    return 'unknown';
  }

  /// Crea una respuesta de fallback cuando Deep Learning no está disponible
  Map<String, dynamic> _createFallbackDLResponse(
    String message, {
    Map<String, dynamic>? extractedSymptoms,
  }) {
    final symptoms = extractedSymptoms ?? _extractSymptomsFromMessage(message);

    return {
      'response_type': 'fallback',
      'message': 'Análisis básico realizado localmente',
      'risk_assessment': {
        'level': symptoms.isNotEmpty ? 'medium' : 'low',
        'factors': symptoms.keys.toList(),
        'confidence': 0.6,
      },
      'suggested_actions': [
        'Consultar con un profesional de la salud',
        'Mantener un diario de síntomas',
        'Seguir una dieta balanceada',
      ],
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'fallback_mode',
    };
  }

  /// Crea una respuesta de fallback mejorada con más contexto
  Map<String, dynamic> _createEnhancedFallbackResponse(
    String message,
    String userId,
    String errorContext,
  ) {
    final symptoms = _extractSymptomsFromMessage(message);
    final habits = _extractHabitsFromMessage(message);

    // Análisis más sofisticado del mensaje
    String contextualResponse = '';
    List<String> smartActions = [];
    Map<String, dynamic> riskAssessment = {};

    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('dolor') &&
        (lowerMessage.contains('estómago') ||
            lowerMessage.contains('abdominal'))) {
      contextualResponse =
          '🔍 **Análisis Local:** Detectamos síntomas gastrointestinales. '
          'Basado en patrones conocidos, te sugerimos medidas preventivas inmediatas.';

      smartActions = [
        'Implementar comidas pequeñas y frecuentes',
        'Evitar alimentos irritantes (picantes, ácidos)',
        'Aplicar técnicas de relajación para reducir estrés',
        'Mantener hidratación adecuada',
      ];

      riskAssessment = {
        'level': 'medium',
        'confidence': 0.75,
        'factors': ['síntomas_gastrointestinales', 'dolor_abdominal'],
        'recommendations': [
          'Monitorear frecuencia e intensidad del dolor',
          'Consulta médica si persisten los síntomas por más de 48h',
          'Implementar dieta blanda temporalmente',
        ],
      };
    } else if (lowerMessage.contains('estrés') ||
        lowerMessage.contains('ansiedad')) {
      contextualResponse =
          '🧠 **Análisis Local:** Identificamos factores de estrés que pueden afectar la salud digestiva. '
          'El manejo del estrés es clave para prevenir gastritis.';

      smartActions = [
        'Practicar técnicas de respiración profunda',
        'Establecer rutinas de relajación',
        'Mantener horarios regulares de comida',
        'Considerar actividad física moderada',
      ];

      riskAssessment = {
        'level': 'medium',
        'confidence': 0.70,
        'factors': ['estrés_psicológico', 'impacto_digestivo'],
        'recommendations': [
          'Implementar técnicas de manejo del estrés',
          'Evaluar factores estresantes en el entorno',
          'Considerar apoyo profesional si es necesario',
        ],
      };
    } else {
      contextualResponse =
          '💡 **Análisis Local:** Procesamos tu consulta con nuestro sistema de respaldo. '
          'Te ofrecemos recomendaciones generales para mantener una buena salud digestiva.';

      smartActions = [
        'Mantener alimentación balanceada y regular',
        'Incorporar ejercicio moderado diariamente',
        'Asegurar descanso adecuado (7-8 horas)',
        'Gestionar niveles de estrés efectivamente',
      ];

      riskAssessment = {
        'level': 'low',
        'confidence': 0.65,
        'factors': [],
        'recommendations': [
          'Continuar con hábitos preventivos',
          'Monitoreo regular de síntomas',
          'Mantener comunicación con profesionales de salud',
        ],
      };
    }

    return {
      'message_id': _uuid.v4(),
      'respuesta_modelo': contextualResponse,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': 'fallback_session_${_uuid.v4()}',
      'risk_assessment': riskAssessment,
      'suggested_actions': smartActions,
      'confidence_score': riskAssessment['confidence'] ?? 0.65,
      'processing_time_ms': 50,
      'model_version': '1.0.0-local-fallback',
      'status': 'local_analysis',
      'error_context': errorContext,
      'fallback_reason': 'deep_learning_service_unavailable',
    };
  }

  /// Convierte la categoría de riesgo string a RiskLevel enum
  RiskLevel _mapRiskLevel(String riskCategory) {
    switch (riskCategory.toLowerCase()) {
      case 'low':
      case 'bajo':
        return RiskLevel.low;
      case 'medium':
      case 'moderate':
      case 'moderado':
      case 'medio':
        return RiskLevel.medium;
      case 'high':
      case 'alto':
        return RiskLevel.high;
      case 'critical':
      case 'critico':
      case 'crítico':
        return RiskLevel.critical;
      default:
        return RiskLevel.low;
    }
  }

  /// Registra errores de Deep Learning para métricas y debugging
  void _logDeepLearningError(String operation, String error) {
    _logError('deep_learning', operation, error, {
      'dl_service_available': _deepLearningDatasource != null,
    });
  }

  /// Método general de logging de errores con contexto detallado
  void _logError(
    String service,
    String operation,
    String error, [
    Map<String, dynamic>? context,
  ]) {
    final errorLog = {
      'timestamp': DateTime.now().toIso8601String(),
      'service': service,
      'operation': operation,
      'error': error,
      'context': context ?? {},
      'user_agent': 'ViveGood_Flutter_App',
      'version': '1.0.0',
    };

    // Logging detallado para debugging
    print('🚨 ===== ERROR LOG =====');
    print('🕐 Timestamp: ${errorLog['timestamp']}');
    print('🔧 Service: ${errorLog['service']}');
    print('⚙️ Operation: ${errorLog['operation']}');
    print('❌ Error: ${errorLog['error']}');
    if (context != null && context.isNotEmpty) {
      print('📋 Context: ${errorLog['context']}');
    }
    print('🚨 =====================');

    // En un entorno de producción, esto se enviaría a un servicio de logging
    // TODO: Implementar envío a servicio de métricas/logging
    // await _metricsService.logError(errorLog);
  }

  String _combineResponses(
    String geminiResponse,
    DeepLearningAnalysis analysis,
  ) {
    final buffer = StringBuffer();

    // Agregar respuesta de Gemini
    buffer.writeln(geminiResponse);
    buffer.writeln();

    // Agregar análisis de Deep Learning
    buffer.writeln('📊 **Análisis de Riesgo:**');
    buffer.writeln(
      '• Nivel de riesgo: ${_getRiskLevelText(analysis.riskLevel)}',
    );
    buffer.writeln(
      '• Confianza: ${(analysis.confidence * 100).toStringAsFixed(1)}%',
    );

    if (analysis.identifiedRiskFactors?.isNotEmpty == true) {
      buffer.writeln();
      buffer.writeln('⚠️ **Factores de riesgo identificados:**');
      for (final factor in analysis.identifiedRiskFactors!) {
        buffer.writeln('• $factor');
      }
    }

    if (analysis.recommendations.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💡 **Recomendaciones personalizadas:**');
      for (final recommendation in analysis.recommendations) {
        buffer.writeln('• $recommendation');
      }
    }

    return buffer.toString();
  }

  /// Combina respuestas de Gemini, chat de Deep Learning y análisis
  String _combineAllResponses(
    String geminiResponse,
    Map<String, dynamic>? dlChatResponse,
    DeepLearningAnalysis? dlAnalysis,
  ) {
    final buffer = StringBuffer();

    // Formatear respuesta de Gemini (eliminar marcadores markdown y resaltar palabras clave)
    final formattedGemini = _formatGeminiResponse(geminiResponse);
    buffer.writeln(formattedGemini);

    // Agregar información del chat de Deep Learning si está disponible
    if (dlChatResponse != null) {
      buffer.writeln();
      buffer.writeln('🤖 **Análisis Inteligente:**');

      if (dlChatResponse['risk_assessment'] != null) {
        final riskAssessment = dlChatResponse['risk_assessment'];
        buffer.writeln(
          '• Evaluación de riesgo: ${riskAssessment['level'] ?? 'No determinado'}',
        );
        if (riskAssessment['factors'] != null) {
          buffer.writeln(
            '• Factores identificados: ${(riskAssessment['factors'] as List).join(', ')}',
          );
        }
      }

      if (dlChatResponse['suggested_actions'] != null) {
        buffer.writeln();
        buffer.writeln('💡 **Acciones Recomendadas:**');
        final actions = dlChatResponse['suggested_actions'] as List;
        for (final action in actions) {
          buffer.writeln('• $action');
        }
      }

      final confidence = dlChatResponse['confidence_score'];
      if (confidence != null) {
        buffer.writeln();
        buffer.writeln(
          '📊 Confianza del análisis: ${(confidence * 100).toStringAsFixed(1)}%',
        );
      }
    }

    // Agregar análisis tradicional como fallback
    if (dlAnalysis != null && dlChatResponse == null) {
      buffer.writeln();
      buffer.writeln('📊 **Análisis de Riesgo:**');
      buffer.writeln(
        '• Nivel de riesgo: ${_getRiskLevelText(dlAnalysis.riskLevel)}',
      );
      buffer.writeln(
        '• Confianza: ${(dlAnalysis.confidence * 100).toStringAsFixed(1)}%',
      );

      if (dlAnalysis.identifiedRiskFactors?.isNotEmpty == true) {
        buffer.writeln();
        buffer.writeln('⚠️ **Factores de riesgo identificados:**');
        for (final factor in dlAnalysis.identifiedRiskFactors!) {
          buffer.writeln('• $factor');
        }
      }

      if (dlAnalysis.recommendations.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('💡 **Recomendaciones personalizadas:**');
        for (final recommendation in dlAnalysis.recommendations) {
          buffer.writeln('• $recommendation');
        }
      }
    }

    return buffer.toString();
  }

  /// Formatea la respuesta de Gemini eliminando marcadores markdown y aplicando formato de texto
  String _formatGeminiResponse(String response) {
    print('🔥 DEBUG FORMATEO: Respuesta original de Gemini:');
    print('🔥 DEBUG FORMATEO: "$response"');

    // Normalizar el texto primero
    String normalized = response
        .replaceAll(
          RegExp(r'\n\s*\n\s*\n'),
          '\n\n',
        ) // Máximo 2 saltos de línea consecutivos
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalizar espacios
        .replaceAll(
          RegExp(r'^[•*-]\s*', multiLine: true),
          '• ',
        ) // Unificar bullets
        .replaceAllMapped(RegExp(r'^\s*\d+\.\s+(.+)$', multiLine: true), (
          match,
        ) {
          print('🔥 DEBUG REGEX: Match encontrado: "${match.group(0)}"');
          print('🔥 DEBUG REGEX: Grupo 1: "${match.group(1)}"');
          return '• ${match.group(1)}';
        }) // Convertir listas numeradas
        .replaceAllMapped(
          RegExp(r'^#{1,3}\s*(.+)', multiLine: true),
          (match) => match.group(1)!,
        ) // Limpiar títulos
        .trim();

    print('🔥 DEBUG FORMATEO: Después de normalización:');
    print('🔥 DEBUG FORMATEO: "$normalized"');

    // Eliminar marcadores markdown y aplicar formato de texto
    String formatted = normalized
        .replaceAllMapped(
          RegExp(r'\*\*([^*]+?)\*\*'),
          (match) => match.group(1)!,
        ) // Eliminar negritas **texto**
        .replaceAllMapped(
          RegExp(r'\*([^*]+?)\*'),
          (match) => match.group(1)!,
        ) // Eliminar cursivas *texto*
        .replaceAllMapped(
          RegExp(r'__([^_]+?)__'),
          (match) => match.group(1)!,
        ) // Eliminar negritas __texto__
        .replaceAllMapped(
          RegExp(r'_([^_]+?)_'),
          (match) => match.group(1)!,
        ); // Eliminar cursivas _texto_

    print('🔥 DEBUG FORMATEO: Después de eliminar markdown:');
    print('🔥 DEBUG FORMATEO: "$formatted"');

    // Resaltar palabras clave médicas importantes con emojis
    formatted = _highlightMedicalKeywords(formatted);

    print('🔥 DEBUG FORMATEO: Resultado final:');
    print('🔥 DEBUG FORMATEO: "$formatted"');

    return formatted;
  }

  /// Resalta palabras clave médicas importantes con formato limpio
  String _highlightMedicalKeywords(String text) {
    // Solo resaltar palabras clave críticas sin emojis mezclados
    final criticalKeywords = {'gastritis': 'GASTRITIS', 'úlcera': 'ÚLCERA'};

    String highlighted = text;

    // Aplicar resaltado solo a palabras críticas, sin emojis mezclados
    criticalKeywords.forEach((keyword, replacement) {
      final regex = RegExp(
        r'\b' + RegExp.escape(keyword) + r'\b',
        caseSensitive: false,
      );
      highlighted = highlighted.replaceAllMapped(
        regex,
        (match) => '**$replacement**',
      );
    });

    return highlighted;
  }

  /// Extrae hábitos sugeridos de la respuesta de Gemini para creación automática
  List<Map<String, dynamic>> _extractHabitsFromGeminiResponse(String response) {
    final habits = <Map<String, dynamic>>[];
    final lines = response.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Detectar líneas que contienen recomendaciones de hábitos
      if (_isHabitRecommendation(trimmedLine)) {
        final habit = _parseHabitFromLine(trimmedLine);
        if (habit != null) {
          habits.add(habit);
        }
      }
    }

    return habits;
  }

  /// Determina si una línea contiene una recomendación de hábito
  bool _isHabitRecommendation(String line) {
    final lowerLine = line.toLowerCase();

    // Patrones que indican recomendaciones de hábitos
    final patterns = [
      'comidas pequeñas',
      'evita',
      'evitar',
      'consume',
      'incluye',
      'bebe',
      'toma',
      'realiza',
      'practica',
      'mantén',
      'establece',
      'horarios',
      'frecuencia',
    ];

    return patterns.any((pattern) => lowerLine.contains(pattern)) &&
        (line.startsWith('•') || line.startsWith('*') || line.startsWith('-'));
  }

  /// Parsea un hábito desde una línea de texto
  Map<String, dynamic>? _parseHabitFromLine(String line) {
    // Limpiar la línea de marcadores
    String cleanLine = line
        .replaceAll(RegExp(r'^[•*-]\s*'), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .trim();

    if (cleanLine.isEmpty) return null;

    // Determinar categoría y tipo de hábito
    final category = _determineHabitCategory(cleanLine);
    final type = _determineHabitType(cleanLine);

    return {
      'name': cleanLine,
      'description': 'Recomendación generada automáticamente por el asistente',
      'category': category,
      'type': type,
      'frequency': _suggestFrequency(cleanLine),
      'auto_generated': true,
      'source': 'gemini_recommendation',
    };
  }

  /// Determina la categoría del hábito
  String _determineHabitCategory(String habit) {
    final lowerHabit = habit.toLowerCase();

    if (lowerHabit.contains('comida') ||
        lowerHabit.contains('alimento') ||
        lowerHabit.contains('come') ||
        lowerHabit.contains('consume')) {
      return 'Alimentación';
    }

    if (lowerHabit.contains('ejercicio') ||
        lowerHabit.contains('actividad') ||
        lowerHabit.contains('camina') ||
        lowerHabit.contains('deporte')) {
      return 'Ejercicio';
    }

    if (lowerHabit.contains('agua') ||
        lowerHabit.contains('bebe') ||
        lowerHabit.contains('hidrata')) {
      return 'Hidratación';
    }

    if (lowerHabit.contains('sueño') ||
        lowerHabit.contains('dormir') ||
        lowerHabit.contains('descanso')) {
      return 'Descanso';
    }

    if (lowerHabit.contains('estrés') ||
        lowerHabit.contains('relajación') ||
        lowerHabit.contains('meditación')) {
      return 'Bienestar Mental';
    }

    return 'General';
  }

  /// Determina el tipo de hábito
  String _determineHabitType(String habit) {
    final lowerHabit = habit.toLowerCase();

    if (lowerHabit.contains('evita') ||
        lowerHabit.contains('evitar') ||
        lowerHabit.contains('no') ||
        lowerHabit.contains('reduce')) {
      return 'Evitar';
    }

    return 'Adoptar';
  }

  /// Sugiere frecuencia para el hábito
  String _suggestFrequency(String habit) {
    final lowerHabit = habit.toLowerCase();

    if (lowerHabit.contains('diario') ||
        lowerHabit.contains('cada día') ||
        lowerHabit.contains('todos los días')) {
      return 'Diario';
    }

    if (lowerHabit.contains('comida') || lowerHabit.contains('alimento')) {
      return 'Con cada comida';
    }

    if (lowerHabit.contains('agua') || lowerHabit.contains('hidrata')) {
      return 'Varias veces al día';
    }

    return 'Diario';
  }

  Map<String, dynamic> _extractHabitsFromMessage(String message) {
    final habits = <String, dynamic>{};
    final lowerMessage = message.toLowerCase();

    // Detectar frecuencia de comidas picantes
    if (lowerMessage.contains('picante') ||
        lowerMessage.contains('chile') ||
        lowerMessage.contains('ají')) {
      habits['spicy_food_frequency'] = 4; // Frecuente
    }

    // Detectar síntomas de dolor
    if (lowerMessage.contains('dolor') &&
        (lowerMessage.contains('estómago') ||
            lowerMessage.contains('estomago'))) {
      habits['stomach_pain_frequency'] = 5; // Diario durante una semana
    }

    // Detectar patrones de alimentación
    if (lowerMessage.contains('comida rápida') ||
        lowerMessage.contains('fast food')) {
      habits['fast_food_frequency'] = 3;
    }

    // Detectar estrés
    if (lowerMessage.contains('estrés') ||
        lowerMessage.contains('estres') ||
        lowerMessage.contains('ansiedad')) {
      habits['stress_level'] = 4;
    }

    return habits;
  }

  List<Map<String, dynamic>> _extractHabitsFromResponse(String content) {
    final habits = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    final lowerContent = content.toLowerCase();

    for (final line in lines) {
      final trimmedLine = line.trim();
      final lowerLine = trimmedLine.toLowerCase();

      // Detectar recomendaciones de comidas pequeñas y frecuentes
      if (lowerLine.contains('comer:') && 
          (lowerLine.contains('porciones pequeñas') || 
           lowerLine.contains('comidas pequeñas') ||
           lowerLine.contains('porciones más pequeñas'))) {
        habits.add({
          'name': 'Comidas pequeñas y frecuentes',
          'description': 'Comer porciones más pequeñas cada 2-3 horas',
          'category': 'alimentacion',
          'frequency': 'daily',
          'times_per_day': 5,
        });
      }

      // Detectar recomendaciones para evitar alimentos irritantes
      if ((lowerLine.contains('evitar:') || lowerLine.contains('evita')) &&
          (lowerLine.contains('irritantes') || 
           lowerLine.contains('picante') ||
           lowerLine.contains('grasosas') ||
           lowerLine.contains('cítricos') ||
           lowerLine.contains('alcohol') ||
           lowerLine.contains('cafeína'))) {
        habits.add({
          'name': 'Evitar alimentos irritantes',
          'description': 'Evitar comidas picantes, café, alcohol y cítricos',
          'category': 'alimentacion',
          'frequency': 'daily',
          'is_negative': true,
        });
      }

      // Detectar recomendaciones de hidratación
      if ((lowerLine.contains('tomar:') || lowerLine.contains('beber')) && 
          lowerLine.contains('agua')) {
        habits.add({
          'name': 'Mantener hidratación',
          'description': 'Beber suficiente agua durante el día',
          'category': 'hidratacion',
          'frequency': 'daily',
          'target_amount': '8 vasos',
        });
      }

      // Detectar recomendaciones de descanso después de comer
      if (lowerLine.contains('evitar acostarte') || 
          lowerLine.contains('no acostarse') ||
          lowerLine.contains('después de comer')) {
        habits.add({
          'name': 'Evitar acostarse después de comer',
          'description': 'Esperar al menos 2-3 horas antes de acostarse después de comer',
          'category': 'descanso',
          'frequency': 'daily',
          'is_negative': true,
        });
      }
    }

    // También buscar patrones en todo el contenido para mayor flexibilidad
    if (lowerContent.contains('porciones pequeñas') && !habits.any((h) => h['name'] == 'Comidas pequeñas y frecuentes')) {
      habits.add({
        'name': 'Comidas pequeñas y frecuentes',
        'description': 'Comer porciones más pequeñas cada 2-3 horas',
        'category': 'alimentacion',
        'frequency': 'daily',
        'times_per_day': 5,
      });
    }

    if ((lowerContent.contains('evitar') && lowerContent.contains('irritantes')) && 
        !habits.any((h) => h['name'] == 'Evitar alimentos irritantes')) {
      habits.add({
        'name': 'Evitar alimentos irritantes',
        'description': 'Evitar comidas picantes, café, alcohol y cítricos',
        'category': 'alimentacion',
        'frequency': 'daily',
        'is_negative': true,
      });
    }

    if (lowerContent.contains('agua') && !habits.any((h) => h['name'] == 'Mantener hidratación')) {
      habits.add({
        'name': 'Mantener hidratación',
        'description': 'Beber suficiente agua durante el día',
        'category': 'hidratacion',
        'frequency': 'daily',
        'target_amount': '8 vasos',
      });
    }

    return habits;
  }

  String _getRiskLevelText(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Bajo 🟢';
      case RiskLevel.medium:
        return 'Medio 🟡';
      case RiskLevel.high:
        return 'Alto 🟠';
      case RiskLevel.critical:
        return 'Crítico 🔴';
    }
  }

  double? _extractConfidence(Map<String, dynamic> data) {
    // Gemini no proporciona confidence score directamente
    // Podríamos implementar una heurística basada en la respuesta
    return 0.85; // Valor por defecto
  }

  /// Extrae sugerencias combinando respuesta de chat DL y análisis tradicional
  List<String> _extractSuggestions(
    Map<String, dynamic>? dlChatResponse,
    DeepLearningAnalysis? dlAnalysis,
  ) {
    final suggestions = <String>[];

    // Agregar sugerencias del chat de deep learning
    if (dlChatResponse != null && dlChatResponse['suggested_actions'] != null) {
      final actions = dlChatResponse['suggested_actions'] as List;
      suggestions.addAll(actions.map((action) => action.toString()));
    }

    // Agregar recomendaciones del análisis tradicional como fallback
    if (dlAnalysis != null && suggestions.isEmpty) {
      suggestions.addAll(dlAnalysis.recommendations);
    }

    // Agregar sugerencias generales si no hay ninguna
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'Mantén horarios regulares de comida',
        'Evita alimentos irritantes',
        'Reduce el estrés',
        'Consulta con un profesional de la salud',
      ]);
    }

    return suggestions;
  }

  /// Crea una respuesta de fallback cuando la API de Gemini no está disponible
  String _createGeminiFallbackResponse(
    String message,
    String userId,
    String error,
  ) {
    print('🔄 Generando respuesta de fallback para Gemini');

    // Analizar el mensaje para proporcionar una respuesta contextual
    final lowerMessage = message.toLowerCase();

    // Respuestas específicas para temas de salud digestiva
    if (lowerMessage.contains('dolor') ||
        lowerMessage.contains('estómago') ||
        lowerMessage.contains('gastritis')) {
      return '''Entiendo que tienes molestias estomacales. Aunque no puedo acceder al asistente de IA en este momento, puedo ofrecerte algunos consejos generales:

• Evita alimentos irritantes como picantes, ácidos o muy grasosos
• Come en porciones pequeñas y frecuentes
• Mantén horarios regulares de comida
• Reduce el estrés y practica técnicas de relajación
• Considera consultar con un profesional de la salud

¿Te gustaría que te ayude a crear un hábito específico para mejorar tu digestión?''';
    }

    if (lowerMessage.contains('hábito') ||
        lowerMessage.contains('rutina') ||
        lowerMessage.contains('crear')) {
      return '''Me encantaría ayudarte a crear nuevos hábitos saludables. Aunque el asistente de IA no está disponible temporalmente, puedo sugerirte algunos hábitos beneficiosos:

• Beber agua al despertar
• Caminar 30 minutos diarios
• Meditar 10 minutos antes de dormir
• Comer frutas y verduras en cada comida
• Mantener horarios regulares de sueño

¿Cuál de estos hábitos te interesa más desarrollar?''';
    }

    if (lowerMessage.contains('alimentación') ||
        lowerMessage.contains('comida') ||
        lowerMessage.contains('dieta')) {
      return '''La alimentación es fundamental para la salud digestiva. Te comparto algunos consejos nutricionales:

• Incluye fibra en tu dieta (frutas, verduras, cereales integrales)
• Evita comidas muy condimentadas o grasosas
• Mastica bien los alimentos
• Bebe suficiente agua durante el día
• Evita comer muy tarde en la noche

¿Te gustaría que te ayude a planificar comidas más saludables?''';
    }

    // Respuesta general de fallback
    return '''Disculpa, el asistente de IA está temporalmente no disponible, pero estoy aquí para ayudarte.

Puedo asistirte con:
• Crear hábitos saludables personalizados
• Consejos sobre alimentación y digestión
• Rutinas de ejercicio y bienestar
• Técnicas de manejo del estrés

¿En qué área específica te gustaría que te ayude hoy?

Nota: El servicio completo de IA se restablecerá pronto. Mientras tanto, puedo ofrecerte consejos basados en las mejores prácticas de salud.''';
  }

  Future<String> _speechToText(String audioPath) async {
    // Placeholder para integración con Speech-to-Text
    // Esto requeriría integración con Google Speech-to-Text API o similar
    throw UnimplementedError('Speech-to-Text no implementado aún');
  }

  /// Genera un título descriptivo para una conversación basado en el primer mensaje
  Future<String> generateConversationTitle(String firstMessage) async {
    try {
      final prompt =
          '''
Genera un título corto y descriptivo (máximo 50 caracteres) para una conversación de chat basado en este primer mensaje del usuario:

"$firstMessage"

El título debe:
- Ser conciso y claro
- Reflejar el tema principal del mensaje
- Estar en español
- No incluir comillas ni caracteres especiales
- Ser apropiado para mostrar en una lista de conversaciones

Responde SOLO con el título, sin explicaciones adicionales.
''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 20,
          'topP': 0.8,
          'maxOutputTokens': 100,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      final response = await _httpClient
          .post(
            Uri.parse(
              '$_baseUrl/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final title =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text']
                ?.trim() ??
            'Nueva conversación';

        // Limpiar el título y asegurar que no exceda 50 caracteres
        String cleanTitle = title.replaceAll(RegExp(r'["\n\r]'), '').trim();
        if (cleanTitle.length > 50) {
          cleanTitle = '${cleanTitle.substring(0, 47)}...';
        }

        return cleanTitle.isEmpty ? 'Nueva conversación' : cleanTitle;
      } else {
        print('❌ Error al generar título: ${response.statusCode}');
        return _generateFallbackTitle(firstMessage);
      }
    } catch (e) {
      print('❌ Error al generar título con Gemini: $e');
      return _generateFallbackTitle(firstMessage);
    }
  }

  /// Genera un título de fallback basado en palabras clave del mensaje
  String _generateFallbackTitle(String message) {
    final lowerMessage = message.toLowerCase();

    // Títulos basados en palabras clave comunes
    if (lowerMessage.contains('dolor') || lowerMessage.contains('duele')) {
      return 'Consulta sobre dolor';
    } else if (lowerMessage.contains('hábito') ||
        lowerMessage.contains('rutina')) {
      return 'Creación de hábitos';
    } else if (lowerMessage.contains('síntoma') ||
        lowerMessage.contains('síntomas')) {
      return 'Registro de síntomas';
    } else if (lowerMessage.contains('gastritis') ||
        lowerMessage.contains('estómago')) {
      return 'Consulta digestiva';
    } else if (lowerMessage.contains('ejercicio') ||
        lowerMessage.contains('actividad')) {
      return 'Actividad física';
    } else if (lowerMessage.contains('alimentación') ||
        lowerMessage.contains('comida')) {
      return 'Consulta nutricional';
    } else if (lowerMessage.contains('progreso') ||
        lowerMessage.contains('avance')) {
      return 'Seguimiento de progreso';
    } else {
      // Usar las primeras palabras del mensaje
      final words = message.split(' ').take(4).join(' ');
      return words.length > 50 ? '${words.substring(0, 47)}...' : words;
    }
  }

  /// Convierte el análisis médico del nuevo formato al formato legacy
  DeepLearningAnalysis? _convertMedicalAnalysisToLegacy(
    Map<String, dynamic> medicalAnalysis,
  ) {
    try {
      // Extraer información del nuevo formato
      final analysisId = medicalAnalysis['analysis_id'] ?? '';
      final timestamp =
          medicalAnalysis['timestamp'] ?? DateTime.now().toIso8601String();
      final confidence = (medicalAnalysis['confidence'] ?? 0.0).toDouble();

      // Extraer síntomas
      final symptomAnalysis = medicalAnalysis['symptom_analysis'] ?? {};
      final detectedSymptoms = List<String>.from(
        symptomAnalysis['detected_symptoms'] ?? [],
      );
      final severityLevel = symptomAnalysis['severity_level'] ?? 'leve';
      final urgency = symptomAnalysis['urgency'] ?? 'baja';

      // Extraer recomendaciones
      final recommendations = medicalAnalysis['recommendations'] ?? {};
      final dietaryRecommendations = List<String>.from(
        recommendations['dietary'] ?? [],
      );
      final lifestyleRecommendations = List<String>.from(
        recommendations['lifestyle'] ?? [],
      );
      final medicalRecommendations = List<String>.from(
        recommendations['medical'] ?? [],
      );

      // Extraer evaluación de riesgo
      final riskAssessment = medicalAnalysis['risk_assessment'] ?? {};
      final riskLevel = riskAssessment['risk_level'] ?? 'bajo';
      final followUp = riskAssessment['follow_up'] ?? '';

      // Mapear nivel de riesgo a enum
      RiskLevel riskLevelEnum;
      switch (riskLevel.toLowerCase()) {
        case 'alto':
        case 'high':
          riskLevelEnum = RiskLevel.high;
          break;
        case 'medio':
        case 'medium':
          riskLevelEnum = RiskLevel.medium;
          break;
        case 'crítico':
        case 'critical':
          riskLevelEnum = RiskLevel.critical;
          break;
        default:
          riskLevelEnum = RiskLevel.low;
      }

      // Crear objeto DeepLearningAnalysis en formato legacy
      return DeepLearningAnalysis(
        id: analysisId,
        userId: '', // Se llenará desde el contexto
        type: AnalysisType.gastritisRisk,
        inputData: {
          'symptoms': detectedSymptoms,
          'severity_level': severityLevel,
          'urgency': urgency,
        },
        results: medicalAnalysis,
        riskLevel: riskLevelEnum,
        recommendations: [
          ...dietaryRecommendations,
          ...lifestyleRecommendations,
          ...medicalRecommendations,
        ],
        confidence: confidence,
        timestamp: DateTime.parse(timestamp),
        modelVersion: '1.0.0',
        metadata: {
          'severity_level': severityLevel,
          'urgency': urgency,
          'follow_up': followUp,
          'confidence_text': medicalAnalysis['confidence_text'] ?? 'media',
          'status': medicalAnalysis['status'] ?? 'completed',
          'original_analysis': medicalAnalysis, // Mantener análisis original
        },
      );
    } catch (e) {
      print('❌ Error convirtiendo análisis médico a formato legacy: $e');
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
