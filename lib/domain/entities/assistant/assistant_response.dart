import '../chat/chat_message.dart';

enum ResponseType {
  text,
  voice,
  suggestion,
  healthAdvice,
  habitRecommendation,
  gastritisAnalysis,
}

class AssistantResponse {
  final String id;
  final String sessionId;
  final String content;
  final ResponseType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String>? suggestions;
  final String? audioUrl;
  final Duration? audioDuration;
  final double? confidence;
  final bool isFromDeepLearning;
  final Map<String, dynamic>? analysisData;
  final List<String>? habitRecommendations;
  final String? gastritisRiskLevel;
  final List<Map<String, dynamic>>? extractedHabits;
  final List<Map<String, dynamic>>? suggestedHabits;
  final Map<String, dynamic>? dlChatResponse;
  final Map<String, dynamic>? processedActions;
  final bool isInitialResponse;

  const AssistantResponse({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.metadata,
    this.suggestions,
    this.audioUrl,
    this.audioDuration,
    this.confidence,
    this.isFromDeepLearning = false,
    this.analysisData,
    this.habitRecommendations,
    this.gastritisRiskLevel,
    this.extractedHabits,
    this.suggestedHabits,
    this.dlChatResponse,
    this.processedActions,
    this.isInitialResponse = false,
  });

  AssistantResponse copyWith({
    String? id,
    String? sessionId,
    String? content,
    ResponseType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<String>? suggestions,
    String? audioUrl,
    Duration? audioDuration,
    double? confidence,
    bool? isFromDeepLearning,
    Map<String, dynamic>? analysisData,
    List<String>? habitRecommendations,
    String? gastritisRiskLevel,
    List<Map<String, dynamic>>? extractedHabits,
    List<Map<String, dynamic>>? suggestedHabits,
    Map<String, dynamic>? dlChatResponse,
    Map<String, dynamic>? processedActions,
    bool? isInitialResponse,
  }) {
    return AssistantResponse(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      suggestions: suggestions ?? this.suggestions,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      confidence: confidence ?? this.confidence,
      isFromDeepLearning: isFromDeepLearning ?? this.isFromDeepLearning,
      analysisData: analysisData ?? this.analysisData,
      habitRecommendations: habitRecommendations ?? this.habitRecommendations,
      gastritisRiskLevel: gastritisRiskLevel ?? this.gastritisRiskLevel,
      extractedHabits: extractedHabits ?? this.extractedHabits,
      suggestedHabits: suggestedHabits ?? this.suggestedHabits,
      dlChatResponse: dlChatResponse ?? this.dlChatResponse,
      processedActions: processedActions ?? this.processedActions,
      isInitialResponse: isInitialResponse ?? this.isInitialResponse,
    );
  }

  ChatMessage toChatMessage() {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      content: content,
      status: MessageStatus.sent,
      type: _mapResponseTypeToMessageType(type),
      createdAt: timestamp,
      updatedAt: timestamp,
      metadata: metadata,
    );
  }

  MessageType _mapResponseTypeToMessageType(ResponseType responseType) {
    switch (responseType) {
      case ResponseType.voice:
      case ResponseType.suggestion:
      case ResponseType.text:
      case ResponseType.healthAdvice:
      case ResponseType.habitRecommendation:
      case ResponseType.gastritisAnalysis:
      default:
        return MessageType.assistant;
    }
  }

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;
  bool get hasAnalysisData => analysisData != null && analysisData!.isNotEmpty;
  bool get hasHabitRecommendations => habitRecommendations != null && habitRecommendations!.isNotEmpty;
  bool get hasGastritisAnalysis => gastritisRiskLevel != null;
  bool get hasExtractedHabits => extractedHabits != null && extractedHabits!.isNotEmpty;
  bool get hasSuggestedHabits => suggestedHabits != null && suggestedHabits!.isNotEmpty;
  bool get hasDlChatResponse => dlChatResponse != null && dlChatResponse!.isNotEmpty;
  bool get hasProcessedActions => processedActions != null && processedActions!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssistantResponse &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.content == content &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.confidence == confidence &&
        other.isFromDeepLearning == isFromDeepLearning;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        content.hashCode ^
        type.hashCode ^
        timestamp.hashCode ^
        confidence.hashCode ^
        isFromDeepLearning.hashCode;
  }

  @override
  String toString() {
    return 'AssistantResponse(id: $id, sessionId: $sessionId, content: $content, type: $type, timestamp: $timestamp, confidence: $confidence, isFromDeepLearning: $isFromDeepLearning)';
  }
}