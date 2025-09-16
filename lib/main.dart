import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/habit/habit_bloc.dart';
import 'presentation/blocs/progress/progress_bloc.dart';
import 'presentation/blocs/habit_breakdown/habit_breakdown_bloc.dart';
import 'presentation/bloc/calendar/calendar_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable debug logging
  if (kDebugMode) {
    debugPrint('🚀 Iniciando ViveGood App en modo debug');
  }
  
  try {
    debugPrint('📦 Inicializando dependencias...');
    await di.init();
    debugPrint('✅ Dependencias inicializadas');
    
    debugPrint('🌍 Inicializando datos de localización...');
    await initializeDateFormatting('es_ES', null);
    debugPrint('✅ Datos de localización inicializados');
    
    debugPrint('🎯 Ejecutando aplicación...');
    runApp(const ViveGoodApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Error durante la inicialización: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

class ViveGoodApp extends StatelessWidget {
  const ViveGoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<HabitBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ProgressBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<HabitBreakdownBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<CalendarBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'ViveGood',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF4CAF50),
          fontFamily: 'Roboto',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
          ),
        ),
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
