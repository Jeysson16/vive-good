import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_sidebar_toggle_button.dart';
import '../../widgets/admin/kpi_card.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_evaluaciones_page.dart';
import 'admin_export_page.dart';
import 'admin_indicadores_page.dart';
import 'admin_mantenedores_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
      // En desktop, mostrar sidebar por defecto
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth >= 1024) {
        setState(() {
          _isSidebarVisible = true;
        });
      }
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavigate(String route) {
    // Implementar navegación si es necesario
    // Por ahora solo actualizar el índice basado en la ruta
  }

  String get _currentRoute {
    switch (_selectedIndex) {
      case 0:
        return '/admin/dashboard';
      case 1:
        return '/admin/evaluaciones';
      case 2:
        return '/admin/indicadores';
      case 3:
        return '/admin/mantenedores';
      case 4:
        return '/admin/export';
      default:
        return '/admin/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Contenido principal (sin sidebar en móvil cuando está visible)
          Row(
            children: [
              // Sidebar visible en desktop cuando _isSidebarVisible es true
              if (!isMobile && _isSidebarVisible)
                AdminSidebar(
                  currentRoute: _currentRoute,
                  onNavigate: _onNavigate,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  isVisible: _isSidebarVisible,
                  onToggle: _toggleSidebar,
                ),
              // Contenido principal
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
          
          // Overlay para móvil cuando el sidebar está visible
          if (isMobile && _isSidebarVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          
          // Sidebar en móvil como overlay
          if (isMobile && _isSidebarVisible)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: AdminSidebar(
                currentRoute: _currentRoute,
                onNavigate: _onNavigate,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                isVisible: _isSidebarVisible,
                onToggle: _toggleSidebar,
              ),
            ),
          
          // Botón flotante para mostrar/ocultar sidebar (solo en móvil)
          if (isMobile)
            AdminSidebarToggleButton(
              isSidebarVisible: _isSidebarVisible,
              onToggle: _toggleSidebar,
              isFloating: true,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header con botón de toggle
        _buildHeader(),
        // Contenido principal
        Expanded(
          child: _getSelectedPage(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      height: isMobile ? 56 : 64,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Botón de toggle solo en desktop
          if (!isMobile)
            AdminSidebarToggleButton(
              onToggle: _toggleSidebar,
              isSidebarVisible: _isSidebarVisible,
              isFloating: false,
            ),
          if (!isMobile) SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Text(
              _getPageTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Administrativo';
      case 1:
        return 'Mantenedores';
      case 2:
        return 'Evaluaciones';
      case 3:
        return 'Indicadores';
      case 4:
        return 'Exportar Datos';
      default:
        return 'Dashboard Administrativo';
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const AdminMantenedoresPage();
      case 2:
        return const AdminEvaluacionesPage();
      case 3:
        return const AdminIndicadoresPage();
      case 4:
        return const AdminExportPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.dashboardState == AdminLoadingState.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.dashboardState == AdminLoadingState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar datos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.dashboardError ?? 'Error desconocido',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.loadDashboardStats(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = provider.dashboardStats;
        if (stats == null) {
          return const Center(
            child: Text('No hay datos disponibles'),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        final isTablet = screenWidth >= 768 && screenWidth < 1024;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: _getGridCrossAxisCount(context),
                crossAxisSpacing: isMobile ? 8 : 12,
                mainAxisSpacing: isMobile ? 8 : 12,
                childAspectRatio: isMobile ? 1.2 : (isTablet ? 1.3 : 1.4),
                children: [
                  KpiCard(
                    title: 'Total Usuarios',
                    value: stats.totalUsers.toString(),
                    icon: Icons.people,
                    color: AppColors.primary,
                    subtitle: '${stats.activeUsers} activos',
                  ),
                  KpiCard(
                    title: 'Total Hábitos',
                    value: stats.totalHabits.toString(),
                    icon: Icons.track_changes,
                    color: AppColors.secondaryBlue,
                    subtitle: '${stats.totalCategories} categorías',
                  ),
                  KpiCard(
                    title: 'Evaluaciones',
                    value: stats.totalEvaluations.toString(),
                    icon: Icons.assessment,
                    color: Colors.green,
                    subtitle: 'Completadas',
                  ),
                  KpiCard(
                    title: 'Consultas',
                    value: stats.totalConsultations.toString(),
                    icon: Icons.chat,
                    color: Colors.purple,
                    subtitle: 'Rating: ${stats.averageRating.toStringAsFixed(1)}',
                  ),
                  KpiCard(
                    title: 'Roles',
                    value: stats.totalRoles.toString(),
                    icon: Icons.admin_panel_settings,
                    color: Colors.orange,
                    subtitle: 'Configurados',
                  ),
                  KpiCard(
                    title: 'Última Actualización',
                    value: _formatDate(stats.lastUpdated),
                    icon: Icons.update,
                    color: Colors.teal,
                    subtitle: 'Datos sincronizados',
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // Acciones Rápidas
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Rápidas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Wrap(
                      spacing: isMobile ? 6 : 8,
                      runSpacing: isMobile ? 6 : 8,
                      children: [
                        _buildQuickActionButton(
                          context,
                          'Evaluaciones',
                          Icons.assessment,
                          () => setState(() => _selectedIndex = 2),
                          isMobile,
                        ),
                        _buildQuickActionButton(
                          context,
                          'Indicadores',
                          Icons.analytics,
                          () => setState(() => _selectedIndex = 3),
                          isMobile,
                        ),
                        _buildQuickActionButton(
                          context,
                          'Mantenedores',
                          Icons.settings,
                          () => setState(() => _selectedIndex = 1),
                          isMobile,
                        ),
                        _buildQuickActionButton(
                          context,
                          'Exportar',
                          Icons.download,
                          () => setState(() => _selectedIndex = 4),
                          isMobile,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool isMobile,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: isMobile ? 14 : 16,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 11 : 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 6 : 8,
        ),
        minimumSize: Size(isMobile ? 80 : 100, isMobile ? 32 : 36),
      ),
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Ajustar para el sidebar
    final availableWidth = _isSidebarVisible ? width - 300 : width;
    
    if (availableWidth > 1200) return 3;
    if (availableWidth > 800) return 2;
    return 1;
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