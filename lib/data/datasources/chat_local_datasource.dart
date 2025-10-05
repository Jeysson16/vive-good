import 'package:uuid/uuid.dart';
import 'package:vive_good_app/data/models/chat/chat_message_model.dart';
import 'package:vive_good_app/data/models/local/local_sync_operation_model.dart';
import 'package:vive_good_app/data/datasources/local_database_service.dart';
import 'package:vive_good_app/domain/entities/sync_operation.dart';

abstract class ChatLocalDataSource {
  Future<List<ChatMessageModel>> getChatHistory(String userId, {int limit = 50});
  Future<void> saveChatMessage(ChatMessageModel message);
  Future<void> updateChatMessage(String messageId, Map<String, dynamic> updates);
  Future<void> deleteChatMessage(String messageId);
  Future<void> clearChatHistory(String userId);
  Future<List<Map<String, dynamic>>> getMessagesNeedingSync();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final LocalDatabaseService _localDb;
  final Uuid _uuid = const Uuid();

  ChatLocalDataSourceImpl({required LocalDatabaseService localDb}) : _localDb = localDb;

  @override
  Future<List<ChatMessageModel>> getChatHistory(String userId, {int limit = 50}) async {
    // Obtener mensajes del metadata como JSON
    final messagesData = await _localDb.getMetadata('chat_messages_$userId');
    if (messagesData == null) return [];
    
    try {
      final List<dynamic> messagesList = messagesData['messages'] as List<dynamic>;
      final messages = messagesList
          .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Ordenar por fecha (más recientes primero) y limitar
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveChatMessage(ChatMessageModel message) async {
    // Obtener el usuario actual para determinar el userId
    final currentUser = await _localDb.getCurrentUser();
    final userId = currentUser?.id ?? 'anonymous';
    
    final messages = await getChatHistory(userId);
    
    // Agregar el nuevo mensaje
    messages.insert(0, message);
    
    // Mantener solo los últimos 100 mensajes para evitar crecimiento excesivo
    final limitedMessages = messages.take(100).toList();
    
    // Guardar en metadata
    final messagesJson = limitedMessages.map((m) => m.toJson()).toList();
    await _localDb.setMetadata('chat_messages_$userId', {'messages': messagesJson});
    
    // Crear operación de sincronización
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'chat_message',
        entityId: message.id,
        operationType: SyncOperationType.create,
        data: message.toJson(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<void> updateChatMessage(String messageId, Map<String, dynamic> updates) async {
    // Buscar el mensaje en los metadatos de chat
    final metadataKeys = ['chat_messages_${updates['userId'] ?? 'unknown'}'];
    
    for (final key in metadataKeys) {
       final messagesData = await _localDb.getMetadata(key);
       if (messagesData != null) {
         try {
           final List<dynamic> messagesList = messagesData['messages'] as List<dynamic>;
          final messages = messagesList
              .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          
          if (messageIndex != -1) {
            final message = messages[messageIndex];
            final updatedMessage = ChatMessageModel(
              id: message.id,
              sessionId: message.sessionId,
              content: updates['content'] ?? message.content,
              type: message.type,
              status: message.status,
              createdAt: message.createdAt,
              updatedAt: DateTime.now(),
              metadata: updates['metadata'] ?? message.metadata,
              parentMessageId: message.parentMessageId,
              isEdited: updates['is_edited'] ?? message.isEdited,
            );
            
            messages[messageIndex] = updatedMessage;
            
            // Guardar mensajes actualizados
             final updatedMessagesJson = messages.map((m) => m.toJson()).toList();
             await _localDb.setMetadata(key, {'messages': updatedMessagesJson});
            
            // Crear operación de sincronización
            final syncOperation = LocalSyncOperationModel.fromEntity(
              SyncOperation(
                id: _uuid.v4(),
                entityType: 'chat_message',
                entityId: messageId,
                operationType: SyncOperationType.update,
                data: updatedMessage.toJson(),
                status: SyncStatus.pending,
                createdAt: DateTime.now(),
              ),
            );
            await _localDb.saveSyncOperation(syncOperation);
            break;
          }
        } catch (e) {
          // Error al procesar mensajes, continuar con el siguiente
          continue;
        }
      }
    }
  }

  @override
  Future<void> deleteChatMessage(String messageId) async {
    // Buscar en todos los metadatos de chat posibles
    final currentUser = await _localDb.getCurrentUser();
    final searchKeys = currentUser != null 
        ? ['chat_messages_${currentUser.id}']
        : <String>[];
    
    for (final key in searchKeys) {
       final messagesData = await _localDb.getMetadata(key);
       if (messagesData != null) {
         try {
           final List<dynamic> messagesList = messagesData['messages'] as List<dynamic>;
          final messages = messagesList
              .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          
          if (messageIndex != -1) {
            messages.removeAt(messageIndex);
            
            // Guardar mensajes actualizados
             final updatedMessagesJson = messages.map((m) => m.toJson()).toList();
             await _localDb.setMetadata(key, {'messages': updatedMessagesJson});
            
            // Crear operación de sincronización para eliminación
            final syncOperation = LocalSyncOperationModel.fromEntity(
              SyncOperation(
                id: _uuid.v4(),
                entityType: 'chat_message',
                entityId: messageId,
                operationType: SyncOperationType.delete,
                data: {'id': messageId},
                status: SyncStatus.pending,
                createdAt: DateTime.now(),
              ),
            );
            await _localDb.saveSyncOperation(syncOperation);
            break;
          }
        } catch (e) {
          // Error al procesar mensajes, continuar con el siguiente
          continue;
        }
      }
    }
  }

  @override
  Future<void> clearChatHistory(String userId) async {
    await _localDb.deleteMetadata('chat_messages_$userId');
  }

  @override
  Future<List<Map<String, dynamic>>> getMessagesNeedingSync() async {
    final syncOperations = await _localDb.getPendingSyncOperations();
    return syncOperations
        .where((op) => op.entityType == 'chat_message')
        .map((op) => op.data)
        .toList();
  }
}