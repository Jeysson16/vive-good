import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vive_good_app/data/services/sync_service.dart';
import 'package:vive_good_app/domain/entities/pending_operation.dart';

class PendingChangesIndicator extends StatelessWidget {
  final Widget child;
  final bool showBadge;

  const PendingChangesIndicator({
    super.key,
    required this.child,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        return StreamBuilder<int>(
          stream: syncService.pendingOperationsCountStream,
          initialData: 0,
          builder: (context, snapshot) {
            final pendingCount = snapshot.data ?? 0;
            
            if (pendingCount == 0) {
              return child;
            }

            return Stack(
              children: [
                child,
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : pendingCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class PendingChangesBottomSheet extends StatelessWidget {
  const PendingChangesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        return StreamBuilder<List<PendingOperation>>(
          stream: syncService.pendingOperationsStream,
          initialData: const [],
          builder: (context, snapshot) {
            final pendingOperations = snapshot.data ?? [];

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cambios Pendientes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pendingOperations.isEmpty)
                    const Center(
                      child: Text('No hay cambios pendientes'),
                    )
                  else ...[
                    Text(
                      '${pendingOperations.length} operaciones pendientes de sincronización',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pendingOperations.length,
                        itemBuilder: (context, index) {
                          final operation = pendingOperations[index];
                          return _buildOperationTile(context, operation);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await syncService.syncPendingOperations();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Sincronizar Ahora'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await _showClearConfirmation(context);
                            if (confirmed == true) {
                              await syncService.clearPendingOperations();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          child: const Text('Limpiar'),
                        ),
                      ],
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

  Widget _buildOperationTile(BuildContext context, PendingOperation operation) {
    IconData icon;
    Color iconColor;
    String operationText;

    switch (operation.type) {
      case PendingOperationType.createHabit:
        icon = Icons.add;
        iconColor = Colors.green;
        operationText = 'Crear hábito';
        break;
      case PendingOperationType.updateHabit:
        icon = Icons.edit;
        iconColor = Colors.orange;
        operationText = 'Actualizar hábito';
        break;
      case PendingOperationType.deleteHabit:
        icon = Icons.delete;
        iconColor = Colors.red;
        operationText = 'Eliminar hábito';
        break;
      case PendingOperationType.updateProgress:
        icon = Icons.trending_up;
        iconColor = Colors.blue;
        operationText = 'Actualizar progreso';
        break;
      case PendingOperationType.updateUser:
        icon = Icons.person;
        iconColor = Colors.purple;
        operationText = 'Actualizar usuario';
        break;
      case PendingOperationType.sendMessage:
        icon = Icons.message;
        iconColor = Colors.teal;
        operationText = 'Enviar mensaje';
        break;
      case PendingOperationType.clearChatHistory:
        icon = Icons.clear_all;
        iconColor = Colors.grey;
        operationText = 'Limpiar historial';
        break;
      default:
        icon = Icons.sync;
        iconColor = Colors.blue;
        operationText = 'Sincronizar';
    }

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(operationText),
      subtitle: Text(
        'ID: ${operation.entityId}\n${_formatDateTime(operation.createdAt)}',
      ),
      trailing: operation.retryCount > 0
          ? Chip(
              label: Text('${operation.retryCount} reintentos'),
              backgroundColor: Colors.orange.shade100,
            )
          : null,
      isThreeLine: true,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showClearConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Cambios Pendientes'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los cambios pendientes? '
          'Esta acción no se puede deshacer y perderás todos los cambios que no se han sincronizado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}

class PendingChangesFloatingButton extends StatelessWidget {
  const PendingChangesFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        return StreamBuilder<int>(
          stream: syncService.pendingOperationsCountStream,
          initialData: 0,
          builder: (context, snapshot) {
            final pendingCount = snapshot.data ?? 0;
            
            if (pendingCount == 0) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const PendingChangesBottomSheet(),
                );
              },
              icon: const Icon(Icons.sync_problem),
              label: Text('$pendingCount pendientes'),
              backgroundColor: Colors.orange,
            );
          },
        );
      },
    );
  }
}