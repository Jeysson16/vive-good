import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/habit_repository.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../../../domain/entities/assistant_config.dart';
import '../../../domain/entities/deep_learning_analysis.dart';
import '../../../domain/entities/assistant/assistant_response.dart';
import '../../../domain/entities/habit.dart';
import '../../../data/services/voice_service.dart';
import '../../../data/services/metrics_extraction_service.dart';
import '../../../data/services/habit_extraction_service.dart';
import '../../../data/services/habit_auto_creation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assistant_event.dart';
import 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  final ChatRepository chatRepository;
  final HabitRepository habitRepository;
  final VoiceService voiceService;
  final MetricsExtractionService metricsService;
  final HabitAutoCreationService habitAutoCreationService;
  final String? userId;
  
  StreamSubscription? _speechSubscription;
  StreamSubscription? _partialSpeechSubscription;
  StreamSubscription? _listeningSubscription;
  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _ttsSubscription;
  Timer? _typingTimer;
  Timer? _suggestionTimer;

  AssistantBloc({
    required this.chatRepository,
    required this.habitRepository,
    VoiceService? voiceService,
    MetricsExtractionService? metricsService,
    HabitAutoCreationService? habitAutoCreationService,
    this.userId,
  }) : voiceService = voiceService ?? VoiceService(),
        metricsService = metricsService ?? MetricsExtractionService(Supabase.instance.client),
        habitAutoCreationService = habitAutoCreationService ?? HabitAutoCreationService(
          habitRepository: habitRepository,
          habitExtractionService: HabitExtractionService(),
        ),
        super(AssistantState.initial()) {
    
    // Initialize voice service
    _initializeVoiceService();
    
    // Registrar manejadores de eventos
    on<InitializeAssistant>(_onInitializeAssistant);
    on<LoadChatSessions>(_onLoadChatSessions);
    on<CreateNewChatSession>(_onCreateNewChatSession);
    on<SelectChatSession>(_onSelectChatSession);
    on<SendTextMessage>(_onSendTextMessage);
    on<StartVoiceRecording>(_onStartVoiceRecording);
    on<StopVoiceRecording>(_onStopVoiceRecording);
    on<StartVoicePlayback>(_onStartVoicePlayback);
    on<StopVoicePlayback>(_onStopVoicePlayback);
    on<LoadSuggestions>(_onLoadSuggestions);
    on<SelectSuggestion>(_onSelectSuggestion);
    on<AnalyzeUserHabits>(_onAnalyzeUserHabits);
    on<UpdateTextInput>(_onUpdateTextInput);
    on<ClearTextInput>(_onClearTextInput);
    on<ClearError>(_onClearError);
    on<UpdateVoiceAnimation>(_onUpdateVoiceAnimation);
    on<UpdateConfiguration>(_onUpdateConfiguration);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<DeleteChatSession>(_onDeleteChatSession);
    on<UpdateSessionTitle>(_onUpdateSessionTitle);
    on<RefreshData>(_onRefreshData);
    on<CompleteChatSession>(_onCompleteChatSession);
    
    // Cargar datos iniciales solo si tenemos un userId válido
    if (userId != null && userId!.isNotEmpty) {
      add(LoadChatSessions(userId!));
      add(LoadSuggestions(
        userId: userId!,
        currentContext: 'general',
      ));
    }
  }

  /// Initialize voice service and set up listeners
  Future<void> _initializeVoiceService() async {
    try {
      final initialized = await voiceService.initialize();
      if (initialized) {
        _setupVoiceListeners();
      }
    } catch (e) {
      // Handle initialization error
    }
  }
  
  /// Set up voice service listeners
  void _setupVoiceListeners() {
    // Listen to speech recognition results
    _speechSubscription = voiceService.speechResultStream.listen((text) {
      print('🔥 DEBUG: Received final speech result: "$text"');
      if (text.isNotEmpty) {
        print('🔥 DEBUG: Auto-sending message to assistant with: "$text"');
        // Automatically send the transcribed text to the assistant
        add(SendTextMessage(
          content: text,
          userId: userId ?? 'anonymous_user',
        ));
        // Also update the text input for UI purposes
        add(UpdateTextInput(text));
      }
    });
    
    // Listen to partial speech recognition results for real-time transcription
    _partialSpeechSubscription = voiceService.partialSpeechStream.listen((partialText) {
      print('DEBUG: Received partial transcription: "$partialText"');
      emit(state.copyWith(partialTranscription: partialText));
    });
    
    // Listen to listening state changes
    _listeningSubscription = voiceService.listeningStream.listen((isListening) {
      emit(state.copyWith(isRecording: isListening));
    });
    
    // Listen to amplitude changes for voice animation
    _amplitudeSubscription = voiceService.amplitudeStream.listen((amplitude) {
      emit(state.copyWith(recordingAmplitude: amplitude));
    });
    
    // Listen to TTS state changes
    _ttsSubscription = voiceService.ttsStateStream.listen((isSpeaking) {
      emit(state.copyWith(isPlayingAudio: isSpeaking));
    });
  }



  // Manejadores de eventos
  Future<void> _onLoadChatSessions(
    LoadChatSessions event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.toLoading());
      
      final sessions = await chatRepository.getUserSessions(event.userId);
      
      emit(state.copyWith(
        chatSessions: sessions,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.toError('Error al cargar sesiones de chat: ${e.toString()}'));
    }
  }

  Future<void> _onCreateNewChatSession(
    CreateNewChatSession event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.toLoading());
      
      final session = await chatRepository.createSession(
        event.userId,
        title: event.title ?? 'Nueva conversación',
      );
      
      final updatedSessions = <ChatSession>[session, ...state.chatSessions];
      
      emit(state.copyWith(
        chatSessions: updatedSessions,
        currentSession: session,
        messages: [],
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.toError('Error al crear sesión de chat: ${e.toString()}'));
    }
  }

  Future<void> _onSelectChatSession(
    SelectChatSession event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.toLoading());
      
      final session = state.getSession(event.sessionId);
      if (session == null) {
        emit(state.toError('Sesión de chat no encontrada'));
        return;
      }
      
      final messages = await chatRepository.getChatMessages(event.sessionId);
      
      emit(state.copyWith(
        currentSession: session,
        messages: messages,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.toError('Error al cargar mensajes: ${e.toString()}'));
    }
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<AssistantState> emit,
  ) async {
    if (event.content.trim().isEmpty) return;
    
    try {
      print('🔥 DEBUG: ===== INICIANDO _onSendTextMessage =====');
      print('🔥 DEBUG: Contenido del mensaje: "${event.content}"');
      print('🔥 DEBUG: UserId: ${event.userId}');
      
      // Crear sesión de chat si no existe
      ChatSession currentSession;
      List<ChatSession> updatedSessions = List<ChatSession>.from(state.chatSessions);
      
      if (state.currentSession == null) {
        print('🔥 DEBUG: Creando nueva sesión de chat');
        currentSession = await chatRepository.createSession(
          event.userId,
          title: 'Nueva conversación',
        );
        print('🔥 DEBUG: Sesión creada con ID: ${currentSession.id}');
        // Agregar la nueva sesión al inicio de la lista
        updatedSessions = <ChatSession>[currentSession, ...state.chatSessions];
      } else {
        currentSession = state.currentSession!;
        print('🔥 DEBUG: Usando sesión existente: ${currentSession.id}');
      }
      
      // Crear mensaje del usuario
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: currentSession.id,
        content: event.content,
        type: MessageType.user,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('🔥 DEBUG: Guardando mensaje del usuario en Supabase');
      // Guardar mensaje del usuario
      await chatRepository.createChatMessage(userMessage);
      print('🔥 DEBUG: Mensaje del usuario guardado con ID: ${userMessage.id}');
      
      // Actualizar estado con mensaje del usuario
      final updatedMessages = <ChatMessage>[...state.messages, userMessage];
      emit(state.copyWith(
        currentSession: currentSession,
        chatSessions: updatedSessions,
        messages: updatedMessages,
        textInput: '',
        isTyping: true,
        clearError: true,
      ));
      
      print('🔥 DEBUG: ===== LLAMANDO A GEMINI =====');
      print('🔥 DEBUG: Enviando mensaje a chatRepository.sendMessageToGemini');
      // Obtener respuesta del asistente
      final assistantResponse = await chatRepository.sendMessageToGemini(
        message: event.content,
        sessionId: currentSession.id,
        userId: event.userId,
        conversationHistory: updatedMessages,
      );
      
      print('🔥 DEBUG: ===== RESPUESTA DE GEMINI RECIBIDA =====');
      print('🔥 DEBUG: Contenido de la respuesta: "${assistantResponse.content}"');
      
      print('🔥 DEBUG: ===== INICIANDO CREACIÓN AUTOMÁTICA DE HÁBITOS =====');
      // Crear hábitos automáticamente basados en la respuesta del asistente
      final createdHabits = await _createHabitsFromAssistantResponse(
        assistantResponse,
        event.content,
        event.userId,
      );
      
      // Crear mensaje del asistente con metadatos de hábitos si se crearon
      Map<String, dynamic>? metadata;
      if (createdHabits.isNotEmpty) {
        metadata = {
          'autoCreatedHabits': createdHabits.map((habit) => habit.toMap()).toList(),
        };
      }
      
      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: currentSession.id,
        content: assistantResponse.content,
        type: MessageType.assistant,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata,
      );
      
      print('🔥 DEBUG: Guardando mensaje del asistente');
      // Guardar mensaje del asistente
      await chatRepository.createChatMessage(assistantMessage);
      
      // Actualizar estado final
      final finalMessages = <ChatMessage>[...updatedMessages, assistantMessage];
      emit(state.copyWith(
        messages: finalMessages,
        suggestions: assistantResponse.suggestions,
        isTyping: false,
        autoCreatedHabits: createdHabits,
      ));
      
      print('🔥 DEBUG: ===== INICIANDO SÍNTESIS DE VOZ =====');
      print('🔥 DEBUG: Llamando a voiceService.speak con: "${assistantResponse.content}"');
      // Speak the assistant's response using TTS
      if (assistantResponse.content.isNotEmpty) {
        await voiceService.speak(assistantResponse.content);
        print('🔥 DEBUG: ===== SÍNTESIS DE VOZ COMPLETADA =====');
      }
      
      // Procesar métricas y análisis en segundo plano
      _processMetricsInBackground(event.userId, currentSession.id, finalMessages);
      
      // Analizar hábitos si está habilitado (procesamiento en segundo plano)
      if (state.isDeepLearningEnabled) {
        _processDeepLearningInBackground(event.userId, finalMessages);
      }
      
    } catch (e) {
      print('🔥 DEBUG: ===== ERROR EN _onSendTextMessage =====');
      print('🔥 DEBUG: Error: $e');
      print('🔥 DEBUG: Stack trace: ${StackTrace.current}');
      emit(state.copyWith(
        isTyping: false,
        error: 'Error al enviar mensaje: ${e.toString()}',
      ));
    }
  }

  /// Handle start voice recording event
  Future<void> _onStartVoiceRecording(
    StartVoiceRecording event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.copyWith(
        isRecording: true,
        error: null,
      ));
      
      // Start speech recognition
      await voiceService.startListening();
      
    } catch (e) {
      emit(state.copyWith(
        isRecording: false,
        error: 'Error al iniciar grabación: $e',
      ));
    }
  }

  /// Handle stop voice recording event
  Future<void> _onStopVoiceRecording(
    StopVoiceRecording event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Stop speech recognition
      await voiceService.stopListening();
      
      emit(state.copyWith(
        isRecording: false,
        recordingAmplitude: 0.0,
        error: null,
      ));
      
      // If there's text input from speech recognition, send it
      if (state.textInput.isNotEmpty) {
        print('🔥 DEBUG: Disparando evento SendTextMessage con contenido: "${state.textInput}"');
        add(SendTextMessage(
          content: state.textInput,
          userId: userId ?? 'anonymous_user',
        ));
        add(ClearTextInput());
      } else {
        print('🔥 DEBUG: No hay texto para enviar, textInput está vacío');
      }
      
    } catch (e) {
      emit(state.copyWith(
        isRecording: false,
        error: 'Error al detener grabación: $e',
      ));
    }
  }

  /// Handle start voice playback event
  Future<void> _onStartVoicePlayback(
    StartVoicePlayback event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.copyWith(
        isPlayingAudio: true,
        currentAudioUrl: event.audioUrl,
        error: null,
      ));
      
      // Play audio using voice service
      await voiceService.playAudio(event.audioUrl);
      
    } catch (e) {
      emit(state.copyWith(
        isPlayingAudio: false,
        currentAudioUrl: null,
        error: 'Error al reproducir audio: $e',
      ));
    }
  }

  Future<void> _onStopVoicePlayback(
    StopVoicePlayback event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Stop audio playback
      await voiceService.stopAudio();
      
      emit(state.copyWith(
        isPlayingAudio: false,
        currentAudioUrl: null,
      ));
      
    } catch (e) {
      emit(state.toError('Error al detener audio: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSuggestions(
    LoadSuggestions event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Por ahora simulamos las sugerencias ya que no tenemos assistantRepository
      final suggestions = [
        'Cuéntame sobre tus síntomas',
        '¿Qué alimentos has consumido hoy?',
        '¿Cómo te sientes después de comer?'
      ];
      
      emit(state.copyWith(
        suggestions: suggestions,
        clearError: true,
      ));
      
    } catch (e) {
      // No emitir error para sugerencias, solo log
    }
  }

  Future<void> _onSelectSuggestion(
    SelectSuggestion event,
    Emitter<AssistantState> emit,
  ) async {
    // Enviar la sugerencia como mensaje de texto
    add(SendTextMessage(
      content: event.suggestion,
      userId: event.userId,
    ));
  }

  Future<void> _onAnalyzeUserHabits(
    AnalyzeUserHabits event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Extraer información relevante de los mensajes del usuario
      final userMessages = state.messages
          .where((msg) => msg.type == MessageType.user)
          .map((msg) => msg.content.toLowerCase())
          .toList();
      
      // Analizar síntomas y hábitos mencionados en los mensajes
      final symptoms = _extractSymptomsFromMessages(userMessages);
      final habitHistory = _extractHabitsFromMessages(userMessages);
      
      // Por ahora simulamos el análisis ya que no tenemos assistantRepository
      final analysis = DeepLearningAnalysis(
        id: 'analysis_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        type: AnalysisType.gastritisRisk,
        inputData: {'symptoms': symptoms, 'habits': habitHistory},
        results: {'gastritis_risk_score': 0.75},
        riskLevel: RiskLevel.medium,
        confidence: 0.75,
        recommendations: ['Evitar comidas picantes', 'Reducir el estrés'],
        timestamp: DateTime.now(),
        modelVersion: '1.0.0',
      );
      
      emit(state.copyWith(
        deepLearningAnalysis: analysis.toJson(),
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        error: 'Error en análisis de gastritis: ${e.toString()}',
      ));
    }
  }

  /// Extrae síntomas mencionados en los mensajes del usuario
  Map<String, dynamic> _extractSymptomsFromMessages(List<String> messages) {
    final symptoms = <String, dynamic>{};
    final allText = messages.join(' ').toLowerCase();
    
    // Síntomas comunes de gastritis
    final symptomKeywords = {
      'dolor_estomago': ['dolor de estómago', 'dolor estomacal', 'duele el estómago', 'dolor abdominal'],
      'acidez': ['acidez', 'agruras', 'reflujo', 'ardor estómago'],
      'nauseas': ['náuseas', 'nausea', 'ganas de vomitar', 'mareo'],
      'vomito': ['vómito', 'vomitar', 'devolver'],
      'hinchazon': ['hinchazón', 'inflamación', 'estómago hinchado', 'distensión'],
      'perdida_apetito': ['sin apetito', 'no tengo hambre', 'pérdida de apetito'],
      'eructos': ['eructos', 'gases', 'flatulencia'],
      'sensacion_llenura': ['sensación de llenura', 'estómago lleno', 'saciedad temprana'],
    };
    
    for (final entry in symptomKeywords.entries) {
      final symptom = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (allText.contains(keyword)) {
          symptoms[symptom] = true;
          break;
        }
      }
    }
    
    return symptoms;
  }

  /// Extrae hábitos mencionados en los mensajes del usuario
  List<Map<String, dynamic>> _extractHabitsFromMessages(List<String> messages) {
    final habits = <Map<String, dynamic>>[];
    final allText = messages.join(' ').toLowerCase();
    
    // Hábitos relacionados con gastritis
    final habitKeywords = {
      'comida_picante': ['picante', 'chile', 'salsa picante', 'comida condimentada'],
      'alcohol': ['alcohol', 'cerveza', 'vino', 'licor', 'bebida alcohólica'],
      'cafe': ['café', 'cafeína'],
      'tabaco': ['fumar', 'cigarro', 'tabaco', 'cigarrillo'],
      'estres': ['estrés', 'estresado', 'ansiedad', 'nervioso', 'preocupado'],
      'horarios_irregulares': ['horarios irregulares', 'como a deshoras', 'salto comidas'],
      'medicamentos': ['medicamento', 'pastilla', 'ibuprofeno', 'aspirina', 'antiinflamatorio'],
      'ejercicio': ['ejercicio', 'deporte', 'actividad física', 'gimnasio'],
    };
    
    for (final entry in habitKeywords.entries) {
      final habit = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (allText.contains(keyword)) {
          habits.add({
            'habit_type': habit,
            'frequency': 'mentioned',
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
        }
      }
    }
    
    return habits;
  }

  void _onUpdateTextInput(
    UpdateTextInput event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(textInput: event.text));
  }

  void _onClearTextInput(
    ClearTextInput event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(textInput: '', partialTranscription: ''));
  }

  void _onClearError(
    ClearError event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onUpdateVoiceAnimation(
    UpdateVoiceAnimation event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(
      voiceAnimationState: event.animationState,
      recordingAmplitude: event.animationState.amplitude,
    ));
  }

  Future<void> _onUpdateConfiguration(
    UpdateConfiguration event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Por ahora solo actualizamos el estado local
      // await assistantRepository.updateAssistantConfig(
      //   userId: event.userId ?? 'current_user_id',
      //   config: event.config,
      // );
      
      final updatedConfig = {...state.assistantConfig, ...event.config};
      emit(state.copyWith(
        assistantConfig: updatedConfig,
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.toError('Error al actualizar configuración: ${e.toString()}'));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Por ahora solo actualizamos el estado local
      // ChatMessage no tiene propiedad isRead, se omite esta funcionalidad
      // emit(state.copyWith(messages: state.messages));
      
    } catch (e) {
    }
  }

  Future<void> _onDeleteChatSession(
    DeleteChatSession event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      await chatRepository.deleteChatSession(event.sessionId);
      
      final updatedSessions = state.chatSessions
          .where((s) => s.id != event.sessionId)
          .toList();
      
      bool clearCurrent = state.currentSession?.id == event.sessionId;
      
      emit(state.copyWith(
        chatSessions: updatedSessions,
        clearCurrentSession: clearCurrent,
        messages: clearCurrent ? [] : state.messages,
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.toError('Error al eliminar sesión de chat: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSessionTitle(
    UpdateSessionTitle event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Crear sesión actualizada
      final updatedSession = state.chatSessions
          .firstWhere((s) => s.id == event.sessionId)
          .copyWith(title: event.newTitle);
      
      // Actualizar usando el método del repositorio
      await chatRepository.editChatSession(updatedSession);
      
      final updatedSessions = state.chatSessions.map((session) {
        if (session.id == event.sessionId) {
          return session.copyWith(title: event.newTitle);
        }
        return session;
      }).toList();
      
      ChatSession? updatedCurrent;
      if (state.currentSession?.id == event.sessionId) {
        updatedCurrent = state.currentSession!.copyWith(title: event.newTitle);
      }
      
      emit(state.copyWith(
        chatSessions: updatedSessions,
        currentSession: updatedCurrent,
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.toError('Error al actualizar título: ${e.toString()}'));
    }
  }

  Future<void> _onInitializeAssistant(
    InitializeAssistant event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      
      // Cargar configuración del asistente
      final config = await chatRepository.getAssistantConfig(event.userId);
      
      // Cargar sesiones de chat del usuario
      final sessions = await chatRepository.getUserSessions(event.userId);
      
      emit(state.copyWith(
        assistantConfig: config,
        chatSessions: sessions,
        isLoading: false,
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.toError('Error al inicializar asistente: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      
      final sessions = await chatRepository.getUserSessions(event.userId);
      
      emit(state.copyWith(
        chatSessions: sessions,
        isLoading: false,
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
      ).toError('Error al refrescar datos: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteChatSession(
    CompleteChatSession event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      
      // Obtener todos los mensajes de la sesión
      final messages = await chatRepository.getSessionMessages(event.sessionId);
      
      // Generar resumen de la sesión
      final summary = _generateChatSessionSummary(messages);
      
      // Crear mensaje de resumen
      final summaryMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: event.sessionId,
        content: summary,
        type: MessageType.system,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Guardar el mensaje de resumen
      await chatRepository.createChatMessage(summaryMessage);
      
      // Actualizar la lista de mensajes
      final updatedMessages = [...messages, summaryMessage];
      
      emit(state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        clearError: true,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
      ).toError('Error al completar sesión de chat: ${e.toString()}'));
    }
  }

  String _generateChatSessionSummary(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return '📋 **Resumen de Conversación**\n\nNo hay mensajes en esta conversación.';
    }

    final userMessages = messages.where((m) => m.type == MessageType.user).length;
    final assistantMessages = messages.where((m) => m.type == MessageType.assistant).length;
    final totalMessages = messages.length;
    
    // Obtener los temas principales basados en el contenido
    final topics = _extractMainTopics(messages);
    final keyInsights = _extractKeyInsights(messages);
    
    final summary = StringBuffer();
    summary.writeln('📋 **Resumen de Conversación**\n');
    summary.writeln('**Estadísticas:**');
    summary.writeln('• Total de mensajes: $totalMessages');
    summary.writeln('• Mensajes del usuario: $userMessages');
    summary.writeln('• Respuestas del asistente: $assistantMessages\n');
    
    if (topics.isNotEmpty) {
      summary.writeln('**Temas principales discutidos:**');
      for (final topic in topics) {
        summary.writeln('• $topic');
      }
      summary.writeln();
    }
    
    if (keyInsights.isNotEmpty) {
      summary.writeln('**Puntos clave:**');
      for (final insight in keyInsights) {
        summary.writeln('• $insight');
      }
      summary.writeln();
    }
    
    summary.writeln('**Recomendaciones:**');
    summary.writeln('• Revisa los puntos clave para futuras referencias');
    summary.writeln('• Considera aplicar las sugerencias proporcionadas');
    summary.writeln('• No dudes en iniciar una nueva conversación si tienes más preguntas\n');
    
    summary.writeln('✅ **Conversación completada exitosamente**');
    
    return summary.toString();
  }

  List<String> _extractMainTopics(List<ChatMessage> messages) {
    final topics = <String>[];
    final keywords = <String, int>{};
    
    // Analizar palabras clave en los mensajes
    for (final message in messages) {
      if (message.type == MessageType.user && message.content.length > 10) {
        final words = message.content.toLowerCase().split(' ');
        for (final word in words) {
          if (word.length > 4) {
            keywords[word] = (keywords[word] ?? 0) + 1;
          }
        }
      }
    }
    
    // Obtener las palabras más frecuentes
    final sortedKeywords = keywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generar temas basados en las palabras más frecuentes
    for (int i = 0; i < sortedKeywords.length && i < 3; i++) {
      final keyword = sortedKeywords[i].key;
      topics.add('Consultas sobre $keyword');
    }
    
    if (topics.isEmpty) {
      topics.add('Conversación general con el asistente');
    }
    
    return topics;
  }

  List<String> _extractKeyInsights(List<ChatMessage> messages) {
    final insights = <String>[];
    
    // Buscar mensajes del asistente que contengan información valiosa
    final assistantMessages = messages.where((m) => m.type == MessageType.assistant).toList();
    
    for (final message in assistantMessages) {
      if (message.content.length > 50) {
        // Extraer la primera oración como insight
        final sentences = message.content.split('.');
        if (sentences.isNotEmpty && sentences.first.length > 20) {
          insights.add(sentences.first.trim());
        }
      }
    }
    
    // Limitar a 3 insights principales
    return insights.take(3).toList();
  }

  /// Procesa métricas de conversación en segundo plano
  void _processMetricsInBackground(String userId, String sessionId, List<ChatMessage> messages) {
    // Ejecutar en un Future para no bloquear la UI
    Future.microtask(() async {
      try {
        // Obtener el último mensaje del usuario y la respuesta del asistente
        final userMessages = messages
            .where((msg) => msg.type == MessageType.user)
            .map((msg) => msg.content)
            .join(' ');
        
        final assistantMessages = messages
            .where((msg) => msg.type == MessageType.assistant)
            .map((msg) => msg.content)
            .join(' ');
        
        // Extraer conocimiento sobre síntomas
        await metricsService.extractSymptomsKnowledge(
          userId: userId,
          sessionId: sessionId,
          text: userMessages,
          geminiResponse: assistantMessages,
        );

        // Extraer aceptación tecnológica
        await metricsService.extractTechAcceptance(
          userId: userId,
          sessionId: sessionId,
          text: userMessages,
          geminiResponse: assistantMessages,
        );

        // Extraer hábitos alimenticios
        await metricsService.extractEatingHabits(
          userId: userId,
          sessionId: sessionId,
          text: userMessages,
          geminiResponse: assistantMessages,
        );

        // Extraer hábitos saludables
        await metricsService.extractHealthyHabits(
          userId: userId,
          sessionId: sessionId,
          text: userMessages,
          geminiResponse: assistantMessages,
        );

        // Guardar análisis completo de la conversación
        await metricsService.saveConversationAnalysis(
          userId: userId,
          sessionId: sessionId,
          userMessage: userMessages,
          geminiResponse: assistantMessages,
        );

        print('DEBUG: Métricas procesadas exitosamente para conversación $sessionId');
      } catch (e) {
        print('ERROR: Error procesando métricas: $e');
      }
    });
  }

  /// Procesa análisis de deep learning en segundo plano
  void _processDeepLearningInBackground(String userId, List<ChatMessage> messages) {
    // Ejecutar en un Future para no bloquear la UI
    Future.microtask(() async {
      try {
        // Extraer información relevante de los mensajes del usuario
        final userMessages = messages
            .where((msg) => msg.type == MessageType.user)
            .map((msg) => msg.content.toLowerCase())
            .toList();
        
        // Analizar síntomas y hábitos mencionados en los mensajes
        final symptoms = _extractSymptomsFromMessages(userMessages);
        final habitHistory = _extractHabitsFromMessages(userMessages);
        
        // Realizar análisis de deep learning
        final analysis = await chatRepository.analyzeGastritisRisk(
          userId: userId,
          symptoms: symptoms,
          habitHistory: habitHistory,
        );
        
        // Actualizar estado si el análisis es exitoso
        if (!isClosed) {
          emit(state.copyWith(
            deepLearningAnalysis: analysis,
            clearError: true,
          ));
        }
        
        print('DEBUG: Análisis de deep learning completado para usuario $userId');
      } catch (e) {
        print('ERROR: Error en análisis de deep learning: $e');
        // No emitir error en segundo plano para no interrumpir la conversación
      }
    });
  }

  /// Crea hábitos automáticamente basados en la respuesta del asistente
  Future<List<Habit>> _createHabitsFromAssistantResponse(
    AssistantResponse assistantResponse,
    String userMessage,
    String? userId,
  ) async {
    try {
      if (userId == null) {
        print('🔥 DEBUG: Usuario no autenticado, omitiendo creación de hábitos');
        return [];
      }

      print('🔥 DEBUG: Analizando respuesta del asistente para extraer hábitos');
      print('🔥 DEBUG: Contenido de respuesta: ${assistantResponse.content}');
      
      // Crear hábitos contextuales basados en el mensaje del usuario y la respuesta
      final createdHabits = await habitAutoCreationService.createContextualHabits(
        assistantResponse: assistantResponse,
        userMessage: userMessage,
        userId: userId,
      );
      
      if (createdHabits.isNotEmpty) {
        print('🔥 DEBUG: Se crearon ${createdHabits.length} hábitos automáticamente');
        for (final habit in createdHabits) {
          print('🔥 DEBUG: Hábito creado: ${habit.name}');
        }
      } else {
        print('🔥 DEBUG: No se encontraron hábitos para crear automáticamente');
      }
      
      return createdHabits;
    } catch (e, stackTrace) {
      print('🔥 ERROR: Error creando hábitos automáticamente: $e');
      print('🔥 ERROR: StackTrace: $stackTrace');
      // Retornar lista vacía en caso de error para no interrumpir la conversación
      return [];
    }
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    _partialSpeechSubscription?.cancel();
    _listeningSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _ttsSubscription?.cancel();
    _typingTimer?.cancel();
    _suggestionTimer?.cancel();
    voiceService.dispose();
    return super.close();
  }
}