import 'package:hive_flutter/hive_flutter.dart';
import 'package:vive_good_app/data/models/local/local_habit_model.dart';
import 'package:vive_good_app/data/models/local/local_progress_model.dart';
import 'package:vive_good_app/data/models/local/local_user_model.dart';
import 'package:vive_good_app/data/models/local/local_sync_operation_model.dart';

class LocalDatabaseService {
  static const String _habitsBoxName = 'habits';
  static const String _progressBoxName = 'progress';
  static const String _usersBoxName = 'users';
  static const String _syncOperationsBoxName = 'sync_operations';
  static const String _metadataBoxName = 'metadata';

  // Singleton
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Registrar adaptadores si no están registrados
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LocalHabitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LocalProgressModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LocalUserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LocalSyncOperationModelAdapter());
    }

    // Abrir cajas
    await Future.wait([
      Hive.openBox<LocalHabitModel>(_habitsBoxName),
      Hive.openBox<LocalProgressModel>(_progressBoxName),
      Hive.openBox<LocalUserModel>(_usersBoxName),
      Hive.openBox<LocalSyncOperationModel>(_syncOperationsBoxName),
      Hive.openBox<Map<String, dynamic>>(_metadataBoxName),
    ]);

    _isInitialized = true;
  }

  // Getters para las cajas
  Box<LocalHabitModel> get _habitsBox => Hive.box<LocalHabitModel>(_habitsBoxName);
  Box<LocalProgressModel> get _progressBox => Hive.box<LocalProgressModel>(_progressBoxName);
  Box<LocalUserModel> get _usersBox => Hive.box<LocalUserModel>(_usersBoxName);
  Box<LocalSyncOperationModel> get _syncOperationsBox => Hive.box<LocalSyncOperationModel>(_syncOperationsBoxName);
  Box<Map<String, dynamic>> get _metadataBox => Hive.box<Map<String, dynamic>>(_metadataBoxName);

  // === HÁBITOS ===
  Future<void> saveHabit(LocalHabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  Future<LocalHabitModel?> getHabit(String id) async {
    return _habitsBox.get(id);
  }

  Future<List<LocalHabitModel>> getAllHabits() async {
    return _habitsBox.values.toList();
  }

  Future<List<LocalHabitModel>> getHabitsNeedingSync() async {
    return _habitsBox.values.where((habit) => habit.needsSync).toList();
  }

  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
  }

  // === PROGRESO ===
  Future<void> saveProgress(LocalProgressModel progress) async {
    await _progressBox.put(progress.id, progress);
  }

  Future<LocalProgressModel?> getProgress(String id) async {
    return _progressBox.get(id);
  }

  Future<List<LocalProgressModel>> getAllProgress() async {
    return _progressBox.values.toList();
  }

  Future<List<LocalProgressModel>> getProgressForHabit(String habitId) async {
    return _progressBox.values.where((progress) => progress.habitId == habitId).toList();
  }

  Future<List<LocalProgressModel>> getProgressNeedingSync() async {
    return _progressBox.values.where((progress) => progress.needsSync).toList();
  }

  Future<void> deleteProgress(String id) async {
    await _progressBox.delete(id);
  }

  // === USUARIOS ===
  Future<void> saveUser(LocalUserModel user) async {
    await _usersBox.put(user.id, user);
  }

  Future<LocalUserModel?> getUser(String id) async {
    return _usersBox.get(id);
  }

  Future<LocalUserModel?> getCurrentUser() async {
    final users = _usersBox.values.toList();
    return users.isNotEmpty ? users.first : null;
  }

  Future<List<LocalUserModel>> getUsersNeedingSync() async {
    return _usersBox.values.where((user) => user.needsSync).toList();
  }

  Future<void> deleteUser(String id) async {
    await _usersBox.delete(id);
  }

  // === OPERACIONES DE SINCRONIZACIÓN ===
  Future<void> saveSyncOperation(LocalSyncOperationModel operation) async {
    await _syncOperationsBox.put(operation.id, operation);
  }

  Future<LocalSyncOperationModel?> getSyncOperation(String id) async {
    return _syncOperationsBox.get(id);
  }

  Future<List<LocalSyncOperationModel>> getPendingSyncOperations() async {
    return _syncOperationsBox.values
        .where((op) => op.status == 0) // SyncStatus.pending.index
        .toList();
  }

  Future<List<LocalSyncOperationModel>> getFailedSyncOperations() async {
    return _syncOperationsBox.values
        .where((op) => op.status == 3) // SyncStatus.failed.index
        .toList();
  }

  Future<void> deleteSyncOperation(String id) async {
    await _syncOperationsBox.delete(id);
  }

  Future<void> clearCompletedSyncOperations() async {
    final completedKeys = _syncOperationsBox.values
        .where((op) => op.status == 2) // SyncStatus.completed.index
        .map((op) => op.id)
        .toList();
    
    for (final key in completedKeys) {
      await _syncOperationsBox.delete(key);
    }
  }

  // === METADATA ===
  Future<void> setMetadata(String key, Map<String, dynamic> value) async {
    await _metadataBox.put(key, value);
  }

  Future<Map<String, dynamic>?> getMetadata(String key) async {
    return _metadataBox.get(key);
  }

  Future<void> deleteMetadata(String key) async {
    await _metadataBox.delete(key);
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await setMetadata('last_sync_time', {'timestamp': time.toIso8601String()});
  }

  Future<DateTime?> getLastSyncTime() async {
    final metadata = await getMetadata('last_sync_time');
    if (metadata != null && metadata['timestamp'] != null) {
      return DateTime.parse(metadata['timestamp']);
    }
    return null;
  }

  // === UTILIDADES ===
  Future<void> clearAllData() async {
    await Future.wait([
      _habitsBox.clear(),
      _progressBox.clear(),
      _usersBox.clear(),
      _syncOperationsBox.clear(),
      _metadataBox.clear(),
    ]);
  }

  Future<Map<String, int>> getDatabaseStats() async {
    return {
      'habits': _habitsBox.length,
      'progress': _progressBox.length,
      'users': _usersBox.length,
      'sync_operations': _syncOperationsBox.length,
      'habits_needing_sync': _habitsBox.values.where((h) => h.needsSync).length,
      'progress_needing_sync': _progressBox.values.where((p) => p.needsSync).length,
      'users_needing_sync': _usersBox.values.where((u) => u.needsSync).length,
    };
  }

  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}