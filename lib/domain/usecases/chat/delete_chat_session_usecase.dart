import '../../repositories/chat_repository.dart';

class DeleteChatSessionUseCase {
  final ChatRepository repository;

  DeleteChatSessionUseCase(this.repository);

  Future<void> call(String sessionId) async {
    return await repository.deleteChatSession(sessionId);
  }
}