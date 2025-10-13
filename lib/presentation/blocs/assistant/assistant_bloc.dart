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
    on<ToggleTTS>(_onToggleTTS);
    on<MuteTTS>(_onMuteTTS);
    on<UnmuteTTS>(_onUnmuteTTS);
    on<StopCurrentTTS>(_onStopCurrentTTS);
    on<RestartTTS>(_onRestartTTS);
    on<ResetToInitialView>(_onResetToInitialView);
    
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
      
      // Limpiar cache de hábitos para nueva conversación
      habitAutoCreationService.habitExtractionService.clearCreatedHabitsCache();
      
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
      
      // Limpiar cache de hábitos al cambiar de sesión
      habitAutoCreationService.habitExtractionService.clearCreatedHabitsCache();
      
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
        // Generar título basado en el primer mensaje del usuario
        final sessionTitle = _generateSessionTitle(event.content);
        print('🔥 DEBUG: Título generado: "$sessionTitle"');
        
        currentSession = await chatRepository.createSession(
          event.userId,
          title: sessionTitle,
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
      
      print('🔥 DEBUG: ===== OBTENIENDO HÁBITOS SUGERIDOS =====');
      // Obtener hábitos sugeridos directamente de la respuesta del asistente
      final suggestedHabitsData = assistantResponse.suggestedHabits ?? [];
      print('🔥 DEBUG BLOC: Hábitos sugeridos recibidos: ${suggestedHabitsData.length}');
      
      if (suggestedHabitsData.isNotEmpty) {
        print('🔥 DEBUG BLOC: Lista de hábitos sugeridos:');
        for (int i = 0; i < suggestedHabitsData.length; i++) {
          final habit = suggestedHabitsData[i];
          print('🔥 DEBUG BLOC: Hábito $i: ${habit['name']} - ${habit['description']}');
        }
      } else {
        print('🔥 DEBUG BLOC: No se encontraron hábitos sugeridos en la respuesta');
      }
      
      // Crear mensaje del asistente con metadatos de hábitos sugeridos si se encontraron
      Map<String, dynamic>? metadata;
      if (suggestedHabitsData.isNotEmpty) {
        metadata = {
          'suggestedHabits': suggestedHabitsData,
        };
        print('🔥 DEBUG BLOC: Metadata de hábitos sugeridos creada con ${suggestedHabitsData.length} hábitos');
        print('🔥 DEBUG BLOC: Metadata completa: $metadata');
      } else {
        print('🔥 DEBUG BLOC: No se creará metadata de hábitos (lista vacía)');
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
        autoCreatedHabits: [], // Ya no creamos hábitos automáticamente
      ));
      
      print('🔥 DEBUG: ===== INICIANDO SÍNTESIS DE VOZ =====');
      print('🔥 DEBUG: TTS Habilitado: ${state.isTTSEnabled}, TTS Silenciado: ${state.isTTSMuted}');
      // Speak the assistant's response using TTS only if enabled and not muted
      if (assistantResponse.content.isNotEmpty && state.isTTSEnabled && !state.isTTSMuted) {
        // Limpiar el texto para TTS eliminando símbolos residuales
        final cleanTextForTTS = _cleanTextForTTS(assistantResponse.content);
        print('🔥 DEBUG: Texto original: "${assistantResponse.content}"');
        print('🔥 DEBUG: Texto limpio para TTS: "$cleanTextForTTS"');
        print('🔥 DEBUG: Llamando a voiceService.speak con texto limpio');
        await voiceService.speak(cleanTextForTTS);
        print('🔥 DEBUG: ===== SÍNTESIS DE VOZ COMPLETADA =====');
      } else {
        print('🔥 DEBUG: ===== SÍNTESIS DE VOZ OMITIDA (TTS deshabilitado o silenciado) =====');
      }
      
      // Procesar métricas y análisis en segundo plano
      _processMetricsInBackground(event.userId, currentSession.id, finalMessages);
      
      // Procesar Deep Learning en segundo plano solo si es necesario
      if (state.isDeepLearningEnabled && _shouldUseDeepLearning(event.content)) {
        print('🔥 DEBUG: ===== DEEP LEARNING ACTIVADO PARA ESTE MENSAJE =====');
        print('🔥 DEBUG: Mensaje: "${event.content}"');
        _processDeepLearningAndUpdateResponse(
          event.content, 
          event.userId, 
          currentSession.id, 
          assistantMessage,
          finalMessages
        );
      } else {
        print('🔥 DEBUG: ===== DEEP LEARNING OMITIDO - NO ES NECESARIO =====');
        print('🔥 DEBUG: Mensaje: "${event.content}"');
        print('🔥 DEBUG: DL Habilitado: ${state.isDeepLearningEnabled}, Requiere DL: ${_shouldUseDeepLearning(event.content)}');
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
      
      // Wait a moment for the summary to be displayed, then reset to initial view
      await Future.delayed(const Duration(seconds: 3));
      add(const ResetToInitialView());
      
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

  /// Procesa Deep Learning en segundo plano y actualiza la respuesta del asistente
  void _processDeepLearningAndUpdateResponse(
    String userMessage,
    String userId,
    String sessionId,
    ChatMessage assistantMessage,
    List<ChatMessage> messages,
  ) {
    Future.microtask(() async {
      try {
        print('🔥 DEBUG: ===== INICIANDO DEEP LEARNING EN SEGUNDO PLANO =====');
        
        // Procesar análisis de Deep Learning usando el repositorio de chat
        // Extraer síntomas básicos del mensaje del usuario
        final symptoms = _extractSymptomsFromMessage(userMessage);
        final habitHistory = <Map<String, dynamic>>[];
        
        final dlAnalysis = await chatRepository.analyzeGastritisRisk(
          userId: userId,
          symptoms: symptoms,
          habitHistory: habitHistory,
        );
        
        print('🔥 DEBUG: Deep Learning analysis obtenido: $dlAnalysis');
        
        // Crear un nuevo mensaje con el análisis de Deep Learning
        if (dlAnalysis.isNotEmpty && !isClosed) {
          // Crear contenido del análisis inteligente
          final analysisContent = _formatDeepLearningAnalysis(dlAnalysis);
          
          // Crear nuevo mensaje con el análisis inteligente
          final analysisMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sessionId: sessionId,
            content: analysisContent,
            type: MessageType.assistant,
            status: MessageStatus.sent,
            createdAt: DateTime.now(),
            metadata: {
              'isAnalysisMessage': true,
              'deepLearningAnalysis': dlAnalysis,
              'hasDeepLearning': true,
              'analysisType': 'intelligent_analysis',
            },
          );
          
          // Agregar el nuevo mensaje a la lista
          final updatedMessages = [...messages, analysisMessage];
          
          // Actualizar estado con el nuevo mensaje
          emit(state.copyWith(
            messages: updatedMessages,
            deepLearningAnalysis: dlAnalysis,
            clearError: true,
          ));
          
          // Guardar el nuevo mensaje (no editar el existente)
          await chatRepository.sendMessage(
            sessionId,
            analysisContent,
            MessageType.assistant,
            metadata: analysisMessage.metadata,
          );
          
          print('🔥 DEBUG: Nuevo mensaje de análisis inteligente creado');
        }
        
        // También procesar métricas de hábitos como antes
        _processDeepLearningInBackground(userId, messages);
        
      } catch (e) {
        print('🔥 DEBUG: Error en Deep Learning en segundo plano: $e');
        // No emitir error para no interrumpir la conversación
      }
    });
  }

  /// Combina la respuesta de Gemini con el análisis de Deep Learning
  String _combineGeminiWithDeepLearning(
    String geminiContent,
    Map<String, dynamic> dlAnalysis,
  ) {
    final buffer = StringBuffer();
    
    // Agregar la respuesta original de Gemini
    buffer.writeln(geminiContent);
    
    // Agregar separador
    buffer.writeln('\n---\n');
    
    // Agregar análisis de Deep Learning
    buffer.writeln('## 🤖 Análisis Inteligente');
    
    if (dlAnalysis.containsKey('confidence')) {
      final confidence = dlAnalysis['confidence'];
      buffer.writeln('**Confianza del análisis:** ${(confidence * 100).toStringAsFixed(1)}%');
    }
    
    if (dlAnalysis.containsKey('riskLevel')) {
      final riskLevel = dlAnalysis['riskLevel'];
      buffer.writeln('**Nivel de riesgo:** $riskLevel');
    }
    
    if (dlAnalysis.containsKey('suggestions') && dlAnalysis['suggestions'] is List) {
      buffer.writeln('\n**Recomendaciones específicas:**');
      for (final suggestion in dlAnalysis['suggestions']) {
        buffer.writeln('• $suggestion');
      }
    }
    
    if (dlAnalysis.containsKey('dlChatResponse') && dlAnalysis['dlChatResponse'] != null) {
      buffer.writeln('\n**Análisis detallado:**');
      buffer.writeln(dlAnalysis['dlChatResponse']);
    }
    
    return buffer.toString();
  }

  /// Formatea el análisis de Deep Learning de manera amigable para el usuario
  String _formatDeepLearningAnalysis(Map<String, dynamic> dlAnalysis) {
    final buffer = StringBuffer();
    
    // Título del análisis
    buffer.writeln('## 🤖 Análisis Inteligente');
    buffer.writeln('');
    
    // Nivel de riesgo
    if (dlAnalysis.containsKey('riskLevel')) {
      final riskLevel = dlAnalysis['riskLevel'];
      String emoji = '⚠️';
      if (riskLevel.toLowerCase().contains('bajo')) {
        emoji = '✅';
      } else if (riskLevel.toLowerCase().contains('alto')) {
        emoji = '🚨';
      }
      buffer.writeln('$emoji **Nivel de riesgo:** $riskLevel');
    }
    
    // Confianza del análisis
    if (dlAnalysis.containsKey('confidence')) {
      final confidence = dlAnalysis['confidence'];
      final confidencePercent = (confidence * 100).toStringAsFixed(1);
      buffer.writeln('📊 **Confianza del análisis:** $confidencePercent%');
    }
    
    // Recomendaciones específicas
    if (dlAnalysis.containsKey('suggestions') && dlAnalysis['suggestions'] is List) {
      buffer.writeln('');
      buffer.writeln('💡 **Recomendaciones:**');
      for (final suggestion in dlAnalysis['suggestions']) {
        buffer.writeln('• $suggestion');
      }
    }
    
    // Nota importante
    buffer.writeln('');
    buffer.writeln('⚕️ *Este análisis es una herramienta de apoyo. Siempre consulta con un profesional de la salud para un diagnóstico preciso.*');
    
    return buffer.toString();
  }

  /// Extrae hábitos sugeridos basados en la respuesta del asistente (sin crearlos automáticamente)
  Future<List<Habit>> _extractSuggestedHabitsFromResponse(
    AssistantResponse assistantResponse,
    String userMessage,
    String? userId,
  ) async {
    try {
      if (userId == null) {
        print('🔥 DEBUG: Usuario no autenticado, omitiendo extracción de hábitos');
        return [];
      }

      print('🔥 DEBUG: Analizando respuesta del asistente para extraer hábitos sugeridos');
      print('🔥 DEBUG: Contenido de respuesta: ${assistantResponse.content}');
      
      // Extraer hábitos sugeridos basados en el mensaje del usuario y la respuesta (sin crearlos)
      final suggestedHabits = await habitAutoCreationService.extractSuggestedHabits(
        assistantResponse: assistantResponse,
        userMessage: userMessage,
        userId: userId,
      );
      
      if (suggestedHabits.isNotEmpty) {
        print('🔥 DEBUG: Se encontraron ${suggestedHabits.length} hábitos sugeridos');
        for (final habit in suggestedHabits) {
          print('🔥 DEBUG: Hábito sugerido: ${habit.name}');
        }
      } else {
        print('🔥 DEBUG: No se encontraron hábitos sugeridos');
      }
      
      return suggestedHabits;
    } catch (e, stackTrace) {
      print('🔥 ERROR: Error extrayendo hábitos sugeridos: $e');
      print('🔥 ERROR: StackTrace: $stackTrace');
      // Retornar lista vacía en caso de error para no interrumpir la conversación
      return [];
    }
  }

  /// Determina si el mensaje del usuario requiere análisis de Deep Learning
  bool _shouldUseDeepLearning(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Palabras clave relacionadas con síntomas de gastritis
    final gastritisSymptoms = [
      'dolor', 'estómago', 'estomago', 'gastritis', 'acidez', 'ardor',
      'náuseas', 'nauseas', 'vómito', 'vomito', 'reflujo', 'indigestión',
      'hinchazón', 'hinchado', 'pesadez', 'malestar', 'quemazón',
      'punzadas', 'presión', 'distensión', 'abdominal', 'digestivo',
      'úlcera', 'ulcera', 'helicobacter', 'pylori'
    ];
    
    // Palabras clave relacionadas con análisis de riesgo
    final riskAnalysisKeywords = [
      'riesgo', 'análisis', 'analisis', 'evaluación', 'evaluacion',
      'diagnóstico', 'diagnostico', 'predicción', 'prediccion',
      'probabilidad', 'posibilidad', 'chequeo', 'revisión', 'revision'
    ];
    
    // Palabras clave relacionadas con hábitos alimentarios
    final foodHabitsKeywords = [
      'comida', 'alimentación', 'alimentacion', 'dieta', 'nutrición',
      'nutricion', 'alimentos', 'comer', 'desayuno', 'almuerzo',
      'cena', 'merienda', 'snack', 'bebida', 'alcohol', 'café',
      'picante', 'grasa', 'frituras', 'condimentos', 'especias'
    ];
    
    // Palabras clave relacionadas con estilo de vida
    final lifestyleKeywords = [
      'estrés', 'estres', 'ansiedad', 'sueño', 'dormir', 'ejercicio',
      'actividad', 'sedentario', 'trabajo', 'horarios', 'rutina',
      'medicamentos', 'pastillas', 'antiinflamatorios', 'aspirina'
    ];
    
    // Verificar si el mensaje contiene alguna palabra clave relevante
    bool hasGastritisSymptoms = gastritisSymptoms.any((symptom) => message.contains(symptom));
    bool hasRiskAnalysis = riskAnalysisKeywords.any((keyword) => message.contains(keyword));
    bool hasFoodHabits = foodHabitsKeywords.any((keyword) => message.contains(keyword));
    bool hasLifestyle = lifestyleKeywords.any((keyword) => message.contains(keyword));
    
    // Frases que NO requieren deep learning (conversación general)
    final generalConversationPhrases = [
      'hola', 'buenos días', 'buenas tardes', 'buenas noches',
      'gracias', 'de nada', 'por favor', 'disculpa', 'perdón',
      'cómo estás', 'como estas', 'qué tal', 'que tal',
      'ayuda', 'información', 'informacion', 'explicar',
      'entiendo', 'ok', 'vale', 'bien', 'perfecto'
    ];
    
    bool isGeneralConversation = generalConversationPhrases.any((phrase) => message.contains(phrase));
    
    // Si es conversación general y no tiene síntomas específicos, no usar DL
    if (isGeneralConversation && !hasGastritisSymptoms && !hasRiskAnalysis) {
      return false;
    }
    
    // Usar Deep Learning si:
    // 1. Menciona síntomas específicos de gastritis
    // 2. Solicita análisis de riesgo
    // 3. Habla de hábitos alimentarios en contexto de salud
    // 4. Menciona factores de estilo de vida relacionados con gastritis
    return hasGastritisSymptoms || hasRiskAnalysis || 
           (hasFoodHabits && (hasGastritisSymptoms || hasLifestyle)) ||
           (hasLifestyle && hasGastritisSymptoms);
  }

  // Manejadores de eventos TTS
  void _onToggleTTS(
    ToggleTTS event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(isTTSMuted: !state.isTTSMuted));
    
    // Si se está silenciando, detener TTS actual
    if (state.isTTSMuted) {
      voiceService.stopSpeaking();
    }
  }

  void _onMuteTTS(
    MuteTTS event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(isTTSMuted: true));
    voiceService.stopSpeaking();
  }

  void _onUnmuteTTS(
    UnmuteTTS event,
    Emitter<AssistantState> emit,
  ) {
    emit(state.copyWith(isTTSMuted: false));
  }

  void _onStopCurrentTTS(
    StopCurrentTTS event,
    Emitter<AssistantState> emit,
  ) {
    voiceService.stopSpeaking();
    emit(state.copyWith(isPlayingAudio: false));
  }

  void _onRestartTTS(
    RestartTTS event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      // Desmutear TTS si está silenciado
      emit(state.copyWith(isTTSMuted: false));
      
      // Limpiar el texto para TTS eliminando símbolos residuales
      final cleanTextForTTS = _cleanTextForTTS(event.content);
      
      // Reiniciar la lectura del contenido
      await voiceService.speak(cleanTextForTTS);
    } catch (e) {
      print('❌ Error al reiniciar TTS: $e');
    }
  }

  void _onResetToInitialView(
    ResetToInitialView event,
    Emitter<AssistantState> emit,
  ) {
    // Reset to initial state but keep chat sessions
    emit(state.copyWith(
      clearCurrentSession: true,
      messages: [],
      textInput: '',
      partialTranscription: '',
      isTyping: false,
      isRecording: false,
      isPlayingAudio: false,
      clearError: true,
      autoCreatedHabits: [],
    ));
    
    // Stop any ongoing TTS
    voiceService.stopSpeaking();
  }

  /// Extrae síntomas básicos del mensaje del usuario para análisis de Deep Learning
  Map<String, dynamic> _extractSymptomsFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    final symptoms = <String, dynamic>{};
    
    // Detectar dolor de estómago
    if (lowerMessage.contains('dolor') && (lowerMessage.contains('estómago') || lowerMessage.contains('estomago'))) {
      symptoms['stomachpain'] = true;
    }
    
    // Detectar reflujo
    if (lowerMessage.contains('reflujo') || lowerMessage.contains('acidez')) {
      symptoms['heartburn'] = true;
    }
    
    // Detectar náuseas
    if (lowerMessage.contains('náusea') || lowerMessage.contains('nausea') || lowerMessage.contains('mareo')) {
      symptoms['nausea'] = true;
    }
    
    // Detectar vómito
    if (lowerMessage.contains('vómito') || lowerMessage.contains('vomito')) {
      symptoms['vomiting'] = true;
    }
    
    // Detectar pérdida de apetito
    if (lowerMessage.contains('apetito') || lowerMessage.contains('hambre')) {
      symptoms['appetite_loss'] = true;
    }
    
    return symptoms;
  }

  /// Limpia el texto para TTS eliminando símbolos residuales y caracteres no deseados
  String _cleanTextForTTS(String text) {
    String cleanText = text;
    
    // PRIMERO: Extraer contenido de markdown antes de eliminar símbolos
    // Extraer contenido de negritas **texto** y __texto__
    cleanText = cleanText.replaceAllMapped(RegExp(r'\*\*([^*]+?)\*\*'), (match) => match.group(1)!);
    cleanText = cleanText.replaceAllMapped(RegExp(r'__([^_]+?)__'), (match) => match.group(1)!);
    
    // Extraer contenido de cursivas *texto* y _texto_
    cleanText = cleanText.replaceAllMapped(RegExp(r'\*([^*]+?)\*'), (match) => match.group(1)!);
    cleanText = cleanText.replaceAllMapped(RegExp(r'_([^_]+?)_'), (match) => match.group(1)!);
    
    // Extraer contenido de headers # texto
    cleanText = cleanText.replaceAllMapped(RegExp(r'^#{1,6}\s*(.+)', multiLine: true), (match) => match.group(1)!);
    
    // SEGUNDO: Limpiar símbolos y caracteres no deseados
    return cleanText
        // Eliminar símbolos $1, $2, etc. que puedan haber quedado
        .replaceAll(RegExp(r'\$\d+'), '')
        // Eliminar cualquier símbolo $ seguido de caracteres
        .replaceAll(RegExp(r'\$[a-zA-Z0-9]*'), '')
        // Eliminar TODOS los emojis (rangos Unicode completos)
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '') // Emoticons
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '') // Misc Symbols
        .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '') // Transport
        .replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), '') // Flags
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '') // Misc symbols
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '') // Dingbats
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '') // Supplemental Symbols
        .replaceAll(RegExp(r'[\u{1FA70}-\u{1FAFF}]', unicode: true), '') // Extended symbols
        // Eliminar asteriscos y guiones bajos residuales (ya se extrajo el contenido)
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        // Eliminar marcadores markdown adicionales
        .replaceAll(RegExp(r'`+'), '') // Code blocks
        .replaceAll(RegExp(r'~~'), '') // Strikethrough
        // Eliminar corchetes y llaves
        .replaceAll(RegExp(r'[\[\]{}]'), '')
        // Eliminar caracteres de control y símbolos especiales problemáticos
        .replaceAll(RegExp(r'[^\w\s\.,;:!?¿¡\-\(\)áéíóúüñÁÉÍÓÚÜÑ]'), '')
        // Limpiar espacios múltiples y normalizar
        .replaceAll(RegExp(r'\s+'), ' ')
        // Eliminar espacios al inicio y final
        .trim();
  }

  /// Genera un título para la sesión basado en el primer mensaje del usuario
  String _generateSessionTitle(String firstMessage) {
    // Limpiar el mensaje de caracteres especiales y espacios extra
    String cleanMessage = firstMessage
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Reemplazar múltiples espacios por uno solo
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u017F]'), '') // Mantener solo letras, números, espacios y acentos
        .trim();
    
    // Si el mensaje está vacío después de limpiar, usar título por defecto
    if (cleanMessage.isEmpty) {
      return 'Nueva conversación';
    }
    
    // Si el mensaje es de 20 caracteres o menos, usarlo completo
    if (cleanMessage.length <= 20) {
      return cleanMessage;
    }
    
    // Si es más largo, cortarlo a 17 caracteres y agregar "..."
    return '${cleanMessage.substring(0, 17)}...';
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