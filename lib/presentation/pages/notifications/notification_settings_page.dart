import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_event.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_state.dart';
import 'package:vive_good_app/domain/entities/notification_settings.dart';
import 'package:vive_good_app/core/di/injection_container.dart' as di;

class NotificationSettingsPage extends StatefulWidget {
  final String userId;

  const NotificationSettingsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late NotificationBloc _notificationBloc;
  
  @override
  void initState() {
    super.initState();
    _notificationBloc = di.sl<NotificationBloc>();
    _notificationBloc.add(LoadNotificationSettings(widget.userId));
    _notificationBloc.add(CheckNotificationPermissions());
  }

  @override
  void dispose() {
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Notificaciones'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: BlocConsumer<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state.status == NotificationStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Error desconocido'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == NotificationStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == NotificationStatus.permissionDenied) {
              return _buildPermissionDeniedView(context);
            }

            return _buildSettingsView(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Permisos de Notificación Requeridos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Para recibir recordatorios de tus hábitos, necesitas habilitar las notificaciones.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              _notificationBloc.add(RequestNotificationPermissions());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Habilitar Notificaciones',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context, NotificationState state) {
    final settings = state.settings;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralSettings(context, settings),
          const SizedBox(height: 24),
          _buildQuietHoursSettings(context, settings),
          const SizedBox(height: 24),
          _buildSnoozeSettings(context, settings),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context, NotificationSettings? settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificaciones Habilitadas'),
              subtitle: const Text('Recibir recordatorios de hábitos'),
              value: settings?.globalNotificationsEnabled ?? true,
              onChanged: (value) {
                _notificationBloc.add(
                  UpdateNotificationSettings(
                    settings?.copyWith(globalNotificationsEnabled: value) ??
                        NotificationSettings(
                          userId: widget.userId,
                          globalNotificationsEnabled: value,
                          permissionsGranted: false,
                          quietHoursStart: '22:00',
                          quietHoursEnd: '08:00',
                          maxSnoozeCount: 3,
                          defaultSnoozeMinutes: 5,
                          defaultNotificationSound: 'default',
                          updatedAt: DateTime.now(),
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSettings(BuildContext context, NotificationSettings? settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horas de Silencio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Habilitar Horas de Silencio'),
              subtitle: const Text('No recibir notificaciones durante estas horas'),
              value: (settings?.quietHoursStart != null && settings?.quietHoursEnd != null),
              onChanged: (value) {
                _notificationBloc.add(
                  UpdateNotificationSettings(
                    settings?.copyWith(quietHoursStart: value ? '22:00' : null, quietHoursEnd: value ? '08:00' : null) ??
                        NotificationSettings(
                          userId: widget.userId,
                          globalNotificationsEnabled: true,
                          permissionsGranted: false,
                          quietHoursStart: value ? '22:00' : null,
                          quietHoursEnd: value ? '08:00' : null,
                          maxSnoozeCount: 3,
                          defaultSnoozeMinutes: 5,
                          defaultNotificationSound: 'default',
                          updatedAt: DateTime.now(),
                        ),
                  ),
                );
              },
            ),
            if (settings?.quietHoursStart != null && settings?.quietHoursEnd != null) ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Hora de Inicio'),
                subtitle: Text(_formatTimeString(settings!.quietHoursStart)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(
                  context,
                  _parseTimeString(settings.quietHoursStart),
                  (time) {
                    _notificationBloc.add(
                      UpdateNotificationSettings(
                        settings.copyWith(quietHoursStart: _timeOfDayToString(time)),
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                title: const Text('Hora de Fin'),
                subtitle: Text(_formatTimeString(settings.quietHoursEnd)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(
                  context,
                  _parseTimeString(settings.quietHoursEnd),
                  (time) {
                    _notificationBloc.add(
                      UpdateNotificationSettings(
                        settings.copyWith(quietHoursEnd: _timeOfDayToString(time)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeSettings(BuildContext context, NotificationSettings? settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Posposición',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Máximo de Posposiciones'),
              subtitle: Text('${settings?.maxSnoozeCount ?? 3} veces'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showSnoozeCountDialog(context, settings),
            ),
            ListTile(
              title: const Text('Intervalo de Posposición'),
              subtitle: Text('${settings?.defaultSnoozeMinutes ?? 5} minutos'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showSnoozeIntervalDialog(context, settings),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeString(String? timeString) {
    if (timeString == null) return '--:--';
    return timeString;
  }

  TimeOfDay _parseTimeString(String? timeString) {
    if (timeString == null) return const TimeOfDay(hour: 22, minute: 0);
    final parts = timeString.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 22, minute: 0);
    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null) {
      onTimeSelected(time);
    }
  }

  void _showSnoozeCountDialog(BuildContext context, NotificationSettings? settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Máximo de Posposiciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4, 5].map((count) {
            return RadioListTile<int>(
              title: Text('$count ${count == 1 ? 'vez' : 'veces'}'),
              value: count,
              groupValue: settings?.maxSnoozeCount ?? 3,
              onChanged: (value) {
                if (value != null) {
                  _notificationBloc.add(
                    UpdateNotificationSettings(
                      settings?.copyWith(maxSnoozeCount: value) ??
                          NotificationSettings(
                            userId: widget.userId,
                            globalNotificationsEnabled: true,
                            permissionsGranted: false,
                            quietHoursStart: '22:00',
                            quietHoursEnd: '08:00',
                            maxSnoozeCount: value,
                            defaultSnoozeMinutes: 5,
                            defaultNotificationSound: 'default',
                            updatedAt: DateTime.now(),
                          ),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSnoozeIntervalDialog(BuildContext context, NotificationSettings? settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intervalo de Posposición'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 5, 10, 15, 30].map((minutes) {
            return RadioListTile<int>(
              title: Text('$minutes ${minutes == 1 ? 'minuto' : 'minutos'}'),
              value: minutes,
              groupValue: settings?.defaultSnoozeMinutes ?? 5,
              onChanged: (value) {
                if (value != null) {
                  _notificationBloc.add(
                    UpdateNotificationSettings(
                      settings?.copyWith(defaultSnoozeMinutes: value) ??
                          NotificationSettings(
                            userId: widget.userId,
                            globalNotificationsEnabled: true,
                            permissionsGranted: false,
                            quietHoursStart: '22:00',
                            quietHoursEnd: '08:00',
                            maxSnoozeCount: 3,
                            defaultSnoozeMinutes: value,
                            defaultNotificationSound: 'default',
                            updatedAt: DateTime.now(),
                          ),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}