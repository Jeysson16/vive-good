import 'package:uuid/uuid.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/models/category_model.dart';
import 'package:vive_good_app/data/models/user_habit_model.dart';
import 'package:vive_good_app/data/models/local/local_habit_model.dart';
import 'package:vive_good_app/data/models/local/local_progress_model.dart';
import 'package:vive_good_app/data/models/local/local_sync_operation_model.dart';
import 'package:vive_good_app/data/datasources/local_database_service.dart';
import 'package:vive_good_app/domain/entities/sync_operation.dart';

abstract class HabitLocalDataSource {
  Future<List<UserHabitModel>> getUserHabits(String userId);
  Future<UserHabitModel?> getUserHabitById(String userHabitId);
  Future<List<CategoryModel>> getHabitCategories();
  Future<void> addHabit(HabitModel habit);
  Future<void> deleteHabit(String habitId);
  Future<void> logHabitCompletion(String habitId, DateTime date, String userId);
  Future<List<HabitModel>> getDashboardHabits(String userId, int limit);
  Future<void> updateUserHabit(String userHabitId, Map<String, dynamic> updates);
  Future<void> deleteUserHabit(String userHabitId);
  Future<List<LocalHabitModel>> getHabitsNeedingSync();
  Future<List<LocalProgressModel>> getProgressNeedingSync();
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final LocalDatabaseService _localDb;
  final Uuid _uuid = const Uuid();

  HabitLocalDataSourceImpl({required LocalDatabaseService localDb}) : _localDb = localDb;

  @override
  Future<List<UserHabitModel>> getUserHabits(String userId) async {
    final localHabits = await _localDb.getAllHabits();
    // Convertir LocalHabitModel a UserHabitModel
    // Por simplicidad, creamos UserHabitModel básicos
    return localHabits.map((habit) => UserHabitModel(
      id: habit.id,
      userId: userId,
      habitId: habit.id,
      frequency: 'daily', // Valor por defecto
      notificationsEnabled: true,
      startDate: habit.createdAt,
      isActive: habit.isActive,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
    )).toList();
  }

  @override
  Future<UserHabitModel?> getUserHabitById(String userHabitId) async {
    final habit = await _localDb.getHabit(userHabitId);
    if (habit == null) return null;
    
    return UserHabitModel(
      id: habit.id,
      userId: '', // Se puede obtener del contexto
      habitId: habit.id,
      frequency: 'daily', // Valor por defecto
      notificationsEnabled: true,
      startDate: habit.createdAt,
      isActive: habit.isActive,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
    );
  }

  @override
  Future<List<CategoryModel>> getHabitCategories() async {
    // Categorías predefinidas para modo offline
    return [
      CategoryModel(
        id: '1',
        name: 'Salud',
        iconName: 'health',
        color: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: '2',
        name: 'Ejercicio',
        iconName: 'fitness',
        color: '#FF9800',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: '3',
        name: 'Productividad',
        iconName: 'productivity',
        color: '#2196F3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    final localHabit = LocalHabitModel.fromEntity(habit.toEntity()).markAsNeedsSync();
    await _localDb.saveHabit(localHabit);
    
    // Crear operación de sincronización
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'habit',
        entityId: habit.id,
        operationType: SyncOperationType.create,
        data: localHabit.toSyncMap(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _localDb.deleteHabit(habitId);
    
    // Crear operación de sincronización para eliminación
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'habit',
        entityId: habitId,
        operationType: SyncOperationType.delete,
        data: {'id': habitId},
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<void> logHabitCompletion(String habitId, DateTime date, String userId) async {
    final progressId = _uuid.v4();
    final progress = LocalProgressModel(
      id: progressId,
      userId: userId,
      habitId: habitId,
      date: date,
      completed: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: true,
    );
    
    await _localDb.saveProgress(progress);
    
    // Crear operación de sincronización
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'progress',
        entityId: progressId,
        operationType: SyncOperationType.create,
        data: progress.toSyncMap(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<List<HabitModel>> getDashboardHabits(String userId, int limit) async {
    final localHabits = await _localDb.getAllHabits();
    final limitedHabits = localHabits.take(limit).toList();
    
    return limitedHabits.map((habit) => HabitModel.fromEntity(habit.toEntity())).toList();
  }

  @override
  Future<void> updateUserHabit(String userHabitId, Map<String, dynamic> updates) async {
    final existingHabit = await _localDb.getHabit(userHabitId);
    if (existingHabit == null) return;
    
    // Crear hábito actualizado
    final updatedHabit = LocalHabitModel(
      id: existingHabit.id,
      name: updates['name'] ?? existingHabit.name,
      description: updates['description'] ?? existingHabit.description,
      categoryId: updates['category_id'] ?? existingHabit.categoryId,
      iconName: updates['icon_name'] ?? existingHabit.iconName,
      color: updates['color'] ?? existingHabit.color,
      createdAt: existingHabit.createdAt,
      updatedAt: DateTime.now(),
      isActive: updates['is_active'] ?? existingHabit.isActive,
      targetFrequency: updates['target_frequency'] ?? existingHabit.targetFrequency,
      frequencyType: updates['frequency_type'] ?? existingHabit.frequencyType,
      needsSync: true,
    );
    
    await _localDb.saveHabit(updatedHabit);
    
    // Crear operación de sincronización
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'habit',
        entityId: userHabitId,
        operationType: SyncOperationType.update,
        data: updatedHabit.toSyncMap(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<void> deleteUserHabit(String userHabitId) async {
    await deleteHabit(userHabitId);
  }

  @override
  Future<List<LocalHabitModel>> getHabitsNeedingSync() async {
    return await _localDb.getHabitsNeedingSync();
  }

  @override
  Future<List<LocalProgressModel>> getProgressNeedingSync() async {
    return await _localDb.getProgressNeedingSync();
  }
}
