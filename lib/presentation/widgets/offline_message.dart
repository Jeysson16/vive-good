import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/sync_service.dart';

class OfflineMessage extends StatelessWidget {
  final String? customMessage;
  final bool showSyncButton;
  final VoidCallback? onSyncPressed;

  const OfflineMessage({
    Key? key,
    this.customMessage,
    this.showSyncButton = true,
    this.onSyncPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityService, SyncService>(
      builder: (context, connectivityService, syncService, _) {
        return StreamBuilder<ConnectivityStatus>(
          stream: connectivityService.connectivityStream,
          initialData: ConnectivityStatus(
            type: ConnectivityType.none,
            isOnline: false,
            lastChecked: DateTime.now(),
          ),
          builder: (context, connectivitySnapshot) {
            return StreamBuilder<int>(
              stream: syncService.pendingOperationsCountStream,
              initialData: 0,
              builder: (context, pendingSnapshot) {
                final connectivityStatus = connectivitySnapshot.data ?? ConnectivityStatus(
                  type: ConnectivityType.none,
                  isOnline: false,
                  lastChecked: DateTime.now(),
                );
                final pendingCount = pendingSnapshot.data ?? 0;

                // No mostrar nada si está online y no hay cambios pendientes
                if (connectivityStatus.isOnline && pendingCount == 0) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(connectivityStatus, pendingCount),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getBorderColor(connectivityStatus, pendingCount),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getIcon(connectivityStatus, pendingCount),
                            color: _getIconColor(connectivityStatus, pendingCount),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTitle(connectivityStatus, pendingCount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _getTextColor(connectivityStatus, pendingCount),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  customMessage ?? _getMessage(connectivityStatus, pendingCount),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getTextColor(connectivityStatus, pendingCount).withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (showSyncButton && connectivityStatus.isOnline && pendingCount > 0) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onSyncPressed ?? () async {
                              await syncService.syncPendingOperations();
                            },
                            icon: const Icon(Icons.sync, size: 16),
                            label: Text('Sincronizar $pendingCount cambios'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getBackgroundColor(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return Colors.red.shade50;
    } else if (pendingCount > 0) {
      return Colors.orange.shade50;
    }
    return Colors.blue.shade50;
  }

  Color _getBorderColor(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return Colors.red.shade200;
    } else if (pendingCount > 0) {
      return Colors.orange.shade200;
    }
    return Colors.blue.shade200;
  }

  Color _getIconColor(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return Colors.red.shade600;
    } else if (pendingCount > 0) {
      return Colors.orange.shade600;
    }
    return Colors.blue.shade600;
  }

  Color _getTextColor(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return Colors.red.shade800;
    } else if (pendingCount > 0) {
      return Colors.orange.shade800;
    }
    return Colors.blue.shade800;
  }

  IconData _getIcon(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return Icons.wifi_off;
    } else if (pendingCount > 0) {
      return Icons.sync_problem;
    }
    return Icons.info;
  }

  String _getTitle(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return 'Modo Offline';
    } else if (pendingCount > 0) {
      return 'Cambios Pendientes';
    }
    return 'Información';
  }

  String _getMessage(ConnectivityStatus status, int pendingCount) {
    if (status.isOffline) {
      return 'Trabajando sin conexión. Los cambios se sincronizarán automáticamente cuando se restablezca la conexión.';
    } else if (pendingCount > 0) {
      return 'Tienes $pendingCount cambios pendientes de sincronizar. Presiona el botón para sincronizar ahora.';
    }
    return 'Todo está funcionando correctamente.';
  }
}

class OfflineSnackBar {
  static void show(BuildContext context, {
    String? message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Sin conexión - Los cambios se guardarán localmente',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SyncSuccessSnackBar {
  static void show(BuildContext context, {
    String? message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Datos sincronizados correctamente',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}