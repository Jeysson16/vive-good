import 'package:equatable/equatable.dart';

/// Tipos de operaciones pendientes de sincronización
enum PendingOperationType {
  createHabit,
  updateHabit,
  deleteHabit,
  updateProgress,
  updateUser,
  sendMessage,
  clearChatHistory,
  unknown,
}

/// Entidad que representa una operación pendiente de sincronización
class PendingOperation extends Equatable {
  final String id;
  final PendingOperationType type;
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  /// Crea una copia de la operación con campos actualizados
  PendingOperation copyWith({
    String? id,
    PendingOperationType? type,
    String? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? error,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }

  /// Incrementa el contador de reintentos
  PendingOperation incrementRetry([String? errorMessage]) {
    return copyWith(
      retryCount: retryCount + 1,
      error: errorMessage,
    );
  }

  /// Verifica si la operación ha excedido el máximo de reintentos
  bool get hasExceededMaxRetries => retryCount >= 3;

  /// Verifica si la operación es reciente (menos de 24 horas)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        entityId,
        data,
        createdAt,
        retryCount,
        error,
      ];

  @override
  String toString() {
    return 'PendingOperation(id: $id, type: $type, entityId: $entityId, createdAt: $createdAt, retryCount: $retryCount, error: $error)';
  }
}