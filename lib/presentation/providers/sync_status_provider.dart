import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vive_good_app/data/services/sync_service.dart';
import 'package:vive_good_app/data/services/pending_operations_service.dart';
import 'package:vive_good_app/data/services/connectivity_service.dart';

/// Provider que maneja el estado de sincronización de la aplicación
class SyncStatusProvider extends ChangeNotifier {
  final SyncService _syncService;
  final PendingOperationsService _pendingOperationsService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  bool _hasPendingChanges = false;
  int _pendingOperationsCount = 0;
  String? _lastSyncError;
  DateTime? _lastSyncTime;

  SyncStatusProvider({
    required SyncService syncService,
    required PendingOperationsService pendingOperationsService,
    required ConnectivityService connectivityService,
  })  : _syncService = syncService,
        _pendingOperationsService = pendingOperationsService,
        _connectivityService = connectivityService {
    _initialize();
  }

  // Getters
  bool get isSyncing => _isSyncing;
  bool get hasPendingChanges => _hasPendingChanges;
  int get pendingOperationsCount => _pendingOperationsCount;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Inicializa el provider
  void _initialize() {
    // Escuchar cambios en el estado de conectividad
    _connectivityService.connectivityStream.listen((status) {
      if (status.isOnline && _hasPendingChanges && !_isSyncing) {
        // Intentar sincronizar automáticamente cuando se restablezca la conexión
        _performSync();
      }
    });

    // Verificar el estado inicial
    _checkPendingOperations();
  }

  /// Verifica si hay operaciones pendientes
  Future<void> _checkPendingOperations() async {
    try {
      final countResult = await _pendingOperationsService.getPendingOperationsCount();
      countResult.fold(
        (failure) {
          _pendingOperationsCount = 0;
          _hasPendingChanges = false;
        },
        (count) {
          _pendingOperationsCount = count;
          _hasPendingChanges = count > 0;
        },
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking pending operations: $e');
    }
  }

  /// Realiza una sincronización manual
  Future<void> performManualSync() async {
    if (_isSyncing) return;
    
    await _performSync();
  }

  /// Realiza la sincronización
  Future<void> _performSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final syncResult = await _syncService.forcSync();
      
      syncResult.fold(
        (failure) {
          _lastSyncError = failure.message;
        },
        (_) {
          _lastSyncTime = DateTime.now();
          _lastSyncError = null;
        },
      );

      // Actualizar el conteo de operaciones pendientes después de la sincronización
      await _checkPendingOperations();
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Actualiza el estado cuando se agrega una nueva operación pendiente
  void onOperationAdded() {
    _pendingOperationsCount++;
    _hasPendingChanges = true;
    notifyListeners();
  }

  /// Actualiza el estado cuando se completa una operación
  void onOperationCompleted() {
    if (_pendingOperationsCount > 0) {
      _pendingOperationsCount--;
      _hasPendingChanges = _pendingOperationsCount > 0;
      notifyListeners();
    }
  }

  /// Limpia el error de sincronización
  void clearSyncError() {
    _lastSyncError = null;
    notifyListeners();
  }

  /// Obtiene un mensaje descriptivo del estado actual
  String getStatusMessage() {
    if (_isSyncing) {
      return 'Sincronizando datos...';
    }

    if (_lastSyncError != null) {
      return 'Error en la sincronización';
    }

    if (_hasPendingChanges) {
      return '$_pendingOperationsCount cambio${_pendingOperationsCount == 1 ? '' : 's'} pendiente${_pendingOperationsCount == 1 ? '' : 's'}';
    }

    if (_lastSyncTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSyncTime!);
      
      if (difference.inMinutes < 1) {
        return 'Sincronizado hace un momento';
      } else if (difference.inHours < 1) {
        return 'Sincronizado hace ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'Sincronizado hace ${difference.inHours}h';
      } else {
        return 'Sincronizado hace ${difference.inDays}d';
      }
    }

    return 'Todo sincronizado';
  }

  /// Obtiene el color del indicador según el estado
  Color getStatusColor() {
    if (_isSyncing) {
      return const Color(0xFF2196F3); // Azul
    }

    if (_lastSyncError != null) {
      return const Color(0xFFF44336); // Rojo
    }

    if (_hasPendingChanges) {
      return const Color(0xFFFF9800); // Naranja
    }

    return const Color(0xFF4CAF50); // Verde
  }

  /// Obtiene el icono del indicador según el estado
  IconData getStatusIcon() {
    if (_isSyncing) {
      return Icons.sync;
    }

    if (_lastSyncError != null) {
      return Icons.sync_problem;
    }

    if (_hasPendingChanges) {
      return Icons.sync_problem;
    }

    return Icons.sync;
  }

}