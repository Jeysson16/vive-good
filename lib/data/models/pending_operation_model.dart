import 'package:vive_good_app/domain/entities/pending_operation.dart';

/// Modelo de datos para operaciones pendientes de sincronización
class PendingOperationModel {
  final String id;
  final String type;
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  const PendingOperationModel({
    required this.id,
    required this.type,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  /// Convierte el modelo a entidad de dominio
  PendingOperation toEntity() {
    return PendingOperation(
      id: id,
      type: PendingOperationType.values.firstWhere(
        (e) => e.toString().split('.').last == type,
        orElse: () => PendingOperationType.unknown,
      ),
      entityId: entityId,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount,
      error: error,
    );
  }

  /// Crea un modelo desde una entidad de dominio
  factory PendingOperationModel.fromEntity(PendingOperation operation) {
    return PendingOperationModel(
      id: operation.id,
      type: operation.type.toString().split('.').last,
      entityId: operation.entityId,
      data: operation.data,
      createdAt: operation.createdAt,
      retryCount: operation.retryCount,
      error: operation.error,
    );
  }

  /// Crea un modelo desde JSON
  factory PendingOperationModel.fromJson(Map<String, dynamic> json) {
    return PendingOperationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      entityId: json['entity_id'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'entity_id': entityId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'error': error,
    };
  }

  /// Crea una copia del modelo con campos actualizados
  PendingOperationModel copyWith({
    String? id,
    String? type,
    String? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? error,
  }) {
    return PendingOperationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingOperationModel &&
        other.id == id &&
        other.type == type &&
        other.entityId == entityId &&
        other.createdAt == createdAt &&
        other.retryCount == retryCount &&
        other.error == error;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        entityId.hashCode ^
        createdAt.hashCode ^
        retryCount.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'PendingOperationModel(id: $id, type: $type, entityId: $entityId, createdAt: $createdAt, retryCount: $retryCount, error: $error)';
  }
}