class AssistantResponse {
  final String content;
  final List<String> suggestions;
  final Map<String, dynamic> metadata;

  AssistantResponse({
    required this.content,
    this.suggestions = const [],
    this.metadata = const {},
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      content: json['content'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'suggestions': suggestions,
      'metadata': metadata,
    };
  }
}