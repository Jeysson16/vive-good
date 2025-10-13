import 'package:flutter/material.dart';
import '../../services/calendar_service.dart';

class PendingActivitiesPage extends StatefulWidget {
  const PendingActivitiesPage({super.key});

  @override
  State<PendingActivitiesPage> createState() => _PendingActivitiesPageState();
}

class _PendingActivitiesPageState extends State<PendingActivitiesPage> {
  List<Map<String, dynamic>> _pendingActivities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingActivities();
  }

  Future<void> _loadPendingActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final activities = await CalendarService.getPendingActivities();
      
      setState(() {
        _pendingActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsCompleted(String activityId) async {
    try {
      await CalendarService.markActivityAsCompleted(activityId);
      await _loadPendingActivities(); // Recargar la lista
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad marcada como completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar actividad: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'habit':
        return Icons.check_circle_outline;
      case 'appointment':
        return Icons.event;
      case 'medication':
        return Icons.medication;
      case 'exercise':
        return Icons.fitness_center;
      case 'meal':
        return Icons.restaurant;
      default:
        return Icons.task_alt;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades Pendientes'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar actividades',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingActivities,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _pendingActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Color(0xFF4CAF50),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Excelente!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No tienes actividades pendientes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingActivities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _pendingActivities[index];
                          final priority = activity['priority'] ?? 'medium';
                          final type = activity['type'] ?? 'task';
                          final scheduledTime = activity['scheduled_time'];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getActivityIcon(type),
                                  color: _getPriorityColor(priority),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                activity['title'] ?? 'Sin título',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (activity['description'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      activity['description'],
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(priority),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          priority.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (scheduledTime != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          scheduledTime,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                ),
                                onPressed: () => _markAsCompleted(activity['id']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}