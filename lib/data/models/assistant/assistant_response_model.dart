import '../../../domain/entities/assistant/assistant_response.dart';

class AssistantResponseModel extends AssistantResponse {
  const AssistantResponseModel({
    required super.id,
    required super.sessionId,
    required super.content,
    required super.type,
    required super.timestamp,
    super.metadata,
    super.suggestions,
    super.audioUrl,
    super.audioDuration,
    super.confidence,
    super.isFromDeepLearning,
    super.analysisData,
    super.habitRecommendations,
    super.gastritisRiskLevel,
    super.extractedHabits,
    super.suggestedHabits,
    super.dlChatResponse,
    super.processedActions,
    super.isInitialResponse,
  });

  factory AssistantResponseModel.fromJson(Map<String, dynamic> json) {
    return AssistantResponseModel(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      content: json['content'] ?? '',
      type: _parseResponseType(json['type']),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration'] != null
          ? Duration(milliseconds: json['audio_duration'])
          : null,
      confidence: json['confidence']?.toDouble(),
      isFromDeepLearning: json['is_from_deep_learning'] ?? false,
      analysisData: json['analysis_data'] != null
          ? Map<String, dynamic>.from(json['analysis_data'])
          : null,
      habitRecommendations: json['habit_recommendations'] != null
          ? List<String>.from(json['habit_recommendations'])
          : null,
      gastritisRiskLevel: json['gastritis_risk_level'],
      extractedHabits: json['extracted_habits'] != null
          ? List<Map<String, dynamic>>.from(json['extracted_habits'])
          : null,
      suggestedHabits: json['suggested_habits'] != null
          ? List<Map<String, dynamic>>.from(json['suggested_habits'])
          : null,
      dlChatResponse: json['dl_chat_response'] != null
          ? Map<String, dynamic>.from(json['dl_chat_response'])
          : null,
      processedActions: json['processed_actions'] != null
          ? Map<String, dynamic>.from(json['processed_actions'])
          : null,
      isInitialResponse: json['is_initial_response'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'suggestions': suggestions,
      'audio_url': audioUrl,
      'audio_duration': audioDuration?.inMilliseconds,
      'confidence': confidence,
      'is_from_deep_learning': isFromDeepLearning,
      'analysis_data': analysisData,
      'habit_recommendations': habitRecommendations,
      'gastritis_risk_level': gastritisRiskLevel,
      'extracted_habits': extractedHabits,
      'suggested_habits': suggestedHabits,
      'dl_chat_response': dlChatResponse,
      'processed_actions': processedActions,
      'is_initial_response': isInitialResponse,
    };
  }

  factory AssistantResponseModel.fromSupabase(Map<String, dynamic> data) {
    return AssistantResponseModel(
      id: data['id']?.toString() ?? '',
      sessionId: data['session_id']?.toString() ?? '',
      content: data['content'] ?? '',
      type: _parseResponseType(data['type']),
      timestamp: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      suggestions: data['suggestions'] != null
          ? List<String>.from(data['suggestions'])
          : null,
      audioUrl: data['audio_url'],
      audioDuration: data['audio_duration'] != null
          ? Duration(milliseconds: data['audio_duration'])
          : null,
      confidence: data['confidence']?.toDouble(),
      isFromDeepLearning: data['is_from_deep_learning'] ?? false,
      analysisData: data['analysis_data'] != null
          ? Map<String, dynamic>.from(data['analysis_data'])
          : null,
      habitRecommendations: data['habit_recommendations'] != null
          ? List<String>.from(data['habit_recommendations'])
          : null,
      gastritisRiskLevel: data['gastritis_risk_level'],
      extractedHabits: data['extracted_habits'] != null
          ? List<Map<String, dynamic>>.from(data['extracted_habits'])
          : null,
      suggestedHabits: data['suggested_habits'] != null
          ? List<Map<String, dynamic>>.from(data['suggested_habits'])
          : null,
      dlChatResponse: data['dl_chat_response'] != null
          ? Map<String, dynamic>.from(data['dl_chat_response'])
          : null,
      processedActions: data['processed_actions'] != null
          ? Map<String, dynamic>.from(data['processed_actions'])
          : null,
      isInitialResponse: data['is_initial_response'] ?? false,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'type': type.toString().split('.').last,
      'created_at': timestamp.toIso8601String(),
      'metadata': metadata,
      'suggestions': suggestions,
      'audio_url': audioUrl,
      'audio_duration': audioDuration?.inMilliseconds,
      'confidence': confidence,
      'is_from_deep_learning': isFromDeepLearning,
      'analysis_data': analysisData,
      'habit_recommendations': habitRecommendations,
      'gastritis_risk_level': gastritisRiskLevel,
      'extracted_habits': extractedHabits,
      'suggested_habits': suggestedHabits,
      'dl_chat_response': dlChatResponse,
      'processed_actions': processedActions,
    };
  }

  static ResponseType _parseResponseType(dynamic type) {
    if (type == null) return ResponseType.text;
    
    switch (type.toString().toLowerCase()) {
      case 'text':
        return ResponseType.text;
      case 'voice':
        return ResponseType.voice;
      case 'suggestion':
        return ResponseType.suggestion;
      case 'healthadvice':
        return ResponseType.healthAdvice;
      case 'habitrecommendation':
        return ResponseType.habitRecommendation;
      case 'gastritisanalysis':
        return ResponseType.gastritisAnalysis;
      default:
        return ResponseType.text;
    }
  }

  @override
  AssistantResponseModel copyWith({
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
    return AssistantResponseModel(
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
}