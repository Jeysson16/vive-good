import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/chat/chat_message.dart';
import '../../../domain/entities/chat/chat_session.dart';
import '../../models/local/chat_message_local_model.dart';
import '../../services/database_service.dart';

class ChatLocalRepository {
  final DatabaseService _databaseService;

  ChatLocalRepository({required DatabaseService databaseService})
      : _databaseService = databaseService;

  /// Obtiene todos los mensajes de chat de un usuario
  Future<Either<Failure, List<ChatMessage>>> getChatMessages(String userId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at ASC',
      );

      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene mensajes de chat por rango de fechas
  Future<Either<Failure, List<ChatMessage>>> getChatMessagesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_messages',
        where: 'user_id = ? AND created_at BETWEEN ? AND ?',
        whereArgs: [
          userId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'created_at ASC',
      );

      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene los últimos N mensajes
  Future<Either<Failure, List<ChatMessage>>> getRecentChatMessages(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList()
          .reversed
          .toList(); // Revertir para orden cronológico

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Agrega un nuevo mensaje de chat
  Future<Either<Failure, void>> addChatMessage(ChatMessage message) async {
    try {
      final messageModel = ChatMessageLocalModel.fromEntity(message);
      
      await _databaseService.insertWithTimestamp('chat_messages', messageModel.toMap());
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Actualiza un mensaje de chat
  Future<Either<Failure, void>> updateChatMessage(ChatMessage message) async {
    try {
      final messageModel = ChatMessageLocalModel.fromEntity(message);
      
      await _databaseService.updateWithTimestamp(
        'chat_messages',
        messageModel.toMap(),
        'id = ?',
        [message.id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Elimina un mensaje de chat
  Future<Either<Failure, void>> deleteChatMessage(String id) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'chat_messages',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene mensajes no sincronizados
  Future<Either<Failure, List<ChatMessage>>> getUnsyncedMessages() async {
    try {
      final maps = await _databaseService.getUnsyncedRecords('chat_messages');
      
      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Marca un mensaje como sincronizado
  Future<Either<Failure, void>> markMessageAsSynced(String id) async {
    try {
      await _databaseService.markAsSynced('chat_messages', id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Guarda mensaje desde el servidor
  Future<Either<Failure, void>> saveMessageFromServer(ChatMessage message) async {
    try {
      final messageModel = ChatMessageLocalModel.fromEntity(message, isSynced: true);
      final db = await _databaseService.database;
      
      await db.insert(
        'chat_messages',
        messageModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Limpia todos los mensajes de un usuario
  Future<Either<Failure, void>> clearUserMessages(String userId) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Limpia todos los mensajes
  Future<Either<Failure, void>> clearAllMessages() async {
    try {
      final db = await _databaseService.database;
      
      await db.delete('chat_messages');
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Busca mensajes por contenido
  Future<Either<Failure, List<ChatMessage>>> searchMessages(
    String userId,
    String query,
  ) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_messages',
        where: 'user_id = ? AND content LIKE ?',
        whereArgs: [userId, '%$query%'],
        orderBy: 'created_at DESC',
      );

      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene estadísticas de mensajes
  Future<Either<Failure, Map<String, dynamic>>> getMessageStats(String userId) async {
    try {
      final db = await _databaseService.database;
      
      // Total de mensajes
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE user_id = ?',
        [userId],
      );
      
      // Mensajes del usuario
      final userMessagesResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE user_id = ? AND is_user_message = 1',
        [userId],
      );
      
      // Mensajes del asistente
      final assistantMessagesResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE user_id = ? AND is_user_message = 0',
        [userId],
      );
      
      // Primer mensaje
      final firstMessageResult = await db.query(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at ASC',
        limit: 1,
      );
      
      // Último mensaje
      final lastMessageResult = await db.query(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      final stats = {
        'total_messages': totalResult.first['count'] as int,
        'user_messages': userMessagesResult.first['count'] as int,
        'assistant_messages': assistantMessagesResult.first['count'] as int,
        'first_message_date': firstMessageResult.isNotEmpty 
            ? firstMessageResult.first['created_at'] as String
            : null,
        'last_message_date': lastMessageResult.isNotEmpty 
            ? lastMessageResult.first['created_at'] as String
            : null,
      };
      
      return Right(stats);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene mensajes por tipo
  Future<Either<Failure, List<ChatMessage>>> getMessagesByType(
    String userId,
    bool isUserMessage,
  ) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_messages',
        where: 'user_id = ? AND is_user_message = ?',
        whereArgs: [userId, isUserMessage ? 1 : 0],
        orderBy: 'created_at ASC',
      );

      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Cuenta mensajes no sincronizados
  Future<Either<Failure, int>> countUnsyncedMessages() async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chat_messages WHERE is_synced = 0',
      );
      
      final count = result.first['count'] as int;
      return Right(count);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene mensajes pendientes de sincronización
  Future<Either<Failure, List<ChatMessage>>> getPendingMessages() async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_messages',
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      final messages = maps
          .map((map) => ChatMessageLocalModel.fromMap(map).toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Obtiene una sesión por ID
  Future<Either<Failure, ChatSession>> getSession(String sessionId) async {
    try {
      final db = await _databaseService.database;
      
      final maps = await db.query(
        'chat_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Left(CacheFailure('Session not found'));
      }

      final sessionMap = maps.first;
      final session = ChatSession(
        id: sessionMap['id'] as String,
        userId: sessionMap['user_id'] as String,
        title: sessionMap['title'] as String,
        status: SessionStatus.values.firstWhere(
          (e) => e.name == sessionMap['status'],
          orElse: () => SessionStatus.active,
        ),
        createdAt: DateTime.parse(sessionMap['created_at'] as String),
        updatedAt: sessionMap['updated_at'] != null 
            ? DateTime.parse(sessionMap['updated_at'] as String) 
            : null,
      );

      return Right(session);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}