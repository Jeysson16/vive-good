import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'data/datasources/assistant/deep_learning_datasource.dart';
import 'data/datasources/assistant/gemini_assistant_datasource.dart';
import 'data/datasources/assistant/supabase_assistant_datasource.dart';
import 'data/datasources/chat_remote_datasource.dart';
import 'data/datasources/local_database_service.dart';
import 'data/repositories/auth/deep_learning_auth_repository.dart';
import 'data/repositories/supabase_chat_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/habit_auto_creation_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/permission_service.dart';
import 'data/services/sync_service.dart';
import 'domain/repositories/habit_repository.dart';
import 'presentation/blocs/assistant/assistant_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/calendar/calendar_bloc.dart';
import 'presentation/blocs/category_evolution/category_evolution_bloc.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/habit/habit_bloc.dart';
import 'presentation/blocs/habit_breakdown/habit_breakdown_bloc.dart';
import 'presentation/blocs/habit_statistics/habit_statistics_bloc.dart';
import 'presentation/blocs/main_page/main_page_bloc.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/progress/progress_bloc.dart';
import 'providers/theme_provider.dart';
import 'services/supabase_realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");

    // Configurar variables de entorno en SharedPreferences
    await _configureEnvironmentVariables();

    await di.init();
    await initializeDateFormatting('es_ES', null);

    // Inicializar servicios offline
    await LocalDatabaseService().initialize();

    // Inicializar ConnectivityService para detectar estado de conectividad
    await ConnectivityService.instance.initialize();

    // Inicializar NotificationService
    await NotificationService().initialize();

    // Solicitar permisos de notificaciones
    await NotificationService().requestPermissions();

    // Solicitar permisos necesarios
    await PermissionService().requestAllPermissions();

    // Inicializar CalendarService (no requiere inicialización explícita)
    // CalendarService se inicializa automáticamente cuando se usa

    // Inicializar SyncService para sincronización automática
    di.sl<SyncService>().initialize();

    // Inicializar SupabaseRealtimeService para manejo de conexiones en tiempo real
    await SupabaseRealtimeService().initialize();

    runApp(const ViveGoodApp());
  } catch (e) {
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
        Provider<ConnectivityService>(
          create: (context) => ConnectivityService.instance,
        ),
        Provider<SyncService>(create: (context) => di.sl<SyncService>()),
        Provider<ChatRepository>(
          create: (context) {
            final deepLearningDatasource = DeepLearningDatasource(
              httpClient: http.Client(),
              authRepository: di.sl<DeepLearningAuthRepositoryImpl>(),
            );
            return SupabaseChatRepository(
              ChatRemoteDataSource(Supabase.instance.client),
              supabaseDatasource: SupabaseAssistantDatasource(
                Supabase.instance.client,
              ),
              geminiDatasource: GeminiAssistantDatasource(
                apiKey: const String.fromEnvironment(
                  'GOOGLE_API_KEY',
                  defaultValue: 'AIzaSyBVYo2LtacVZLUg88-lyqqi9zHGc6O2BDw',
                ),
                habitAutoCreationService: di.sl<HabitAutoCreationService>(),
                deepLearningDatasource: deepLearningDatasource,
              ),
              deepLearningDatasource: deepLearningDatasource,
            );
          },
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
              BlocProvider(create: (context) => di.sl<HabitStatisticsBloc>()),
              BlocProvider(create: (context) => di.sl<CategoryEvolutionBloc>()),
              BlocProvider(create: (context) => di.sl<CalendarBloc>()),
              BlocProvider(create: (context) => di.sl<ChatBloc>()),
              BlocProvider(create: (context) => di.sl<ProfileBloc>()),
              BlocProvider<AssistantBloc>(
                create: (context) {
                  // Get userId from AuthBloc if available
                  String? userId;
                  final authBloc = context.read<AuthBloc>();
                  final authState = authBloc.state;
                  if (authState is AuthAuthenticated) {
                    userId = authState.user.id;
                  }

                  // Crear instancia del DeepLearningDatasource para reutilizar
                  final deepLearningDatasource = DeepLearningDatasource(
                    httpClient: http.Client(),
                    authRepository: di.sl<DeepLearningAuthRepositoryImpl>(),
                  );

                  return AssistantBloc(
                    chatRepository: SupabaseChatRepository(
                      ChatRemoteDataSource(Supabase.instance.client),
                      supabaseDatasource: SupabaseAssistantDatasource(
                        Supabase.instance.client,
                      ),
                      geminiDatasource: GeminiAssistantDatasource(
                        apiKey: const String.fromEnvironment(
                          'GOOGLE_API_KEY',
                          defaultValue:
                              'AIzaSyBVYo2LtacVZLUg88-lyqqi9zHGc6O2BDw',
                        ),
                        habitAutoCreationService: di
                            .sl<HabitAutoCreationService>(),
                        deepLearningDatasource: deepLearningDatasource,
                      ),
                      deepLearningDatasource: deepLearningDatasource,
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

/// Configura las variables de entorno en SharedPreferences
Future<void> _configureEnvironmentVariables() async {
  final prefs = await SharedPreferences.getInstance();

  // Configurar solo la URL base del API de Deep Learning
  // Las credenciales (email y password) se obtienen del usuario en la interfaz de login
  final dlBaseUrl =
      dotenv.env['DL_BASE_URL'] ?? 'https://api.jeysson.cloud/api/v1';

  await prefs.setString('DL_BASE_URL', dlBaseUrl);

  if (kDebugMode) {
    print('🔧 [MAIN] Variables de entorno configuradas:');
    print('🔧 [MAIN] DL_BASE_URL: $dlBaseUrl');
  }
}
