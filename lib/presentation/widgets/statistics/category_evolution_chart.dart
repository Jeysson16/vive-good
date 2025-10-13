import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:vive_good_app/domain/entities/category_evolution.dart';
import 'package:vive_good_app/domain/entities/daily_progress.dart';

class CategoryEvolutionChart extends StatelessWidget {
  final CategoryEvolution evolution;
  final bool showDetails;

  const CategoryEvolutionChart({
    Key? key,
    required this.evolution,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información de la categoría
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(evolution.categoryColor.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    evolution.categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTrendColor(evolution.monthlyTrend),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTrendIcon(evolution.monthlyTrend),
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${evolution.monthlyTrend > 0 ? '+' : ''}${evolution.monthlyTrend.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Gráfico de líneas
            Container(
              height: 220,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LineChart(
                  LineChartData(
                    clipData: FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          interval: 7,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() % 7 == 0 && value.toInt() <= evolution.dailyProgress.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    minX: 1,
                    maxX: evolution.dailyProgress.length.toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getChartSpots(),
                        isCurved: true,
                        color: Color(int.parse(evolution.categoryColor.replaceFirst('#', '0xFF'))),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 2.5,
                              color: Color(int.parse(evolution.categoryColor.replaceFirst('#', '0xFF'))),
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(int.parse(evolution.categoryColor.replaceFirst('#', '0xFF'))).withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (showDetails) ...[
              const SizedBox(height: 16),
              
              // Métricas adicionales
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Promedio Mensual',
                      '${math.min(100, evolution.monthlyAverage).toStringAsFixed(1)}%',
                      Icons.analytics,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Predicción',
                      '${math.min(100, evolution.predictedEndOfMonth).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Días Consistentes',
                      '${evolution.consistentDays}',
                      Icons.check_circle,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Mejora',
                      '${evolution.improvementRate > 0 ? '+' : ''}${evolution.improvementRate.clamp(-100, 100).toStringAsFixed(1)}%',
                      Icons.arrow_upward,
                      evolution.improvementRate > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              
              if (evolution.bestDaysOfWeek.isNotEmpty || evolution.worstDaysOfWeek.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (evolution.bestDaysOfWeek.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.star, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Mejores días',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                evolution.bestDaysOfWeek.map((day) => _getDayName(day)).join(', '),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (evolution.bestDaysOfWeek.isNotEmpty && evolution.worstDaysOfWeek.isNotEmpty)
                      const SizedBox(width: 8),
                    if (evolution.worstDaysOfWeek.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Días difíciles',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                evolution.worstDaysOfWeek.join(', '),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    return evolution.dailyProgress.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final progress = entry.value;
      final percent = progress.completionPercentage.clamp(0, 100).toDouble();
      return FlSpot(index.toDouble(), percent);
    }).toList();
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(double trend) {
    if (trend > 0) return Colors.green;
    if (trend < 0) return Colors.red;
    return Colors.grey;
  }

  IconData _getTrendIcon(double trend) {
    if (trend > 0) return Icons.trending_up;
    if (trend < 0) return Icons.trending_down;
    return Icons.trending_flat;
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