import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../../domain/entities/admin/user_evaluation.dart';
import '../../../core/theme/app_colors.dart';

class AdminEvaluacionesPage extends StatefulWidget {
  const AdminEvaluacionesPage({super.key});

  @override
  State<AdminEvaluacionesPage> createState() => _AdminEvaluacionesPageState();
}

class _AdminEvaluacionesPageState extends State<AdminEvaluacionesPage> {
  String? _selectedRole;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUserEvaluations(refresh: true);
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
            Icons.assessment,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Evaluaciones de Usuarios',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Consumer<AdminProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.evaluationsState == AdminLoadingState.loading
                    ? null
                    : () => provider.loadUserEvaluations(refresh: true),
                icon: provider.evaluationsState == AdminLoadingState.loading
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
          // Filtro por rol
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Filtrar por rol',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 16),
          
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
                _selectedRole = null;
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
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: AdminDataTable<UserEvaluation>(
                  data: provider.userEvaluations,
                  isLoading: provider.evaluationsState == AdminLoadingState.loading,
                  errorMessage: provider.evaluationsError,
                  onRefresh: () => provider.loadUserEvaluations(refresh: true),
                  columns: [
                    AdminDataColumn<UserEvaluation>(
                      label: 'Usuario',
                      cellBuilder: (evaluation) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            evaluation.userName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            evaluation.userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminDataColumn<UserEvaluation>(
                      label: 'Rol',
                      cellBuilder: (evaluation) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(evaluation.roleName ?? 'user').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          evaluation.roleName ?? 'Usuario',
                          style: TextStyle(
                            color: _getRoleColor(evaluation.roleName ?? 'user'),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    AdminDataColumn<UserEvaluation>(
                      label: 'Último Login',
                      cellBuilder: (evaluation) => Text(
                        evaluation.lastLogin != null
                            ? _formatDate(evaluation.lastLogin!)
                            : 'Nunca',
                        style: TextStyle(
                          color: evaluation.lastLogin != null
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                    AdminDataColumn<UserEvaluation>(
                      label: 'Hábitos',
                      cellBuilder: (evaluation) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${evaluation.completedHabits}/${evaluation.totalHabits}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${evaluation.completionRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCompletionRateColor(evaluation.completionRate),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminDataColumn<UserEvaluation>(
                      label: 'Consultas',
                      cellBuilder: (evaluation) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            evaluation.totalConsultations.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if ((evaluation.averageRating ?? 0) > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  (evaluation.averageRating ?? 0).toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    AdminDataColumn<UserEvaluation>(
                      label: 'Estado',
                      cellBuilder: (evaluation) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: evaluation.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          evaluation.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: evaluation.isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    AdminDataColumn<UserEvaluation>(
                      label: 'Creado',
                      cellBuilder: (evaluation) => Text(
                        _formatDate(evaluation.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Aquí se podría agregar paginación si es necesario
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    final provider = context.read<AdminProvider>();
    provider.setRoleFilter(_selectedRole);
    provider.setDateRange(_startDate, _endDate);
    provider.loadUserEvaluations(refresh: true);
  }

  void _clearFilters() {
    final provider = context.read<AdminProvider>();
    provider.clearFilters();
    provider.loadUserEvaluations(refresh: true);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}