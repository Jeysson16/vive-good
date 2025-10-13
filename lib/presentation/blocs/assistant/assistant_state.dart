import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../../../domain/entities/assistant/voice_animation_state.dart';
import '../../../domain/entities/habit.dart';

class AssistantState extends Equatable {
  final List<ChatSession> chatSessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final List<String> suggestions;
  final VoiceAnimationState voiceAnimationState;
  final Map<String, dynamic> assistantConfig;
  final Map<String, dynamic>? deepLearningAnalysis;
  final String textInput;
  final bool isLoading;
  final bool isTyping;
  final bool isRecording;
  final bool isPlayingAudio;
  final bool isConnected;
  final String? error;
  final String? currentAudioUrl;
  final double? recordingAmplitude;
  final String partialTranscription;
  final List<Habit> autoCreatedHabits;
  final bool isTTSEnabled;
  final bool isTTSMuted;

  const AssistantState({
    this.chatSessions = const [],
    this.currentSession,
    this.messages = const [],
    this.suggestions = const [],
    this.voiceAnimationState = const VoiceAnimationState.idle(),
    this.assistantConfig = const {},
    this.deepLearningAnalysis,
    this.textInput = '',
    this.isLoading = false,
    this.isTyping = false,
    this.isRecording = false,
    this.isPlayingAudio = false,
    this.isConnected = true,
    this.error,
    this.currentAudioUrl,
    this.recordingAmplitude,
    this.partialTranscription = '',
    this.autoCreatedHabits = const [],
    this.isTTSEnabled = true,
    this.isTTSMuted = false,
  });

  AssistantState copyWith({
    List<ChatSession>? chatSessions,
    ChatSession? currentSession,
    List<ChatMessage>? messages,
    List<String>? suggestions,
    VoiceAnimationState? voiceAnimationState,
    Map<String, dynamic>? assistantConfig,
    Map<String, dynamic>? deepLearningAnalysis,
    String? textInput,
    bool? isLoading,
    bool? isTyping,
    bool? isRecording,
    bool? isPlayingAudio,
    bool? isConnected,
    String? error,
    String? currentAudioUrl,
    double? recordingAmplitude,
    String? partialTranscription,
    List<Habit>? autoCreatedHabits,
    bool? isTTSEnabled,
    bool? isTTSMuted,
    bool clearError = false,
    bool clearCurrentSession = false,
    bool clearDeepLearningAnalysis = false,
    bool clearCurrentAudioUrl = false,
  }) {
    return AssistantState(
      chatSessions: chatSessions ?? this.chatSessions,
      currentSession: clearCurrentSession 
          ? null 
          : (currentSession ?? this.currentSession),
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      voiceAnimationState: voiceAnimationState ?? this.voiceAnimationState,
      assistantConfig: assistantConfig ?? this.assistantConfig,
      deepLearningAnalysis: clearDeepLearningAnalysis 
          ? null 
          : (deepLearningAnalysis ?? this.deepLearningAnalysis),
      textInput: textInput ?? this.textInput,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      isRecording: isRecording ?? this.isRecording,
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : (error ?? this.error),
      currentAudioUrl: clearCurrentAudioUrl 
          ? null 
          : (currentAudioUrl ?? this.currentAudioUrl),
      recordingAmplitude: recordingAmplitude ?? this.recordingAmplitude,
      partialTranscription: partialTranscription ?? this.partialTranscription,
      autoCreatedHabits: autoCreatedHabits ?? this.autoCreatedHabits,
      isTTSEnabled: isTTSEnabled ?? this.isTTSEnabled,
      isTTSMuted: isTTSMuted ?? this.isTTSMuted,
    );
  }

  @override
  List<Object?> get props => [
    chatSessions,
    currentSession,
    messages,
    suggestions,
    voiceAnimationState,
    assistantConfig,
    deepLearningAnalysis,
    textInput,
    isLoading,
    isTyping,
    isRecording,
    isPlayingAudio,
    isConnected,
    error,
    currentAudioUrl,
    recordingAmplitude,
    partialTranscription,
    autoCreatedHabits,
    isTTSEnabled,
    isTTSMuted,
  ];

