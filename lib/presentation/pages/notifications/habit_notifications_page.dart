import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_event.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_state.dart';
import 'package:vive_good_app/domain/entities/habit_notification.dart';
import 'package:vive_good_app/core/di/injection_container.dart' as di;

class HabitNotificationsPage extends StatefulWidget {
  final String habitId;
  final String habitName;

  const HabitNotificationsPage({
    Key? key,
    required this.habitId,
    required this.habitName,
  }) : super(key: key);

  @override
  State<HabitNotificationsPage> createState() => _HabitNotificationsPageState();
}

class _HabitNotificationsPageState extends State<HabitNotificationsPage> {
  late NotificationBloc _notificationBloc;
  
  @override
  void initState() {
    super.initState();
    _notificationBloc = di.sl<NotificationBloc>();
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
          title: Text('Notificaciones - ${widget.habitName}'),
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

            return _buildNotificationsView(context, state);
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddNotificationDialog(context),
          child: const Icon(Icons.add),
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
            'Para configurar recordatorios de hábitos, necesitas habilitar las notificaciones.',
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

  Widget _buildNotificationsView(BuildContext context, NotificationState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recordatorios Programados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.notificationSchedules.isEmpty
                ? _buildEmptyState()
                : _buildSchedulesList(state.notificationSchedules),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay recordatorios configurados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca el botón + para agregar un recordatorio',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList(List<dynamic> schedules) {
    return ListView.builder(
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(_formatTime(schedule.scheduledTime)),
            subtitle: Text(_formatDaysOfWeek(schedule.daysOfWeek)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: schedule.isActive,
                  onChanged: (value) {
                    // TODO: Implementar toggle de activación
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteSchedule(context, schedule),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDaysOfWeek(List<int> daysOfWeek) {
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    if (daysOfWeek.length == 7) {
      return 'Todos los días';
    }
    return daysOfWeek.map((day) => dayNames[day - 1]).join(', ');
  }

  void _showAddNotificationDialog(BuildContext context) {
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedDays = [];
    String message = 'Es hora de ${widget.habitName}';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Recordatorio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hora:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(_formatTimeOfDay(selectedTime)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Días de la semana:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDaySelector(selectedDays, setState),
                const SizedBox(height: 16),
                const Text('Mensaje:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Mensaje del recordatorio',
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    message = value;
                  },
                  controller: TextEditingController(text: message),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedDays.isEmpty
                  ? null
                  : () {
                      _scheduleNotification(selectedTime, selectedDays, message);
                      Navigator.of(context).pop();
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(List<int> selectedDays, StateSetter setState) {
    const days = [
      {'name': 'Lun', 'value': 1},
      {'name': 'Mar', 'value': 2},
      {'name': 'Mié', 'value': 3},
      {'name': 'Jue', 'value': 4},
      {'name': 'Vie', 'value': 5},
      {'name': 'Sáb', 'value': 6},
      {'name': 'Dom', 'value': 7},
    ];

    return Wrap(
      spacing: 8,
      children: days.map((day) {
        final isSelected = selectedDays.contains(day['value']);
        return FilterChip(
          label: Text(day['name'] as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedDays.add(day['value'] as int);
              } else {
                selectedDays.remove(day['value']);
              }
            });
          },
        );
      }).toList(),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _scheduleNotification(TimeOfDay time, List<int> daysOfWeek, String message) {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    _notificationBloc.add(
      ScheduleHabitNotification(
        habitId: widget.habitId,
        scheduledTime: scheduledTime,
        daysOfWeek: daysOfWeek,
        message: message,
      ),
    );
  }

  void _confirmDeleteSchedule(BuildContext context, dynamic schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Recordatorio'),
        content: const Text('¿Estás seguro de que quieres eliminar este recordatorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationBloc.add(CancelHabitNotification(schedule.id));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}