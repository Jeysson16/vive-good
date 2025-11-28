import 'package:flutter/material.dart';
import 'package:vive_good_app/domain/entities/habit_statistics.dart';

class HabitStatisticsCard extends StatelessWidget {
  final HabitStatistics statistics;
  final VoidCallback? onTap;

  const HabitStatisticsCard({super.key, required this.statistics, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre de categoría y porcentaje
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      statistics.categoryName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCompletionColor(
                        statistics.completionPercentage,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${statistics.completionPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Métricas principales en grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Completados',
                      '${statistics.completedHabits}/${statistics.totalHabits}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricItem(
                      'Racha Actual',
                      '${statistics.currentStreak} días',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Mejor Racha',
                      '${statistics.bestStreak} días',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricItem(
                      'Consistencia',
                      '${statistics.weeklyConsistency.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              if (statistics.bestDayOfWeek.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Mejor día: ${_getDayName(statistics.bestDayOfWeek)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],

              if (statistics.averageCompletionTime > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tiempo promedio: ${statistics.averageCompletionTime.toStringAsFixed(1)} min',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getDayName(String dayCode) {
    switch (dayCode.toLowerCase()) {
      case 'monday':
      case 'mon':
        return 'Lunes';
      case 'tuesday':
      case 'tue':
        return 'Martes';
      case 'wednesday':
      case 'wed':
        return 'Miércoles';
      case 'thursday':
      case 'thu':
        return 'Jueves';
      case 'friday':
      case 'fri':
        return 'Viernes';
      case 'saturday':
      case 'sat':
        return 'Sábado';
      case 'sunday':
      case 'sun':
        return 'Domingo';
      default:
        return dayCode;
    }
  }
}