  // Getters de conveniencia
  bool get hasError => error != null;
  bool get hasCurrentSession => currentSession != null;
  bool get hasMessages => messages.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get canSendMessage => textInput.trim().isNotEmpty && !isLoading;
  bool get isVoiceEnabled => assistantConfig['voice_enabled'] == true;
  bool get isAnimationEnabled => assistantConfig['animation_enabled'] == true;
  bool get isDeepLearningEnabled => assistantConfig['deep_learning_enabled'] == true;
  
  // Getters para análisis de deep learning
  double? get gastritisRiskLevel {
    if (deepLearningAnalysis == null) return null;
    final prediction = deepLearningAnalysis!['prediction'] as Map<String, dynamic>?;
    return prediction?['risk_level']?.toDouble();
  }
  
  String? get riskCategory {
    if (deepLearningAnalysis == null) return null;
    final prediction = deepLearningAnalysis!['prediction'] as Map<String, dynamic>?;
    return prediction?['risk_category'];
  }
  
  List<Map<String, dynamic>> get habitRecommendations {
    if (deepLearningAnalysis == null) return [];
    final recommendations = deepLearningAnalysis!['recommendations'] as List?;
    return recommendations?.cast<Map<String, dynamic>>() ?? [];
  }
  
  // Getters para mensajes
  List<ChatMessage> get userMessages => messages.where((m) => m.type == MessageType.user).toList();
  List<ChatMessage> get assistantMessages => messages.where((m) => m.type == MessageType.assistant).toList();
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  ChatMessage? get lastUserMessage => userMessages.isNotEmpty ? userMessages.last : null;
  ChatMessage? get lastAssistantMessage => assistantMessages.isNotEmpty ? assistantMessages.last : null;
  
  // Getters para sesiones de chat
  List<ChatSession> get activeSessions => chatSessions.where((s) => s.isActive).toList();
  ChatSession? get mostRecentSession {
    if (chatSessions.isEmpty) return null;
    return chatSessions.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
  }
  
  // Getters para estado de voz
  bool get isVoiceActive => isRecording || isPlayingAudio;
  bool get shouldShowVoiceAnimation => isVoiceActive && isAnimationEnabled;
  
  // Métodos de utilidad
  bool hasSession(String sessionId) {
    return chatSessions.any((s) => s.id == sessionId);
  }
  
  ChatMessage? getMessage(String messageId) {
    try {
      return messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }
  
  ChatSession? getSession(String sessionId) {
    try {
      return chatSessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }
  
  // Estado inicial
  factory AssistantState.initial() {
    return const AssistantState(
      assistantConfig: {
        'voice_enabled': true,
        'animation_enabled': true,
        'deep_learning_enabled': true,
        'suggestion_count': 3,
        'response_timeout': 30,
      },
    );
  }
  
  // Estado de carga
  AssistantState toLoading() {
    return copyWith(isLoading: true, clearError: true);
  }
  
  // Estado de error
  AssistantState toError(String errorMessage) {
    return copyWith(
      isLoading: false,
      isTyping: false,
      isRecording: false,
      error: errorMessage,
    );
  }
  
  // Estado de éxito
  AssistantState toSuccess() {
    return copyWith(
      isLoading: false,
      clearError: true,
    );
  }
  
  @override
  String toString() {
    return '''AssistantState {
      chatSessions: ${chatSessions.length},
      currentSession: ${currentSession?.id},
      messages: ${messages.length},
      suggestions: ${suggestions.length},
      isLoading: $isLoading,
      isTyping: $isTyping,
      isRecording: $isRecording,
      isPlayingAudio: $isPlayingAudio,
      isConnected: $isConnected,
      hasError: $hasError,
      textInput: "${textInput.length} chars",
      voiceAnimationState: $voiceAnimationState,
    }''';
  }
}