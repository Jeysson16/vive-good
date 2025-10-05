import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/sync_operation.dart';

part 'local_sync_operation_model.g.dart';

@HiveType(typeId: 4)
class LocalSyncOperationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entityType;

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final int operationType; // Almacenamos como int para Hive

  @HiveField(4)
  final Map<String, dynamic> data;

  @HiveField(5)
  final int status; // Almacenamos como int para Hive

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? lastAttemptAt;

  @HiveField(8)
  final int retryCount;

  @HiveField(9)
  final String? errorMessage;

  LocalSyncOperationModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.data,
    required this.status,
    required this.createdAt,
    this.lastAttemptAt,
    this.retryCount = 0,
    this.errorMessage,
  });

  // Convertir desde entidad de dominio
  factory LocalSyncOperationModel.fromEntity(SyncOperation operation) {
    return LocalSyncOperationModel(
      id: operation.id,
      entityType: operation.entityType,
      entityId: operation.entityId,
      operationType: operation.operationType.index,
      data: operation.data,
      status: operation.status.index,
      createdAt: operation.createdAt,
      lastAttemptAt: operation.lastAttemptAt,
      retryCount: operation.retryCount,
      errorMessage: operation.errorMessage,
    );
  }

  // Convertir a entidad de dominio
  SyncOperation toEntity() {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: SyncOperationType.values[operationType],
      data: data,
      status: SyncStatus.values[status],
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt,
      retryCount: retryCount,
      errorMessage: errorMessage,
    );
  }

  // Actualizar estado
  LocalSyncOperationModel updateStatus(SyncStatus newStatus, {String? error}) {
    return LocalSyncOperationModel(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      data: data,
      status: newStatus.index,
      createdAt: createdAt,
      lastAttemptAt: DateTime.now(),
      retryCount: newStatus == SyncStatus.failed ? retryCount + 1 : retryCount,
      errorMessage: error ?? errorMessage,
    );
  }
}