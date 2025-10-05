import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  DatabaseService._();

  Database? _database;
  static const String _databaseName = 'vive_good_offline.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_sync_at TEXT
      )
    ''');

    // Tabla de hábitos
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        color TEXT,
        icon TEXT,
        frequency TEXT NOT NULL,
        target_count INTEGER DEFAULT 1,
        reminder_time TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_sync_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Tabla de progreso
    await db.execute('''
      CREATE TABLE progress (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        count INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_sync_at TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id),
        UNIQUE(habit_id, date)
      )
    ''');

    // Tabla de mensajes de chat
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        content TEXT NOT NULL,
        is_user_message INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        session_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        last_sync_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Tabla de operaciones pendientes
    await db.execute('''
      CREATE TABLE pending_operations (
        id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at TEXT,
        error_message TEXT
      )
    ''');

    // Tabla de configuración/metadatos
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_habits_user_id ON habits(user_id)');
    await db.execute('CREATE INDEX idx_progress_habit_id ON progress(habit_id)');
    await db.execute('CREATE INDEX idx_progress_date ON progress(date)');
    await db.execute('CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id)');
    await db.execute('CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id)');
    await db.execute('CREATE INDEX idx_pending_operations_type ON pending_operations(operation_type)');
    await db.execute('CREATE INDEX idx_pending_operations_table ON pending_operations(table_name)');
    
    // Insertar metadatos iniciales
    await db.insert('app_metadata', {
      'key': 'database_version',
      'value': _databaseVersion.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('app_metadata', {
      'key': 'last_full_sync',
      'value': '',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Manejar actualizaciones de la base de datos aquí
    if (oldVersion < 2) {
      // Ejemplo de migración para versión 2
      // await db.execute('ALTER TABLE habits ADD COLUMN new_field TEXT');
    }
  }

  // Métodos de utilidad para operaciones comunes

  /// Inserta un registro con timestamp automático
  Future<int> insertWithTimestamp(String table, Map<String, dynamic> values) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    values['created_at'] = now;
    values['updated_at'] = now;
    values['is_synced'] = 0; // Marcar como no sincronizado
    
    return await db.insert(table, values);
  }

  /// Actualiza un registro con timestamp automático
  Future<int> updateWithTimestamp(String table, Map<String, dynamic> values, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    
    values['updated_at'] = DateTime.now().toIso8601String();
    values['is_synced'] = 0; // Marcar como no sincronizado
    
    return await db.update(table, values, where: whereClause, whereArgs: whereArgs);
  }

  /// Marca un registro como sincronizado
  Future<int> markAsSynced(String table, String id) async {
    final db = await database;
    
    return await db.update(
      table,
      {
        'is_synced': 1,
        'last_sync_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene registros no sincronizados
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await database;
    
    return await db.query(
      table,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'updated_at ASC',
    );
  }

  /// Obtiene metadatos de la aplicación
  Future<String?> getMetadata(String key) async {
    final db = await database;
    
    final result = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  /// Establece metadatos de la aplicación
  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    
    await db.insert(
      'app_metadata',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Limpia todos los datos (útil para logout)
  Future<void> clearAllData() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete('users');
      await txn.delete('habits');
      await txn.delete('progress');
      await txn.delete('chat_messages');
      await txn.delete('pending_operations');
      // No limpiar app_metadata para mantener configuraciones
    });
  }

  /// Obtiene estadísticas de la base de datos
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final stats = <String, int>{};
    
    final tables = ['users', 'habits', 'progress', 'chat_messages', 'pending_operations'];
    
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = result.first['count'] as int;
    }
    
    return stats;
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}