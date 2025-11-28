import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  DatabaseService._();

  Database? _database;
  static const String _databaseName = 'vive_good_offline.db';
  static const int _databaseVersion = 3;

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

    // Tabla de notificaciones
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        type TEXT NOT NULL,
        related_id TEXT,
        data TEXT,
        is_read INTEGER DEFAULT 0,
        read_at TEXT,
        scheduled_for TEXT,
        sent_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        needs_sync INTEGER DEFAULT 0,
        last_sync_at TEXT
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
    await db.execute('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
    
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
      // Migración para versión 2: Agregar columnas faltantes
      try {
        // Verificar y agregar columnas faltantes en la tabla habits
        await db.execute('ALTER TABLE habits ADD COLUMN reminder_time TEXT');
      } catch (e) {
        // La columna ya existe, continuar
      }
      
      try {
        await db.execute('ALTER TABLE habits ADD COLUMN is_active INTEGER DEFAULT 1');
      } catch (e) {
        // La columna ya existe, continuar
      }
      
      try {
        // Verificar y agregar columna faltante en la tabla chat_messages
        await db.execute('ALTER TABLE chat_messages ADD COLUMN created_at TEXT NOT NULL DEFAULT ""');
      } catch (e) {
        // La columna ya existe, continuar
      }
    }
    
    if (oldVersion < 3) {
      // Migración para versión 3: Crear tabla notifications
      try {
        await db.execute('''
          CREATE TABLE notifications (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT,
            type TEXT NOT NULL,
            related_id TEXT,
            data TEXT,
            is_read INTEGER DEFAULT 0,
            read_at TEXT,
            scheduled_for TEXT,
            sent_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            needs_sync INTEGER DEFAULT 0,
            last_sync_at TEXT
          )
        ''');
        
        await db.execute('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
      } catch (e) {
        // La tabla ya existe, continuar
        print('Error creating notifications table: $e');
      }
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

  /// Verifica si una tabla existe en la base de datos
  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  /// Fuerza la creación de la tabla notifications si no existe
  Future<void> ensureNotificationsTableExists() async {
    final db = await database;
    
    try {
      // Verificar si la tabla existe
      final exists = await tableExists('notifications');
      if (!exists) {
        print('Tabla notifications no existe, creándola...');
        
        // Crear la tabla notifications
        await db.execute('''
          CREATE TABLE notifications (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT,
            type TEXT NOT NULL,
            related_id TEXT,
            data TEXT,
            is_read INTEGER DEFAULT 0,
            read_at TEXT,
            scheduled_for TEXT,
            sent_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            needs_sync INTEGER DEFAULT 0,
            last_sync_at TEXT
          )
        ''');
        
        // Crear el índice
        await db.execute('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
        
        print('Tabla notifications creada exitosamente');
      } else {
        print('Tabla notifications ya existe');
      }
    } catch (e) {
      print('Error al verificar/crear tabla notifications: $e');
      rethrow;
    }
  }

  /// Limpia todos los datos (útil para logout)
  Future<void> clearAllData() async {
    final db = await database;
    
    // Limpiar todas las tablas
    await db.delete('habits');
    await db.delete('progress');
    await db.delete('chat_messages');
    await db.delete('pending_operations');
    await db.delete('notifications');
    
    // Resetear metadatos de sincronización
    await setMetadata('last_full_sync', '');
  }

  /// Fuerza la recreación de la base de datos (útil para resolver problemas de esquema)
  Future<void> recreateDatabase() async {
    try {
      // Cerrar la conexión actual
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Eliminar el archivo de la base de datos
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      await deleteDatabase(path);
      
      print('Base de datos eliminada y será recreada en el próximo acceso');
    } catch (e) {
      print('Error al recrear la base de datos: $e');
      rethrow;
    }
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