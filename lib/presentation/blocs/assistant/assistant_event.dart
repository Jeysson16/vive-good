import 'package:equatable/equatable.dart';
import '../../../domain/entities/assistant/voice_animation_state.dart';
import '../../../domain/entities/chat/chat_message.dart';

abstract class AssistantEvent extends Equatable {
  const AssistantEvent();

  @override
  List<Object?> get props => [];
}

// Eventos de sesiones de chat
class LoadChatSessions extends AssistantEvent {
  final String userId;

  const LoadChatSessions(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateNewChatSession extends AssistantEvent {
  final String userId;
  final String? title;

  const CreateNewChatSession(this.userId, {this.title});

  @override
  List<Object?> get props => [userId, title];
}

class SelectChatSession extends AssistantEvent {
  final String sessionId;

  const SelectChatSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class DeleteChatSession extends AssistantEvent {
  final String sessionId;

  const DeleteChatSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

// Eventos de mensajes
class LoadMessages extends AssistantEvent {
  final String sessionId;

  const LoadMessages(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class SendTextMessage extends AssistantEvent {
  final String content;
  final String userId;
  final bool includeContext;

  const SendTextMessage({
    required this.content,
    required this.userId,
    this.includeContext = false,
  });

  @override
  List<Object?> get props => [content, userId, includeContext];
}

class SendVoiceMessage extends AssistantEvent {
  final String sessionId;
  final String audioPath;
  final String userId;

  const SendVoiceMessage({
    required this.sessionId,
    required this.audioPath,
    required this.userId,
  });

  @override
  List<Object?> get props => [sessionId, audioPath, userId];
}

class MessageReceived extends AssistantEvent {
  final ChatMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkMessageAsRead extends AssistantEvent {
  final String messageId;

  const MarkMessageAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

// Eventos de voz y animaciones
class StartVoiceRecording extends AssistantEvent {
  const StartVoiceRecording();
}

class StopVoiceRecording extends AssistantEvent {
  const StopVoiceRecording();
}

class StartVoicePlayback extends AssistantEvent {
  final String audioUrl;

  const StartVoicePlayback(this.audioUrl);

  @override
  List<Object?> get props => [audioUrl];
}

class StopVoicePlayback extends AssistantEvent {
  const StopVoicePlayback();
}

// Evento removido - duplicado más abajo

class ResetVoiceAnimation extends AssistantEvent {
  const ResetVoiceAnimation();
}

// Eventos de sugerencias
class LoadSuggestions extends AssistantEvent {
  final String userId;
  final String currentContext;

  const LoadSuggestions({
    required this.userId,
    required this.currentContext,
  });

  @override
  List<Object?> get props => [userId, currentContext];
}

class SelectSuggestion extends AssistantEvent {
  final String suggestion;
  final String sessionId;
  final String userId;

  const SelectSuggestion({
    required this.suggestion,
    required this.sessionId,
    required this.userId,
  });

  @override
  List<Object?> get props => [suggestion, sessionId, userId];
}

// Eventos de análisis con Deep Learning
class AnalyzeUserHabits extends AssistantEvent {
  final String userId;
  final Map<String, dynamic> userHabits;

  const AnalyzeUserHabits({
    required this.userId,
    required this.userHabits,
  });

  @override
  List<Object?> get props => [userId, userHabits];
}

class RequestHabitRecommendations extends AssistantEvent {
  final String userId;
  final String sessionId;

  const RequestHabitRecommendations({
    required this.userId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [userId, sessionId];
}

// Eventos de configuración
class InitializeAssistant extends AssistantEvent {
  final String userId;

  const InitializeAssistant({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadAssistantConfig extends AssistantEvent {
  const LoadAssistantConfig();
}

class UpdateAssistantConfig extends AssistantEvent {
  final Map<String, dynamic> config;

  const UpdateAssistantConfig(this.config);

  @override
  List<Object?> get props => [config];
}

class ToggleVoiceEnabled extends AssistantEvent {
  const ToggleVoiceEnabled();
}

class ToggleAnimationEnabled extends AssistantEvent {
  const ToggleAnimationEnabled();
}

class ToggleDeepLearning extends AssistantEvent {
  final bool enabled;

  const ToggleDeepLearning({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

// Eventos de error y estado
class ClearError extends AssistantEvent {
  const ClearError();
}

class ResetAssistantState extends AssistantEvent {
  const ResetAssistantState();
}

class CheckConnectivity extends AssistantEvent {
  const CheckConnectivity();
}

// Eventos de typing indicator
class StartTyping extends AssistantEvent {
  const StartTyping();
}

class StopTyping extends AssistantEvent {
  const StopTyping();
}

// Eventos de scroll y UI
class ScrollToBottom extends AssistantEvent {
  const ScrollToBottom();
}

class UpdateTextInput extends AssistantEvent {
  final String text;

  const UpdateTextInput(this.text);

  @override
  List<Object?> get props => [text];
}

class ClearTextInput extends AssistantEvent {
  const ClearTextInput();
}

// Eventos adicionales necesarios para el BLoC
class UpdateConfiguration extends AssistantEvent {
  final Map<String, dynamic> config;
  final String? userId;

  const UpdateConfiguration(this.config, {this.userId});

  @override
  List<Object?> get props => [config, userId];
}

class UpdateSessionTitle extends AssistantEvent {
  final String sessionId;
  final String newTitle;

  const UpdateSessionTitle(this.sessionId, this.newTitle);

  @override
  List<Object?> get props => [sessionId, newTitle];
}

class RefreshData extends AssistantEvent {
  final String userId;

  const RefreshData(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateVoiceAnimation extends AssistantEvent {
  final VoiceAnimationState animationState;

  const UpdateVoiceAnimation(this.animationState);

  @override
  List<Object?> get props => [animationState];
}

class CompleteChatSession extends AssistantEvent {
  final String sessionId;
  final String userId;

  const CompleteChatSession({
    required this.sessionId,
    required this.userId,
  });

  @override
  List<Object?> get props => [sessionId, userId];
}

// Eventos de TTS
class ToggleTTS extends AssistantEvent {
  const ToggleTTS();
}

class MuteTTS extends AssistantEvent {
  const MuteTTS();
}

class UnmuteTTS extends AssistantEvent {
  const UnmuteTTS();
}

class StopCurrentTTS extends AssistantEvent {
  const StopCurrentTTS();
}

class RestartTTS extends AssistantEvent {
  final String content;
  
  const RestartTTS({required this.content});
  
  @override
  List<Object?> get props => [content];
}

class ResetToInitialView extends AssistantEvent {
  const ResetToInitialView();
}

// VoiceAnimationState se define en domain/entities/assistant/voice_animation_state.dart