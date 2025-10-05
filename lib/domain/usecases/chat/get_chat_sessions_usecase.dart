import '../../entities/chat_session.dart';
import '../../repositories/chat_repository.dart';

class GetChatSessionsUseCase {
  final ChatRepository repository;

  GetChatSessionsUseCase(this.repository);

  Future<List<ChatSession>> call(String userId) async {
    return await repository.getUserSessions(userId);
  }
}