import '../../entities/chat/chat_message.dart';
import '../../repositories/chat_repository.dart';

class GetChatMessagesUseCase {
  final ChatRepository repository;

  GetChatMessagesUseCase(this.repository);

  Future<List<ChatMessage>> call(String sessionId) async {
    return await repository.getChatMessages(sessionId);
  }
}