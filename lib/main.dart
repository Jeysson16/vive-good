import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'presentation/blocs/calendar/calendar_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/habit/habit_bloc.dart';
import 'presentation/blocs/habit_breakdown/habit_breakdown_bloc.dart';
import 'presentation/blocs/main_page/main_page_bloc.dart';
import 'presentation/blocs/progress/progress_bloc.dart';
import 'presentation/blocs/assistant/assistant_bloc.dart';
import 'data/repositories/supabase_chat_repository.dart';
import 'data/datasources/chat_remote_datasource.dart';
import 'data/datasources/assistant/supabase_assistant_datasource.dart';
import 'data/services/metrics_extraction_service.dart';
import 'data/services/voice_service.dart';
import 'data/datasources/assistant/gemini_assistant_datasource.dart';
import 'data/datasources/deep_learning_datasource.dart';
import 'domain/repositories/habit_repository.dart';
import 'data/services/habit_auto_creation_service.dart';
import 'data/services/habit_extraction_service.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/sync_service.dart';
import 'data/datasources/local_database_service.dart';
import 'providers/theme_provider.dart';
import 'presentation/widgets/connectivity_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await di.init();
    await initializeDateFormatting('es_ES', null);
    
    // Inicializar servicios offline
    await LocalDatabaseService().initialize();
    
    // Inicializar ConnectivityService para detectar estado de conectividad
    await ConnectivityService.instance.initialize();
    
    // Inicializar SyncService para sincronización automática
    di.sl<SyncService>().initialize();
    
    runApp(const ViveGoodApp());
  } catch (e, stackTrace) {
    rethrow;
  }
}

class ViveGoodApp extends StatelessWidget {
  const ViveGoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider<ConnectivityService>(create: (context) => ConnectivityService.instance),
        Provider<SyncService>(
          create: (context) => di.sl<SyncService>(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => di.sl<AuthBloc>()),
              BlocProvider(create: (context) => di.sl<HabitBloc>()),
              BlocProvider(create: (context) => di.sl<DashboardBloc>()),
              BlocProvider(create: (context) => MainPageBloc()),
              BlocProvider(create: (context) => di.sl<ProgressBloc>()),
              BlocProvider(create: (context) => di.sl<HabitBreakdownBloc>()),
              BlocProvider(create: (context) => di.sl<CalendarBloc>()),
              BlocProvider<AssistantBloc>(
                create: (context) {
                  // Get userId from AuthBloc if available
                  String? userId;
                  final authBloc = context.read<AuthBloc>();
                  final authState = authBloc.state;
                  if (authState is AuthAuthenticated) {
                    userId = authState.user.id;
                  }
                  
                  return AssistantBloc(
                    chatRepository: SupabaseChatRepository(
                      ChatRemoteDataSource(Supabase.instance.client),
                      supabaseDatasource: SupabaseAssistantDatasource(
                        Supabase.instance.client,
                      ),
                      geminiDatasource: GeminiAssistantDatasource(
                        apiKey: const String.fromEnvironment('GOOGLE_API_KEY', defaultValue: 'AIzaSyAJ0SdbXQTyxjQ9IpPjKD97rNzFB2zJios'),
                        habitAutoCreationService: di.sl<HabitAutoCreationService>(),
                      ),
                      deepLearningDatasource: DeepLearningDatasourceImpl(
                        httpClient: http.Client(),
                        baseUrl: 'https://homepage-focusing-lanka-describing.trycloudflare.com',
                        apiKey: const String.fromEnvironment('DEEP_LEARNING_API_KEY', defaultValue: ''),
                      ),
                    ),
                    habitRepository: di.sl<HabitRepository>(),
                    userId: userId,
                  );
                },
              ),
            ],
            child: MaterialApp.router(
              title: 'ViveGood',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.themeData,
              themeMode: themeProvider.themeMode,
              routerConfig: AppRoutes.router,
            ),
          );
        },
      ),
    );
  }
}
