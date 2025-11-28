import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../middleware/admin_middleware.dart';
import '../../providers/admin_provider.dart';
import 'admin_dashboard_page.dart';
import '../../../core/di/injection_container.dart' as di;

class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminProvider(
        getDashboardStatsUseCase: di.sl(),
        getUserEvaluationsUseCase: di.sl(),
        getTechAcceptanceIndicatorsUseCase: di.sl(),
        getConsolidatedReportUseCase: di.sl(),
        checkAdminPermissionsUseCase: di.sl(),
        exportToExcelUseCase: di.sl(),
        adminRepository: di.sl(),
      ),
      child: const AdminMiddleware(
        child: AdminDashboardPage(),
      ),
    );
  }
}