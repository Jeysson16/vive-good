import 'package:equatable/equatable.dart';

enum SyncOperationType {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
}

class SyncOperation extends Equatable {
  final String id;
  final String entityType; // 'habit', 'progress', 'user', 'chat'
  final String entityId;
  final SyncOperationType operationType;
  final Map<String, dynamic> data;
  final SyncStatus status;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int retryCount;
  final String? errorMessage;

  const SyncOperation({
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

  SyncOperation copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperationType? operationType,
    Map<String, dynamic>? data,
    SyncStatus? status,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        operationType,
        data,
        status,
        createdAt,
        lastAttemptAt,
        retryCount,
        errorMessage,
      ];
}