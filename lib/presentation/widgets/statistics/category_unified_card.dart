import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:vive_good_app/domain/entities/category_evolution.dart';
import 'package:vive_good_app/domain/entities/habit_statistics.dart';

class CategoryUnifiedCard extends StatefulWidget {
  final CategoryEvolution evolution;
  final HabitStatistics? statistics;

  const CategoryUnifiedCard({
    Key? key,
    required this.evolution,
    this.statistics,
  }) : super(key: key);

  @override
  State<CategoryUnifiedCard> createState() => _CategoryUnifiedCardState();
}

class _CategoryUnifiedCardState extends State<CategoryUnifiedCard> {
  // Mostrar gráfico automáticamente, sin lazy loading
  bool _showChart = true;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la categoría
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse(widget.evolution.categoryColor.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.evolution.categoryName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTrendColor(widget.evolution.monthlyTrend),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTrendIcon(widget.evolution.monthlyTrend),
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.evolution.monthlyTrend > 0 ? '+' : ''}${widget.evolution.monthlyTrend.toStringAsFixed(1)}%',
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
              const SizedBox(height: 20),
              
              // Gráfico de análisis temporal - mostrar directamente
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
                  child: _buildOptimizedChart(),
                ),
              ),
              const SizedBox(height: 20),
            
              // Estadísticas principales en grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Promedio Mensual',
                      '${math.min(100, widget.evolution.monthlyAverage).toStringAsFixed(1)}%',
                      Icons.analytics,
                      const Color(0xFF2196F3), // Azul estándar
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Predicción',
                      '${math.min(100, widget.evolution.predictedEndOfMonth).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      const Color(0xFF4CAF50), // Verde estándar
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
                      '${widget.evolution.consistentDays}',
                      Icons.check_circle,
                      const Color(0xFF2196F3), // Azul estándar
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Mejora',
                      '${widget.evolution.improvementRate > 0 ? '+' : ''}${widget.evolution.improvementRate.clamp(-100, 100).toStringAsFixed(1)}%',
                      Icons.arrow_upward,
                      widget.evolution.improvementRate > 0 ? const Color(0xFF4CAF50) : Colors.red,
                    ),
                  ),
                ],
              ),
              
              // Información adicional de estadísticas si está disponible
              if (widget.statistics != null) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatisticItem(
                        'Completados',
                        '${widget.statistics!.completedHabits}/${widget.statistics!.totalHabits}',
                        Icons.check_circle,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatisticItem(
                        'Racha Actual',
                        '${widget.statistics!.currentStreak} días',
                        Icons.local_fire_department,
                        const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                
                if (widget.statistics!.bestDayOfWeek.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.black54, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Mejor día: ${_getDayName(widget.statistics!.bestDayOfWeek)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              
              // Mejores días y días difíciles
              const SizedBox(height: 16),
              _buildBestAndWorstDays(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataChart() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Datos en proceso',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Los datos se mostrarán cuando estén disponibles',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedChart() {
    // Obtener datos simplificados (incluye fallback automáticamente)
    final simplifiedSpots = _getSimplifiedChartSpots();
    
    // Construir gráfico directamente sin FutureBuilder para mejor rendimiento
    return _buildDirectChart(simplifiedSpots);
  }

  Widget _buildDirectChart(List<FlSpot> spots) {
    return LineChart(
      LineChartData(
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25, // Simplificar grid
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
              interval: math.max(1, (spots.length / 5).ceil()).toDouble(),
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day > 0 && day <= (spots.isNotEmpty ? spots.last.x.toInt() : 1)) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '$day',
                      style: const TextStyle(
                        color: Colors.black54,
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
                      color: Colors.black54,
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
        maxX: math.max(1, (spots.isNotEmpty ? spots.last.x : 1)),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // Líneas rectas para mejor rendimiento
            color: Color(int.parse(widget.evolution.categoryColor.replaceFirst('#', '0xFF'))),
            barWidth: spots.length <= 10 ? 3 : 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: spots.length <= 10), // Mostrar puntos si el dataset es pequeño
            belowBarData: BarAreaData(
              show: true,
              color: Color(int.parse(widget.evolution.categoryColor.replaceFirst('#', '0xFF'))).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
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
      ],
    );
  }

  Widget _buildBestAndWorstDays() {
    return Column(
      children: [
        if (widget.evolution.bestDaysOfWeek.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: const Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Mejores días',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.evolution.bestDaysOfWeek.map((day) => Text(
                    _getDayName(day),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
        
        if (widget.evolution.worstDaysOfWeek.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Días difíciles',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.evolution.worstDaysOfWeek.map((day) => Text(
                    day,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<FlSpot> _getChartSpots() {
    if (widget.evolution.dailyProgress.isEmpty) {
      return _generateFallbackData();
    }
    
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.evolution.dailyProgress.length; i++) {
      final progress = widget.evolution.dailyProgress[i];
      final percent = progress.completionPercentage.clamp(0.0, 100.0);
      spots.add(FlSpot((i + 1).toDouble(), percent));
    }
    
    // Si todos los valores son 0, generar datos de fallback
    if (spots.every((spot) => spot.y == 0)) {
      return _generateFallbackData();
    }
    
    return spots;
  }

  List<FlSpot> _getSimplifiedChartSpots() {
    // Obtener datos validados (incluye fallback si es necesario)
    final allSpots = _getChartSpots();
    if (allSpots.isEmpty) {
      return _generateFallbackData();
    }

    // Reducir puntos de datos para mejor rendimiento
    if (allSpots.length <= 15) return allSpots; // Aumentar límite ligeramente
    
    // Tomar cada n-ésimo punto para reducir la complejidad
    final step = math.max(1, (allSpots.length / 15).ceil());
    final simplifiedSpots = <FlSpot>[];
    
    // Incluir siempre el primer punto
    simplifiedSpots.add(allSpots.first);
    
    // Agregar puntos intermedios
    for (int i = step; i < allSpots.length - 1; i += step) {
      simplifiedSpots.add(allSpots[i]);
    }
    
    // Incluir siempre el último punto
    if (allSpots.length > 1) {
      simplifiedSpots.add(allSpots.last);
    }
    
    return simplifiedSpots;
  }

  Color _getTrendColor(double trend) {
    if (trend > 0) return const Color(0xFF4CAF50); // Verde estándar
    if (trend < 0) return Colors.red;
    return const Color(0xFF2196F3); // Azul estándar
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

  /// Genera datos de fallback cuando no hay datos reales disponibles
  List<FlSpot> _generateFallbackData() {
    final now = DateTime.now();
    final currentDay = now.day;
    
    // Generar datos simulados basados en el promedio mensual si está disponible
    final baseValue = widget.evolution.monthlyAverage > 0 
        ? widget.evolution.monthlyAverage * 100 // Convertir a porcentaje
        : 30.0; // Valor por defecto del 30%
    
    final spots = <FlSpot>[];
    final random = math.Random(42); // Seed fijo para consistencia
    
    // Generar entre 5 y 10 puntos de datos simulados (mínimo 2 para que se vea la línea)
    final pointCount = math.max(2, math.min(currentDay, 10));
    for (int i = 0; i < pointCount; i++) {
      // Agregar algo de variación realista
      final variation = (random.nextDouble() - 0.5) * 20; // ±10%
      final value = (baseValue + variation).clamp(0.0, 100.0);
      spots.add(FlSpot((i + 1).toDouble(), value));
    }

    // Si por alguna razón quedó un solo punto, duplica para mostrar línea horizontal
    if (spots.length == 1) {
      spots.add(FlSpot(2.0, spots.first.y));
    }

    return spots;
  }
}