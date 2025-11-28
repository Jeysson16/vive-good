import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart' as auth_states;

class AdminSidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;
  final bool isVisible;
  final VoidCallback? onToggle;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.isVisible = true,
    this.onToggle,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return BlocListener<AuthBloc, auth_states.AuthState>(
      listener: (context, state) {
        if (state is auth_states.AuthUnauthenticated) {
          // Cerrar overlay de carga si está abierto
          if (_isLoggingOut) {
            setState(() {
              _isLoggingOut = false;
            });
            Navigator.of(context).pop(); // Cerrar el overlay
          }
          // Navegar a la pantalla de welcome cuando el usuario cierre sesión
          context.go('/welcome');
        }
      },
      child: Container(
        width: isMobile ? 280 : 300,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFF090D3A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Panel de Administración',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestión del sistema',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/admin',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.people,
                      title: 'Usuarios',
                      route: '/admin/users',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.assessment,
                      title: 'Evaluaciones',
                      route: '/admin/evaluations',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.analytics,
                      title: 'Indicadores',
                      route: '/admin/indicators',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.description,
                      title: 'Reportes',
                      route: '/admin/reports',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.settings,
                      title: 'Mantenedores',
                      route: '/admin/mantenedores',
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with logout button
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutConfirmationDialog(context),
                      icon: Icon(
                        Icons.logout,
                        size: isMobile ? 18 : 20,
                      ),
                      label: Text(
                        'Salir del Admin',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Versión 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isMobile,
  }) {
    final isSelected = widget.currentRoute == route;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF090D3A).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF090D3A).withOpacity(0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => widget.onNavigate(route),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF090D3A)
                      : Colors.grey[600],
                  size: isMobile ? 20 : 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF090D3A)
                          : Colors.grey[700],
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D3A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo de confirmación para cerrar sesión
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF090D3A),
            ),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión del panel de administración?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Mostrar overlay de carga y disparar el evento de cerrar sesión
                _showLoadingOverlay();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra el overlay de carga durante el logout
  void _showLoadingOverlay() {
    setState(() {
      _isLoggingOut = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevenir cerrar con botón atrás
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF090D3A),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cerrando sesión...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF090D3A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}