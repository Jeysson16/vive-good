import 'package:uuid/uuid.dart';
import 'package:vive_good_app/data/models/user_model.dart';
import 'package:vive_good_app/data/models/local/local_user_model.dart';
import 'package:vive_good_app/data/models/local/local_sync_operation_model.dart';
import 'package:vive_good_app/data/datasources/local_database_service.dart';
import 'package:vive_good_app/domain/entities/sync_operation.dart';

abstract class UserLocalDataSource {
  Future<UserModel?> getCurrentUser();
  Future<void> saveUser(UserModel user);
  Future<void> updateUser(String userId, Map<String, dynamic> updates);
  Future<void> deleteUser(String userId);
  Future<List<LocalUserModel>> getUsersNeedingSync();
  Future<void> clearUserData();
  Future<void> setOnboardingCompleted(bool completed);
  Future<void> setFirstTimeUser(bool isFirstTime);
  Future<bool> hasCompletedOnboarding();
  Future<bool> isFirstTimeUser();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final LocalDatabaseService _localDb;
  final Uuid _uuid = const Uuid();

  UserLocalDataSourceImpl({required LocalDatabaseService localDb}) : _localDb = localDb;

  @override
  Future<UserModel?> getCurrentUser() async {
    final localUser = await _localDb.getCurrentUser();
    if (localUser == null) return null;
    
    return UserModel.fromEntity(localUser.toEntity());
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final localUser = LocalUserModel.fromEntity(user.toEntity()).markAsNeedsSync();
    await _localDb.saveUser(localUser);
    
    // Crear operación de sincronización
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'user',
        entityId: user.id,
        operationType: SyncOperationType.create,
        data: localUser.toSyncMap(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    final existingUser = await _localDb.getUser(userId);
    if (existingUser == null) return;
    
    // Crear usuario actualizado
    final updatedUser = LocalUserModel(
      id: existingUser.id,
      email: updates['email'] ?? existingUser.email,
      name: updates['full_name'] ?? existingUser.name,
      avatarUrl: updates['avatar_url'] ?? existingUser.avatarUrl,
      createdAt: existingUser.createdAt,
      updatedAt: DateTime.now(),
      isLocalOnly: false,
      needsSync: true,
      lastSyncAt: existingUser.lastSyncAt,
    );
    
    await _localDb.saveUser(updatedUser);
    
    // Crear operación de sincronización
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'user',
        entityId: userId,
        operationType: SyncOperationType.update,
        data: updatedUser.toSyncMap(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _localDb.deleteUser(userId);
    
    // Crear operación de sincronización para eliminación
    final syncOperation = LocalSyncOperationModel.fromEntity(
      SyncOperation(
        id: _uuid.v4(),
        entityType: 'user',
        entityId: userId,
        operationType: SyncOperationType.delete,
        data: {'id': userId},
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _localDb.saveSyncOperation(syncOperation);
  }

  @override
  Future<List<LocalUserModel>> getUsersNeedingSync() async {
    return await _localDb.getUsersNeedingSync();
  }

  @override
  Future<void> clearUserData() async {
    await _localDb.clearAllData();
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _localDb.setMetadata('onboarding_completed', {'value': completed});
  }

  @override
  Future<void> setFirstTimeUser(bool isFirstTime) async {
    await _localDb.setMetadata('first_time_user', {'value': isFirstTime});
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final metadata = await _localDb.getMetadata('onboarding_completed');
    return metadata?['value'] == true;
  }

  @override
  Future<bool> isFirstTimeUser() async {
    final metadata = await _localDb.getMetadata('first_time_user');
    return metadata?['value'] == true;
  }
}