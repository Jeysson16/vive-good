import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/kpi_card.dart';
import '../../../core/theme/app_colors.dart';

class AdminIndicadoresPage extends StatefulWidget {
  const AdminIndicadoresPage({super.key});

  @override
  State<AdminIndicadoresPage> createState() => _AdminIndicadoresPageState();
}

class _AdminIndicadoresPageState extends State<AdminIndicadoresPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadTechAcceptanceIndicators();
      provider.loadConsolidatedReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Indicadores y KPIs',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Consumer<AdminProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.indicatorsState == AdminLoadingState.loading
                    ? null
                    : () {
                        provider.loadTechAcceptanceIndicators();
                        provider.loadConsolidatedReport();
                      },
                icon: provider.indicatorsState == AdminLoadingState.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Actualizar datos',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Filtro por fecha de inicio
          SizedBox(
            width: 180,
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Fecha inicio',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: _startDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : '',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                  _applyFilters();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Filtro por fecha de fin
          SizedBox(
            width: 180,
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Fecha fin',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: _endDate != null
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : '',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                  _applyFilters();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Botón limpiar filtros
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              _clearFilters();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.indicatorsState == AdminLoadingState.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.indicatorsState == AdminLoadingState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar indicadores',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.indicatorsError ?? 'Error desconocido',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadTechAcceptanceIndicators();
                    provider.loadConsolidatedReport();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPIs de Aceptación Tecnológica
              _buildTechAcceptanceKPIs(provider),
              const SizedBox(height: 32),

              // Gráficos
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTechAcceptanceChart(provider),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompletionRateChart(provider),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Distribución por niveles
              _buildAcceptanceLevelDistribution(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechAcceptanceKPIs(AdminProvider provider) {
    final indicators = provider.techAcceptanceIndicators;
    
    if (indicators.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No hay datos de aceptación tecnológica disponibles'),
          ),
        ),
      );
    }

    final avgUsefulness = indicators.map((e) => e.perceivedUsefulness).reduce((a, b) => a + b) / indicators.length;
    final avgEaseOfUse = indicators.map((e) => e.perceivedEaseOfUse).reduce((a, b) => a + b) / indicators.length;
    final avgOverallScore = indicators.map((e) => e.overallScore).reduce((a, b) => a + b) / indicators.length;
    final highAcceptance = indicators.where((e) => e.acceptanceLevel == 'Alto').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores de Aceptación Tecnológica',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getGridCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            KpiCard(
              title: 'Utilidad Percibida',
              value: avgUsefulness.toStringAsFixed(1),
              icon: Icons.thumb_up,
              color: Colors.blue,
              subtitle: 'Promedio general',
            ),
            KpiCard(
              title: 'Facilidad de Uso',
              value: avgEaseOfUse.toStringAsFixed(1),
              icon: Icons.touch_app,
              color: Colors.green,
              subtitle: 'Promedio general',
            ),
            KpiCard(
              title: 'Puntuación General',
              value: avgOverallScore.toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.orange,
              subtitle: 'Sobre 5.0',
            ),
            KpiCard(
              title: 'Alta Aceptación',
              value: highAcceptance.toString(),
              icon: Icons.trending_up,
              color: Colors.purple,
              subtitle: '${((highAcceptance / indicators.length) * 100).toStringAsFixed(1)}% del total',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechAcceptanceChart(AdminProvider provider) {
    final indicators = provider.techAcceptanceIndicators;
    
    if (indicators.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text('No hay datos para mostrar'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de Aceptación Tecnológica',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _getTechAcceptanceSections(indicators),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateChart(AdminProvider provider) {
    final report = provider.consolidatedReport;
    
    if (report.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: Text('No hay datos para mostrar'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasa de Completitud de Hábitos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final ranges = ['0-20%', '21-40%', '41-60%', '61-80%', '81-100%'];
                          if (value.toInt() < ranges.length) {
                            return Text(
                              ranges[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _getCompletionRateBarGroups(report),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptanceLevelDistribution(AdminProvider provider) {
    final indicators = provider.techAcceptanceIndicators;
    
    if (indicators.isEmpty) {
      return const SizedBox.shrink();
    }

    final levelCounts = <String, int>{};
    for (final indicator in indicators) {
      levelCounts[indicator.acceptanceLevel] = (levelCounts[indicator.acceptanceLevel] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por Nivel de Aceptación',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...levelCounts.entries.map((entry) {
              final percentage = (entry.value / indicators.length) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getLevelColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getTechAcceptanceSections(List<dynamic> indicators) {
    final levelCounts = <String, int>{};
    for (final indicator in indicators) {
      final level = indicator.acceptanceLevel as String;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }

    return levelCounts.entries.map((entry) {
      final percentage = (entry.value / indicators.length) * 100;
      return PieChartSectionData(
        color: _getLevelColor(entry.key),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _getCompletionRateBarGroups(List<dynamic> report) {
    final ranges = [
      (0, 20),
      (21, 40),
      (41, 60),
      (61, 80),
      (81, 100),
    ];

    final counts = List.filled(5, 0);
    
    for (final item in report) {
      final rate = item.completionRate as double;
      for (int i = 0; i < ranges.length; i++) {
        if (rate >= ranges[i].$1 && rate <= ranges[i].$2) {
          counts[i]++;
          break;
        }
      }
    }

    return counts.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'alto':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'bajo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1;
  }

  void _applyFilters() {
    final provider = context.read<AdminProvider>();
    provider.setDateRange(_startDate, _endDate);
    provider.loadTechAcceptanceIndicators();
    provider.loadConsolidatedReport();
  }

  void _clearFilters() {
    final provider = context.read<AdminProvider>();
    provider.clearFilters();
    provider.loadTechAcceptanceIndicators();
    provider.loadConsolidatedReport();
  }
}