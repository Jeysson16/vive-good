import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper para manejar la base de datos SQLite local
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vive_good_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas de la base de datos
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de hábitos
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        frequency TEXT,
        target_count INTEGER,
        color TEXT,
        icon TEXT,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de progreso
    await db.execute('''
      CREATE TABLE progress (
        user_id TEXT PRIMARY KEY,
        total_habits INTEGER DEFAULT 0,
        completed_habits INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        points INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT,
        name TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de mensajes de chat
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        message TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        user_id TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de operaciones pendientes
    await db.execute('''
      CREATE TABLE pending_operations (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        error TEXT
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_habits_user_id ON habits(user_id)');
    await db.execute('CREATE INDEX idx_habits_synced ON habits(is_synced)');
    await db.execute('CREATE INDEX idx_progress_synced ON progress(is_synced)');
    await db.execute('CREATE INDEX idx_users_synced ON users(is_synced)');
    await db.execute('CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id)');
    await db.execute('CREATE INDEX idx_chat_messages_synced ON chat_messages(is_synced)');
    await db.execute('CREATE INDEX idx_pending_operations_type ON pending_operations(type)');
    await db.execute('CREATE INDEX idx_pending_operations_entity_id ON pending_operations(entity_id)');
  }

  /// Actualiza la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones futuras aquí
  }

  // ==================== MÉTODOS PARA HÁBITOS ====================

  /// Inserta un hábito
  Future<void> insertHabit(Map<String, dynamic> habit) async {
    final db = await database;
    await db.insert('habits', habit, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene todos los hábitos de un usuario
  Future<List<Map<String, dynamic>>> getHabitsByUserId(String userId) async {
    final db = await database;
    return await db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  /// Obtiene hábitos no sincronizados
  Future<List<Map<String, dynamic>>> getUnsyncedHabits() async {
    final db = await database;
    return await db.query(
      'habits',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  /// Marca un hábito como sincronizado
  Future<void> markHabitAsSynced(String habitId) async {
    final db = await database;
    await db.update(
      'habits',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// Elimina un hábito
  Future<void> deleteHabit(String habitId) async {
    final db = await database;
    await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  // ==================== MÉTODOS PARA PROGRESO ====================

  /// Inserta o actualiza el progreso de un usuario
  Future<void> insertOrUpdateProgress(Map<String, dynamic> progress) async {
    final db = await database;
    await db.insert('progress', progress, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene el progreso de un usuario
  Future<Map<String, dynamic>?> getProgressByUserId(String userId) async {
    final db = await database;
    final results = await db.query(
      'progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtiene progreso no sincronizado
  Future<List<Map<String, dynamic>>> getUnsyncedProgress() async {
    final db = await database;
    return await db.query(
      'progress',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  /// Marca el progreso como sincronizado
  Future<void> markProgressAsSynced(String userId) async {
    final db = await database;
    await db.update(
      'progress',
      {'is_synced': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== MÉTODOS PARA USUARIOS ====================

  /// Inserta o actualiza un usuario
  Future<void> insertOrUpdateUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene el usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtiene usuario no sincronizado
  Future<Map<String, dynamic>?> getUnsyncedUser() async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'is_synced = ?',
      whereArgs: [0],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Marca el usuario como sincronizado
  Future<void> markUserAsSynced(String userId) async {
    final db = await database;
    await db.update(
      'users',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== MÉTODOS PARA CHAT ====================

  /// Inserta un mensaje de chat
  Future<void> insertChatMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert('chat_messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene el historial de chat de un usuario
  Future<List<Map<String, dynamic>>> getChatMessagesByUserId(String userId) async {
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Obtiene mensajes no sincronizados
  Future<List<Map<String, dynamic>>> getUnsyncedChatMessages() async {
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  /// Marca un mensaje como sincronizado
  Future<void> markChatMessageAsSynced(String messageId) async {
    final db = await database;
    await db.update(
      'chat_messages',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Limpia el historial de chat de un usuario
  Future<void> clearChatHistory(String userId) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== MÉTODOS PARA OPERACIONES PENDIENTES ====================

  /// Inserta una operación pendiente
  Future<void> insertPendingOperation(Map<String, dynamic> operation) async {
    final db = await database;
    await db.insert('pending_operations', operation, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Obtiene todas las operaciones pendientes
  Future<List<Map<String, dynamic>>> getAllPendingOperations() async {
    final db = await database;
    return await db.query(
      'pending_operations',
      orderBy: 'created_at ASC',
    );
  }

  /// Obtiene operaciones pendientes por tipo
  Future<List<Map<String, dynamic>>> getPendingOperationsByType(String type) async {
    final db = await database;
    return await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at ASC',
    );
  }

  /// Obtiene una operación pendiente por ID
  Future<Map<String, dynamic>?> getPendingOperationById(String id) async {
    final db = await database;
    final results = await db.query(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Actualiza una operación pendiente
  Future<void> updatePendingOperation(String id, Map<String, dynamic> operation) async {
    final db = await database;
    await db.update(
      'pending_operations',
      operation,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina una operación pendiente
  Future<void> deletePendingOperation(String id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina operaciones pendientes por tipo
  Future<void> deletePendingOperationsByType(String type) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  /// Elimina operaciones pendientes por ID de entidad
  Future<void> deletePendingOperationsByEntityId(String entityId) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'entity_id = ?',
      whereArgs: [entityId],
    );
  }

  /// Elimina operaciones pendientes más antiguas que una fecha
  Future<void> deletePendingOperationsOlderThan(DateTime cutoffDate) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Limpia todas las operaciones pendientes
  Future<void> clearPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
  }

  /// Obtiene el conteo de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_operations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtiene el conteo de operaciones pendientes por tipo
  Future<int> getPendingOperationsCountByType(String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_operations WHERE type = ?',
      [type],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== MÉTODOS GENERALES ====================

  /// Cierra la base de datos
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Elimina la base de datos
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vive_good_offline.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}