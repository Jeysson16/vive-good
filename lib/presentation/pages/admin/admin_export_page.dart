import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../../core/theme/app_colors.dart';

class AdminExportPage extends StatefulWidget {
  const AdminExportPage({super.key});

  @override
  State<AdminExportPage> createState() => _AdminExportPageState();
}

class _AdminExportPageState extends State<AdminExportPage> {
  String _selectedReportType = 'consolidated';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
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
            Icons.download,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Exportar Datos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selección de tipo de reporte
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de Reporte',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportTypeSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Filtros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilters(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón de exportación
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exportar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExportSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Column(
      children: [
        _buildReportTypeOption(
          'consolidated',
          'Reporte Consolidado',
          'Incluye evaluaciones de usuarios, indicadores de aceptación tecnológica, conocimiento de síntomas y hábitos de riesgo',
          Icons.assessment,
        ),
        const SizedBox(height: 12),
        _buildReportTypeOption(
          'users',
          'Reporte de Usuarios',
          'Lista detallada de todos los usuarios con sus estadísticas de uso y evaluaciones',
          Icons.people,
        ),
        const SizedBox(height: 12),
        _buildReportTypeOption(
          'tech_acceptance',
          'Indicadores de Aceptación Tecnológica',
          'Métricas específicas de aceptación tecnológica por usuario',
          Icons.psychology,
        ),
        const SizedBox(height: 12),
        _buildReportTypeOption(
          'knowledge_symptoms',
          'Conocimiento de Síntomas',
          'Evaluación del conocimiento de síntomas por usuario',
          Icons.medical_services,
        ),
        const SizedBox(height: 12),
        _buildReportTypeOption(
          'risk_habits',
          'Hábitos de Riesgo',
          'Análisis de hábitos de riesgo identificados por usuario',
          Icons.warning,
        ),
      ],
    );
  }

  Widget _buildReportTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedReportType == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReportType = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedReportType,
              onChanged: (newValue) {
                setState(() {
                  _selectedReportType = newValue!;
                });
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            // Filtro por rol
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por rol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos los roles')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  DropdownMenuItem(value: 'user', child: Text('Usuario')),
                  DropdownMenuItem(value: 'moderator', child: Text('Moderador')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Fecha de inicio
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Fecha inicio',
                  border: OutlineInputBorder(),
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
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            // Fecha de fin
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Fecha fin',
                  border: OutlineInputBorder(),
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
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRole = null;
                  _startDate = null;
                  _endDate = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        final isExporting = provider.exportState == AdminLoadingState.loading;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.exportError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.exportError!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isExporting ? null : _exportData,
                  icon: isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(isExporting ? 'Exportando...' : 'Exportar a Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'El archivo se guardará en la carpeta de Descargas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData() async {
    final provider = context.read<AdminProvider>();
    
    // Aplicar filtros
    provider.setRoleFilter(_selectedRole);
    provider.setDateRange(_startDate, _endDate);
    
    // Exportar
    final filePath = await provider.exportToExcel(_selectedReportType);
    
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Archivo exportado exitosamente: $filePath'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}