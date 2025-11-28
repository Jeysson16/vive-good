import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../pages/auth/login_page.dart';
import '../../../widgets/common/loading_widget.dart';

class AdminMiddleware extends StatefulWidget {
  final Widget child;
  
  const AdminMiddleware({
    super.key,
    required this.child,
  });

  @override
  State<AdminMiddleware> createState() => _AdminMiddlewareState();
}

class _AdminMiddlewareState extends State<AdminMiddleware> {
  bool _isChecking = true;
  bool _hasAdminAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAdminPermissions();
  }

  Future<void> _checkAdminPermissions() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Verificar si el usuario está autenticado
      final authState = authBloc.state;
      if (authState is! AuthAuthenticated) {
        setState(() {
          _isChecking = false;
          _hasAdminAccess = false;
        });
        return;
      }

      // Obtener el usuario actual de Supabase
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isChecking = false;
          _hasAdminAccess = false;
        });
        return;
      }

      // Verificar permisos de administrador
      await adminProvider.checkAdminPermissions(currentUser.id);
      
      // Verificar el resultado en el provider
      final hasPermissions = adminProvider.isAdmin;

      setState(() {
        _isChecking = false;
        _hasAdminAccess = hasPermissions;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _hasAdminAccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: LoadingWidget(message: 'Verificando permisos de administrador...'),
      );
    }

    if (!_hasAdminAccess) {
      return _buildAccessDeniedPage();
    }

    return widget.child;
  }

  Widget _buildAccessDeniedPage() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Acceso Denegado',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes permisos para acceder al módulo de administración.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}