import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../domain/entities/assistant/assistant_response.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../deep_learning_datasource.dart';
import '../../../domain/entities/deep_learning_analysis.dart';
import '../../models/assistant/assistant_response_model.dart';
import '../../services/habit_auto_creation_service.dart';

class GeminiAssistantDatasource {
  final String _apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final http.Client _httpClient;
  final DeepLearningDatasource? _deepLearningDatasource;
  final HabitAutoCreationService _habitAutoCreationService;

  GeminiAssistantDatasource({
    String? apiKey,
    http.Client? httpClient,
    DeepLearningDatasource? deepLearningDatasource,
    required HabitAutoCreationService habitAutoCreationService,
  }) : _apiKey = apiKey ?? 'AIzaSyAJ0SdbXQTyxjQ9IpPjKD97rNzFB2zJios',
       _httpClient = httpClient ?? http.Client(),
       _deepLearningDatasource = deepLearningDatasource,
       _habitAutoCreationService = habitAutoCreationService;

  Future<AssistantResponseModel> sendMessage({
    required String message,
    required String userId,
    required List<ChatMessage> conversationHistory,
    String? sessionId,
  }) async {
    try {
      // Intentar obtener respuesta de Gemini con fallback
      String geminiResponse;
      bool geminiAvailable = true;
      
      try {
        geminiResponse = await _getGeminiResponse(message, userId, conversationHistory);
        print('✅ Respuesta de Gemini obtenida exitosamente');
      } catch (e) {
        print('❌ Error en API de Gemini: $e');
        geminiAvailable = false;
        geminiResponse = _createGeminiFallbackResponse(message, userId, e.toString());
      }
      
      // Obtener respuesta del backend de deep learning con manejo robusto de errores
      Map<String, dynamic>? dlChatResponse;
      DeepLearningAnalysis? deepLearningAnalysis;
      bool dlServiceAvailable = false;
      
      if (_deepLearningDatasource != null) {
        // Verificar salud del servicio primero
        try {
          dlServiceAvailable = await _deepLearningDatasource!.checkModelHealth();
          print('🔍 Estado del servicio Deep Learning: ${dlServiceAvailable ? "Disponible" : "No disponible"}');
        } catch (e) {
          print('⚠️ Error verificando salud del servicio DL: $e');
          dlServiceAvailable = false;
        }
        
        // Intentar obtener respuesta de chat si el servicio está disponible
        if (dlServiceAvailable) {
          try {
            dlChatResponse = await _getDeepLearningChatResponse(message, userId, sessionId);
            print('✅ Respuesta de chat DL obtenida exitosamente');
          } catch (e) {
            print('❌ Error en chat de deep learning: $e');
            // Crear respuesta de fallback con contexto del error
            dlChatResponse = _createEnhancedFallbackResponse(message, userId, e.toString());
          }
        } else {
          // Crear respuesta de fallback cuando el servicio no está disponible
          dlChatResponse = _createEnhancedFallbackResponse(message, userId, 'Servicio no disponible');
        }
        
        // Intentar obtener análisis de deep learning
        try {
          if (dlServiceAvailable) {
            deepLearningAnalysis = await _getDeepLearningAnalysis(message, userId);
            print('✅ Análisis DL obtenido exitosamente');
          }
        } catch (e) {
          print('❌ Error en análisis de deep learning: $e');
          // Continuar sin análisis pero registrar el error para métricas
          _logDeepLearningError('analysis', e.toString());
        }
      } else {
        print('⚠️ Deep Learning datasource no configurado');
        // Crear respuesta básica cuando no hay datasource configurado
        dlChatResponse = _createEnhancedFallbackResponse(message, userId, 'Servicio no configurado');
      }
      
      // Combinar respuestas
      final combinedContent = _combineAllResponses(geminiResponse, dlChatResponse, deepLearningAnalysis);
      
      // Extraer hábitos sugeridos para creación automática
      final suggestedHabits = _extractHabitsFromGeminiResponse(geminiResponse);
      
      // Crear objeto AssistantResponse temporal para creación de hábitos
      final tempResponse = AssistantResponseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId ?? '',
        content: combinedContent,
        type: ResponseType.text,
        timestamp: DateTime.now(),
      );
      
      // Crear hábitos automáticamente basados en la respuesta
      try {
        await _habitAutoCreationService.createContextualHabits(
          assistantResponse: tempResponse,
          userMessage: message,
          userId: userId,
        );
      } catch (e) {
        // Log error pero no fallar la respuesta
        print('Error creating automatic habits: $e');
      }
      
      return AssistantResponseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId ?? '',
        content: combinedContent,
        type: ResponseType.text,
        timestamp: DateTime.now(),
        confidence: dlChatResponse?['confidence_score']?.toDouble() ?? 0.8,
        suggestions: _extractSuggestions(dlChatResponse, deepLearningAnalysis),
        extractedHabits: _extractHabitsFromResponse(combinedContent),
        analysisData: deepLearningAnalysis != null ? {
          'identifiedRiskFactors': deepLearningAnalysis.identifiedRiskFactors,
          'recommendations': deepLearningAnalysis.recommendations,
          'confidence': deepLearningAnalysis.confidence,
        } : null,
        suggestedHabits: suggestedHabits,
        dlChatResponse: dlChatResponse,
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

  Future<List<String>> getContextualSuggestions({
    required String userId,
    required String currentContext,
  }) async {
    try {
      final prompt = '''
Contexto: "$currentContext"

3 sugerencias para gastritis (máximo 4 palabras cada una):
Formato: sugerencia1, sugerencia2, sugerencia3''';

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/models/gemini-2.0-flash-exp:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 100,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
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
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? userContext,
  }) async {
    final buffer = StringBuffer();
    
    buffer.writeln('Eres "Vive Good", asistente especializado en prevención y manejo de gastritis.');
    buffer.writeln('');
    
    buffer.writeln('OBJETIVOS PRINCIPALES:');
    buffer.writeln('• Identificar indicadores específicos de gastritis y factores de riesgo');
    buffer.writeln('• Proporcionar recomendaciones personalizadas y accionables');
    buffer.writeln('• Facilitar la creación automática de hábitos saludables');
    buffer.writeln('• Educar sobre prevención y manejo de síntomas digestivos');
    buffer.writeln('');
    
    buffer.writeln('INDICADORES ESPECÍFICOS DE GASTRITIS A DETECTAR:');
    buffer.writeln('🔍 **Síntomas Primarios:**');
    buffer.writeln('• Dolor epigástrico (ardor, punzadas, presión en "boca del estómago")');
    buffer.writeln('• Acidez estomacal y reflujo gastroesofágico');
    buffer.writeln('• Náuseas matutinas o post-comida');
    buffer.writeln('• Sensación de plenitud temprana o distensión abdominal');
    buffer.writeln('• Pérdida de apetito o aversión a ciertos alimentos');
    buffer.writeln('');
    buffer.writeln('⚠️ **Factores de Riesgo Críticos:**');
    buffer.writeln('• Infección por H. pylori (antecedentes familiares, úlceras previas)');
    buffer.writeln('• Uso prolongado de AINEs (ibuprofeno, aspirina, diclofenaco)');
    buffer.writeln('• Consumo excesivo de alcohol o tabaco');
    buffer.writeln('• Estrés crónico y ansiedad');
    buffer.writeln('• Patrones alimentarios irregulares (ayunos prolongados, comidas tardías)');
    buffer.writeln('• Consumo frecuente de alimentos irritantes (picantes, ácidos, procesados)');
    buffer.writeln('');
    buffer.writeln('🍃 **Alimentos y Hábitos Protectores:**');
    buffer.writeln('• Fibra soluble: avena, manzana, pera, zanahoria');
    buffer.writeln('• Probióticos: yogur natural, kéfir, chucrut');
    buffer.writeln('• Antiinflamatorios naturales: jengibre, cúrcuma, manzanilla');
    buffer.writeln('• Técnicas de masticación lenta y porciones pequeñas');
    buffer.writeln('• Horarios regulares de comida (cada 3-4 horas)');
    buffer.writeln('');
    
    buffer.writeln('FORMATO DE RESPUESTA ESTRUCTURADA:');
    buffer.writeln('1) 🤝 **Validación Empática:** Reconoce y valida la experiencia del usuario');
    buffer.writeln('2) 🎯 **Análisis de Indicadores:** Identifica síntomas/factores específicos mencionados');
    buffer.writeln('3) 📋 **Recomendaciones Accionables:** Lista específica con horarios y frecuencias');
    buffer.writeln('   - Usar formato: "• [Acción específica] - [Horario/Frecuencia] - [Beneficio]"');
    buffer.writeln('   - Incluir al menos 3-5 recomendaciones concretas');
    buffer.writeln('   - Especificar horarios cuando sea relevante (ej: "antes del desayuno", "cada 3 horas")');
    buffer.writeln('4) 💪 **Motivación Personalizada:** Mensaje enfocado en beneficios específicos');
    buffer.writeln('');
    buffer.writeln('INSTRUCCIONES PARA CREACIÓN AUTOMÁTICA DE HÁBITOS:');
    buffer.writeln('• Incluye recomendaciones que puedan convertirse en hábitos trackeable');
    buffer.writeln('• Especifica frecuencias claras (diario, cada 3 horas, antes de comidas)');
    buffer.writeln('• Menciona horarios específicos cuando sea apropiado');
    buffer.writeln('• Usa verbos de acción claros ("tomar", "evitar", "practicar", "consumir")');
    buffer.writeln('• Prioriza hábitos simples y medibles');
    buffer.writeln('');
    buffer.writeln('LÍMITES: Máximo 200 palabras, tono profesional pero cálido.');
    buffer.writeln('');
    
    // Análisis contextual del mensaje del usuario
    final messageAnalysis = _analyzeUserMessage(message);
    if (messageAnalysis.isNotEmpty) {
      buffer.writeln('ANÁLISIS DEL MENSAJE ACTUAL:');
      messageAnalysis.forEach((key, value) {
        buffer.writeln('• $key: $value');
      });
      buffer.writeln('');
    }
    
    if (userContext != null && userContext.isNotEmpty) {
      buffer.writeln('CONTEXTO DEL USUARIO:');
      userContext.forEach((key, value) {
        buffer.writeln('• $key: $value');
      });
      buffer.writeln('');
    }
    
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('HISTORIAL RECIENTE (para continuidad):');
      for (final msg in conversationHistory.take(3)) {
        final sender = msg.type == MessageType.user ? 'Usuario' : 'Asistente';
        final preview = msg.content.length > 100 ? '${msg.content.substring(0, 100)}...' : msg.content;
        buffer.writeln('$sender: $preview');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('MENSAJE DEL USUARIO: "$message"');
    buffer.writeln('');
    buffer.writeln('RESPONDE AHORA siguiendo EXACTAMENTE la estructura requerida:');
    
    return buffer.toString();
  }
  
  /// Analiza el mensaje del usuario para extraer contexto relevante
  Map<String, String> _analyzeUserMessage(String message) {
    final analysis = <String, String>{};
    final lowerMessage = message.toLowerCase();
    
    // Detectar urgencia
    if (_containsAnyKeyword(lowerMessage, ['urgente', 'dolor fuerte', 'muy mal', 'insoportable'])) {
      analysis['Urgencia'] = 'Alta - requiere atención inmediata';
    } else if (_containsAnyKeyword(lowerMessage, ['molesto', 'incómodo', 'frecuente'])) {
      analysis['Urgencia'] = 'Media - síntomas recurrentes';
    }
    
    // Detectar momento del día
    if (_containsAnyKeyword(lowerMessage, ['mañana', 'desayuno', 'levantarme'])) {
      analysis['Momento'] = 'Matutino - considerar hábitos de mañana';
    } else if (_containsAnyKeyword(lowerMessage, ['noche', 'cena', 'dormir'])) {
      analysis['Momento'] = 'Nocturno - enfocar en rutina vespertina';
    }
    
    // Detectar relación con comidas
    if (_containsAnyKeyword(lowerMessage, ['después de comer', 'tras la comida', 'post comida'])) {
      analysis['Relación con comidas'] = 'Post-prandial - síntomas después de comer';
    } else if (_containsAnyKeyword(lowerMessage, ['antes de comer', 'en ayunas', 'estómago vacío'])) {
      analysis['Relación con comidas'] = 'Pre-prandial - síntomas con estómago vacío';
    }
    
    // Detectar duración de síntomas
    if (_containsAnyKeyword(lowerMessage, ['hace días', 'hace semanas', 'hace tiempo', 'crónico'])) {
      analysis['Duración'] = 'Crónica - síntomas persistentes';
    } else if (_containsAnyKeyword(lowerMessage, ['hoy', 'ahora', 'recién', 'de repente'])) {
      analysis['Duración'] = 'Aguda - síntomas recientes';
    }
    
    return analysis;
  }
  
  /// Verifica si el texto contiene alguna palabra clave
  bool _containsAnyKeyword(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  Future<String> _getGeminiResponse(
    String message,
    String userId,
    List<ChatMessage> conversationHistory,
  ) async {
    final prompt = await _buildPrompt(
      message: message,
      conversationHistory: conversationHistory,
    );
    
    final requestBody = {
      'contents': [{
        'parts': [{
          'text': prompt
        }]
      }],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Lo siento, no pude procesar tu mensaje.';
      } else {
         // Logging detallado del error
         _logError('gemini_api', 'generateContent', 'HTTP ${response.statusCode}', {
           'status_code': response.statusCode,
           'response_body': response.body,
           'api_endpoint': '$_baseUrl/models/gemini-1.5-flash-latest:generateContent',
           'has_api_key': _apiKey.isNotEmpty,
         });
         
         // Manejo específico de errores
         switch (response.statusCode) {
           case 400:
             throw Exception('Solicitud inválida a la API de Gemini. Verifica el formato del mensaje.');
           case 401:
             throw Exception('API key de Gemini inválida o expirada. Contacta al administrador.');
           case 403:
             throw Exception('Sin permisos para usar la API de Gemini. Verifica tu cuenta.');
           case 404:
             throw Exception('Endpoint de la API de Gemini no encontrado. Verifica la configuración.');
           case 429:
             throw Exception('Límite de solicitudes excedido. Intenta de nuevo en unos minutos.');
           case 500:
           case 502:
           case 503:
             throw Exception('Servicio de Gemini temporalmente no disponible. Intenta más tarde.');
           default:
             throw Exception('Error en la API de Gemini: ${response.statusCode} - ${response.body}');
         }
       }
    } catch (e) {
       if (e.toString().contains('TimeoutException')) {
         _logError('gemini_api', 'generateContent', 'Timeout', {
           'error_type': 'timeout',
           'timeout_duration': '30 seconds',
         });
         throw Exception('Timeout al conectar con la API de Gemini. Verifica tu conexión.');
       }
       if (e.toString().contains('SocketException')) {
         _logError('gemini_api', 'generateContent', 'Connection Error', {
           'error_type': 'socket_exception',
           'error_details': e.toString(),
         });
         throw Exception('Error de conexión con la API de Gemini. Verifica tu internet.');
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
    
    return await _deepLearningDatasource!.analyzeGastritisRisk(
      userId: userId,
      userHabits: userHabits,
    );
  }

  /// Obtiene respuesta del backend de deep learning usando el endpoint de chat
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
      
      final context = {
        'message_type': 'gastritis_consultation',
        'extracted_symptoms': extractedSymptoms,
        'user_habits': extractedHabits,
        'message_length': message.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📊 Síntomas extraídos: ${extractedSymptoms.keys.join(", ")}');
      print('🔍 Hábitos detectados: ${extractedHabits.keys.join(", ")}');

      // Llamada con timeout para evitar bloqueos
      final response = await _deepLearningDatasource!.sendChatMessage(
        userId: userId,
        message: message,
        sessionId: sessionId,
        context: context,
        includePrediction: true,
      ).timeout(const Duration(seconds: 15));
      
      print('✅ Respuesta de Deep Learning recibida exitosamente');
      return response;
      
    } on TimeoutException {
      print('⏰ Timeout en llamada a Deep Learning backend (15s)');
      return _createFallbackDLResponse(message, extractedSymptoms: _extractSymptomsFromMessage(message));
    } on SocketException catch (e) {
      print('🌐 Error de conexión con Deep Learning backend: $e');
      return _createFallbackDLResponse(message, extractedSymptoms: _extractSymptomsFromMessage(message));
    } catch (e, stackTrace) {
      print('❌ Error inesperado en Deep Learning: $e');
      print('📍 Stack trace: $stackTrace');
      return _createFallbackDLResponse(message, extractedSymptoms: _extractSymptomsFromMessage(message));
    }
  }

  /// Extrae síntomas del mensaje del usuario con análisis mejorado
  Map<String, dynamic> _extractSymptomsFromMessage(String message) {
    final symptoms = <String, dynamic>{};
    final lowerMessage = message.toLowerCase();
    
    // Detectar dolor de estómago con intensidad
    if (lowerMessage.contains('dolor') && (lowerMessage.contains('estómago') || lowerMessage.contains('estomago'))) {
      symptoms['stomach_pain'] = true;
      symptoms['pain_duration'] = _extractDuration(lowerMessage);
      symptoms['pain_intensity'] = _extractIntensity(lowerMessage);
    }
    
    // Acidez y agruras
    if (lowerMessage.contains('acidez') || lowerMessage.contains('agruras') || lowerMessage.contains('reflujo')) {
      symptoms['heartburn'] = true;
      symptoms['heartburn_frequency'] = _extractFrequency(lowerMessage);
    }
    
    // Náuseas y vómitos
    if (lowerMessage.contains('náusea') || lowerMessage.contains('nausea') || 
        lowerMessage.contains('ganas de vomitar') || lowerMessage.contains('vómito')) {
      symptoms['nausea'] = true;
    }
    
    // Hinchazón e inflamación
    if (lowerMessage.contains('hinchazón') || lowerMessage.contains('inflamado') || 
        lowerMessage.contains('distensión') || lowerMessage.contains('pesadez')) {
      symptoms['bloating'] = true;
    }
    
    // Síntomas adicionales
    if (lowerMessage.contains('ardor') || lowerMessage.contains('quemazón')) {
      symptoms['burning_sensation'] = true;
    }
    
    if (lowerMessage.contains('inapetencia') || lowerMessage.contains('sin apetito') || 
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
    if (message.contains('momento') || message.contains('ahora')) return 'current';
    if (message.contains('crónico') || message.contains('siempre')) return 'chronic';
    return 'unknown';
  }
  
  /// Extrae intensidad del dolor del mensaje
  String _extractIntensity(String message) {
    if (message.contains('mucho') || message.contains('intenso') || message.contains('fuerte')) return 'high';
    if (message.contains('poco') || message.contains('leve') || message.contains('ligero')) return 'low';
    if (message.contains('moderado') || message.contains('regular')) return 'medium';
    return 'unknown';
  }
  
  /// Extrae frecuencia de síntomas del mensaje
  String _extractFrequency(String message) {
    if (message.contains('siempre') || message.contains('constantemente')) return 'constant';
    if (message.contains('frecuente') || message.contains('seguido')) return 'frequent';
    if (message.contains('ocasional') || message.contains('a veces')) return 'occasional';
    if (message.contains('rara vez') || message.contains('pocas veces')) return 'rare';
    return 'unknown';
  }
  
  /// Crea una respuesta de fallback cuando Deep Learning no está disponible
  Map<String, dynamic> _createFallbackDLResponse(String message, {Map<String, dynamic>? extractedSymptoms}) {
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
  Map<String, dynamic> _createEnhancedFallbackResponse(String message, String userId, String errorContext) {
    final symptoms = _extractSymptomsFromMessage(message);
    final habits = _extractHabitsFromMessage(message);
    
    // Análisis más sofisticado del mensaje
    String contextualResponse = '';
    List<String> smartActions = [];
    Map<String, dynamic> riskAssessment = {};
    
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('dolor') && (lowerMessage.contains('estómago') || lowerMessage.contains('abdominal'))) {
      contextualResponse = '🔍 **Análisis Local:** Detectamos síntomas gastrointestinales. '
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
    } else if (lowerMessage.contains('estrés') || lowerMessage.contains('ansiedad')) {
      contextualResponse = '🧠 **Análisis Local:** Identificamos factores de estrés que pueden afectar la salud digestiva. '
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
      contextualResponse = '💡 **Análisis Local:** Procesamos tu consulta con nuestro sistema de respaldo. '
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
      'message_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'respuesta_modelo': contextualResponse,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': 'fallback_session_${DateTime.now().millisecondsSinceEpoch}',
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
  
  /// Registra errores de Deep Learning para métricas y debugging
  void _logDeepLearningError(String operation, String error) {
    _logError('deep_learning', operation, error, {
      'dl_service_available': _deepLearningDatasource != null,
    });
  }

  /// Método general de logging de errores con contexto detallado
  void _logError(String service, String operation, String error, [Map<String, dynamic>? context]) {
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
    buffer.writeln('• Nivel de riesgo: ${_getRiskLevelText(analysis.riskLevel)}');
    buffer.writeln('• Confianza: ${(analysis.confidence * 100).toStringAsFixed(1)}%');
    
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
        buffer.writeln('• Evaluación de riesgo: ${riskAssessment['level'] ?? 'No determinado'}');
        if (riskAssessment['factors'] != null) {
          buffer.writeln('• Factores identificados: ${(riskAssessment['factors'] as List).join(', ')}');
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
        buffer.writeln('📊 Confianza del análisis: ${(confidence * 100).toStringAsFixed(1)}%');
      }
    }
    
    // Agregar análisis tradicional como fallback
    if (dlAnalysis != null && dlChatResponse == null) {
      buffer.writeln();
      buffer.writeln('📊 **Análisis de Riesgo:**');
      buffer.writeln('• Nivel de riesgo: ${_getRiskLevelText(dlAnalysis.riskLevel)}');
      buffer.writeln('• Confianza: ${(dlAnalysis.confidence * 100).toStringAsFixed(1)}%');
      
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
    // Normalizar el texto primero
    String normalized = response
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Máximo 2 saltos de línea consecutivos
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalizar espacios
        .replaceAll(RegExp(r'^[•*-]\s*', multiLine: true), '• ') // Unificar bullets
        .replaceAll(RegExp(r'^\s*\d+\.\s+(.+)$', multiLine: true), '• \$1') // Convertir listas numeradas
        .replaceAll(RegExp(r'^#{1,3}\s*(.+)', multiLine: true), '\$1') // Limpiar títulos
        .trim();

    // Eliminar marcadores markdown y aplicar formato de texto
    String formatted = normalized
        .replaceAll(RegExp(r'\*\*([^*]+?)\*\*'), '\$1') // Eliminar negritas **texto**
        .replaceAll(RegExp(r'\*([^*]+?)\*'), '\$1') // Eliminar cursivas *texto*
        .replaceAll(RegExp(r'__([^_]+?)__'), '\$1') // Eliminar negritas __texto__
        .replaceAll(RegExp(r'_([^_]+?)_'), '\$1'); // Eliminar cursivas _texto_

    // Resaltar palabras clave médicas importantes con emojis
    formatted = _highlightMedicalKeywords(formatted);

    return formatted;
  }

  /// Resalta palabras clave médicas importantes con emojis y formato
  String _highlightMedicalKeywords(String text) {
    // Palabras clave médicas importantes
    final medicalKeywords = {
      'gastritis': '🔥 GASTRITIS',
      'dolor de estómago': '⚠️ DOLOR DE ESTÓMAGO',
      'acidez': '🔥 ACIDEZ',
      'reflujo': '⬆️ REFLUJO',
      'úlcera': '🚨 ÚLCERA',
      'importante': '❗ IMPORTANTE',
      'recomendación': '💡 RECOMENDACIÓN',
      'consejo': '💡 CONSEJO',
      'atención': '⚠️ ATENCIÓN',
      'evitar': '🚫 EVITAR',
      'reducir': '📉 REDUCIR',
      'aumentar': '📈 AUMENTAR',
      'mejorar': '✅ MEJORAR',
      'prevenir': '🛡️ PREVENIR',
      'controlar': '🎯 CONTROLAR',
    };

    String highlighted = text;
    
    // Aplicar resaltado a palabras clave
    medicalKeywords.forEach((keyword, replacement) {
      final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
      highlighted = highlighted.replaceAllMapped(regex, (match) => replacement);
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
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), '\$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), '\$1')
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
    
    if (lowerHabit.contains('comida') || lowerHabit.contains('alimento') || 
        lowerHabit.contains('come') || lowerHabit.contains('consume')) {
      return 'Alimentación';
    }
    
    if (lowerHabit.contains('ejercicio') || lowerHabit.contains('actividad') ||
        lowerHabit.contains('camina') || lowerHabit.contains('deporte')) {
      return 'Ejercicio';
    }
    
    if (lowerHabit.contains('agua') || lowerHabit.contains('bebe') ||
        lowerHabit.contains('hidrata')) {
      return 'Hidratación';
    }
    
    if (lowerHabit.contains('sueño') || lowerHabit.contains('dormir') ||
        lowerHabit.contains('descanso')) {
      return 'Descanso';
    }
    
    if (lowerHabit.contains('estrés') || lowerHabit.contains('relajación') ||
        lowerHabit.contains('meditación')) {
      return 'Bienestar Mental';
    }
    
    return 'General';
  }

  /// Determina el tipo de hábito
  String _determineHabitType(String habit) {
    final lowerHabit = habit.toLowerCase();
    
    if (lowerHabit.contains('evita') || lowerHabit.contains('evitar') ||
        lowerHabit.contains('no') || lowerHabit.contains('reduce')) {
      return 'Evitar';
    }
    
    return 'Adoptar';
  }

  /// Sugiere frecuencia para el hábito
  String _suggestFrequency(String habit) {
    final lowerHabit = habit.toLowerCase();
    
    if (lowerHabit.contains('diario') || lowerHabit.contains('cada día') ||
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
    if (lowerMessage.contains('picante') || lowerMessage.contains('chile') || lowerMessage.contains('ají')) {
      habits['spicy_food_frequency'] = 4; // Frecuente
    }
    
    // Detectar síntomas de dolor
    if (lowerMessage.contains('dolor') && (lowerMessage.contains('estómago') || lowerMessage.contains('estomago'))) {
      habits['stomach_pain_frequency'] = 5; // Diario durante una semana
    }
    
    // Detectar patrones de alimentación
    if (lowerMessage.contains('comida rápida') || lowerMessage.contains('fast food')) {
      habits['fast_food_frequency'] = 3;
    }
    
    // Detectar estrés
    if (lowerMessage.contains('estrés') || lowerMessage.contains('estres') || lowerMessage.contains('ansiedad')) {
      habits['stress_level'] = 4;
    }
    
    return habits;
  }

  List<Map<String, dynamic>> _extractHabitsFromResponse(String content) {
    final habits = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Detectar recomendaciones de hábitos
      if (trimmedLine.contains('comidas pequeñas') || trimmedLine.contains('porciones más pequeñas')) {
        habits.add({
          'name': 'Comidas pequeñas y frecuentes',
          'description': 'Comer porciones más pequeñas cada 2-3 horas',
          'category': 'alimentacion',
          'frequency': 'daily',
          'times_per_day': 5,
        });
      }
      
      if (trimmedLine.contains('evita') && (trimmedLine.contains('picante') || trimmedLine.contains('irritantes'))) {
        habits.add({
          'name': 'Evitar alimentos irritantes',
          'description': 'Evitar comidas picantes, café, alcohol y cítricos',
          'category': 'alimentacion',
          'frequency': 'daily',
          'is_negative': true,
        });
      }
      
      if (trimmedLine.contains('hidrat') || trimmedLine.contains('agua')) {
        habits.add({
          'name': 'Mantener hidratación',
          'description': 'Beber suficiente agua durante el día',
          'category': 'hidratacion',
          'frequency': 'daily',
          'target_amount': '8 vasos',
        });
      }
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
  String _createGeminiFallbackResponse(String message, String userId, String error) {
    print('🔄 Generando respuesta de fallback para Gemini');
    
    // Analizar el mensaje para proporcionar una respuesta contextual
    final lowerMessage = message.toLowerCase();
    
    // Respuestas específicas para temas de salud digestiva
    if (lowerMessage.contains('dolor') || lowerMessage.contains('estómago') || lowerMessage.contains('gastritis')) {
      return '''Entiendo que tienes molestias estomacales. Aunque no puedo acceder al asistente de IA en este momento, puedo ofrecerte algunos consejos generales:

• Evita alimentos irritantes como picantes, ácidos o muy grasosos
• Come en porciones pequeñas y frecuentes
• Mantén horarios regulares de comida
• Reduce el estrés y practica técnicas de relajación
• Considera consultar con un profesional de la salud

¿Te gustaría que te ayude a crear un hábito específico para mejorar tu digestión?''';
    }
    
    if (lowerMessage.contains('hábito') || lowerMessage.contains('rutina') || lowerMessage.contains('crear')) {
      return '''Me encantaría ayudarte a crear nuevos hábitos saludables. Aunque el asistente de IA no está disponible temporalmente, puedo sugerirte algunos hábitos beneficiosos:

• Beber agua al despertar
• Caminar 30 minutos diarios
• Meditar 10 minutos antes de dormir
• Comer frutas y verduras en cada comida
• Mantener horarios regulares de sueño

¿Cuál de estos hábitos te interesa más desarrollar?''';
    }
    
    if (lowerMessage.contains('alimentación') || lowerMessage.contains('comida') || lowerMessage.contains('dieta')) {
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

  void dispose() {
    _httpClient.close();
  }
}