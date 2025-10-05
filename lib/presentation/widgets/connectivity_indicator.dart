import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vive_good_app/data/services/connectivity_service.dart';

/// Widget que muestra el estado de conectividad de la aplicación
class ConnectivityIndicator extends StatelessWidget {
  final bool showWhenOnline;
  final EdgeInsetsGeometry? margin;
  final Duration animationDuration;

  const ConnectivityIndicator({
    Key? key,
    this.showWhenOnline = false,
    this.margin,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        return StreamBuilder<ConnectivityStatus>(
          stream: connectivityService.connectivityStream,
          initialData: connectivityService.currentStatus,
          builder: (context, snapshot) {
            final status = snapshot.data ?? ConnectivityStatus(
              type: ConnectivityType.none,
              isOnline: false,
              lastChecked: DateTime.now(),
            );
            
            // Si está online y no queremos mostrar cuando está online, no mostrar nada
            if (status.isOnline && !showWhenOnline) {
              return const SizedBox.shrink();
            }

            return AnimatedContainer(
              duration: animationDuration,
              margin: margin ?? const EdgeInsets.all(8.0),
              child: _buildIndicator(context, status),
            );
          },
        );
      },
    );
  }

  Widget _buildIndicator(BuildContext context, ConnectivityStatus status) {
    final theme = Theme.of(context);
    
    if (status.isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi,
              size: 16,
              color: Colors.green[700],
            ),
            const SizedBox(width: 6),
            Text(
              'En línea',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 16,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 6),
            Text(
              'Sin conexión',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Widget compacto que muestra solo un icono del estado de conectividad
class ConnectivityIcon extends StatelessWidget {
  final double size;
  final Color? onlineColor;
  final Color? offlineColor;

  const ConnectivityIcon({
    Key? key,
    this.size = 20,
    this.onlineColor,
    this.offlineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        return StreamBuilder<ConnectivityStatus>(
          stream: connectivityService.connectivityStream,
          initialData: connectivityService.currentStatus,
          builder: (context, snapshot) {
            final status = snapshot.data ?? ConnectivityStatus(
              type: ConnectivityType.none,
              isOnline: false,
              lastChecked: DateTime.now(),
            );
            
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                status.isOnline ? Icons.wifi : Icons.wifi_off,
                key: ValueKey(status.isOnline),
                size: size,
                color: status.isOnline 
                    ? (onlineColor ?? Colors.green[700])
                    : (offlineColor ?? Colors.orange[700]),
              ),
            );
          },
        );
      },
    );
  }
}

/// Banner que se muestra cuando la aplicación está offline
class OfflineBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const OfflineBanner({
    Key? key,
    this.message = 'Sin conexión a internet. Trabajando en modo offline.',
    this.onRetry,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        return StreamBuilder<ConnectivityStatus>(
          stream: connectivityService.connectivityStream,
          initialData: connectivityService.currentStatus,
          builder: (context, snapshot) {
            final status = snapshot.data ?? ConnectivityStatus(
              type: ConnectivityType.none,
              isOnline: false,
              lastChecked: DateTime.now(),
            );
            
            if (status.isOnline) {
              return const SizedBox.shrink();
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 20,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showRetryButton && onRetry != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontSize: 12),
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
  }
}

/// Widget que muestra el estado de sincronización
class SyncStatusIndicator extends StatelessWidget {
  final bool isSyncing;
  final bool hasPendingChanges;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    Key? key,
    required this.isSyncing,
    required this.hasPendingChanges,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSyncing) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Sincronizando...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blue[700],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasPendingChanges) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync_problem,
                size: 12,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 6),
              Text(
                'Cambios pendientes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber[700],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}