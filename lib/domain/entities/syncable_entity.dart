import 'package:equatable/equatable.dart';

abstract class SyncableEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocalOnly; // true si solo existe localmente
  final bool needsSync; // true si necesita sincronización
  final DateTime? lastSyncAt; // última vez que se sincronizó

  const SyncableEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.isLocalOnly = false,
    this.needsSync = false,
    this.lastSyncAt,
  });

  // Método para marcar como que necesita sincronización
  SyncableEntity markAsNeedsSync();
  
  // Método para marcar como sincronizado
  SyncableEntity markAsSynced();
  
  // Método para convertir a Map para sincronización
  Map<String, dynamic> toSyncMap();

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        isLocalOnly,
        needsSync,
        lastSyncAt,
      ];
}