import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/chat/chat_message.dart';
import '../../repositories/chat_repository.dart';
import '../../../data/services/connectivity_service.dart';

class SaveMessageOfflineUseCase implements UseCase<void, SaveMessageOfflineParams> {
  final ChatRepository repository;
  final ConnectivityService connectivityService;

  SaveMessageOfflineUseCase({
    required this.repository,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, void>> call(SaveMessageOfflineParams params) async {
    try {
      // Siempre guardar el mensaje (el repositorio híbrido maneja la lógica offline)
      await repository.sendMessage(
        params.message.sessionId,
        params.message.content,
        params.message.type,
      );
      
      // Si está offline, mostrar mensaje informativo
      final connectivityStatus = connectivityService.currentStatus;
      if (connectivityStatus.isOffline) {
        // El mensaje se guardó localmente y se sincronizará cuando haya conexión
        return const Right(null);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

class SaveMessageOfflineParams extends Equatable {
  final ChatMessage message;
  final bool forceOffline;

  const SaveMessageOfflineParams({
    required this.message,
    this.forceOffline = false,
  });

  @override
  List<Object> get props => [message, forceOffline];
}