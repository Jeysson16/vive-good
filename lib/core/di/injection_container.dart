import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Notification imports
import 'package:vive_good_app/data/repositories/local/notification_local_repository.dart';
import 'package:vive_good_app/data/models/local/habit_notification_local_model.dart';
import 'package:vive_good_app/data/models/local/notification_log_local_model.dart';
import 'package:vive_good_app/data/models/local/notification_schedule_local_model.dart';
import 'package:vive_good_app/data/models/local/notification_settings_local_model.dart';
import 'package:vive_good_app/data/repositories/notification_repository_impl.dart';
import 'package:vive_good_app/data/services/notification_service.dart';
import 'package:vive_good_app/domain/repositories/notification_repository.dart';
import 'package:vive_good_app/domain/usecases/notifications/cancel_habit_notification_usecase.dart';
import 'package:vive_good_app/domain/usecases/notifications/manage_notification_settings_usecase.dart';
import 'package:vive_good_app/domain/usecases/notifications/get_pending_notifications_usecase.dart';
import 'package:vive_good_app/domain/usecases/notifications/schedule_habit_notification_usecase.dart';
import 'package:vive_good_app/domain/usecases/notifications/snooze_notification_usecase.dart';
import 'package:vive_good_app/domain/usecases/notifications/manage_habit_notification_usecase.dart';
import 'package:vive_good_app/domain/usecases/notifications/reschedule_notifications_usecase.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_bloc.dart';

import '../../core/network/network_info.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_custom_remote_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/habit_local_datasource.dart';
import '../../data/datasources/habit_remote_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
// Deep Learning imports
import '../../data/datasources/assistant/deep_learning_datasource.dart';
import '../../data/datasources/auth/deep_learning_auth_datasource.dart';
import '../../data/repositories/auth/deep_learning_auth_repository.dart';
import '../../data/datasources/local_database_service.dart';

import '../../data/datasources/onboarding_local_data_source.dart';
import '../../data/datasources/progress_remote_datasource.dart';
// Data sources
import '../../data/datasources/user_local_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/models/onboarding_step_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../data/repositories/local/chat_local_repository.dart';
import '../../data/repositories/local/habit_local_repository.dart';
import '../../data/repositories/local/pending_operations_local_repository.dart';
import '../../data/repositories/local/progress_local_repository.dart';
import '../../data/repositories/local/user_local_repository.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../data/repositories/progress_repository_impl.dart';
// Repositories
import '../../data/repositories/user_repository_impl.dart';
import '../../data/services/calendar_service.dart';
import '../../data/services/habit_calendar_sync_service.dart';
// Services
import '../../data/services/connectivity_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/documentation_service.dart';
import '../../data/services/habit_auto_creation_service.dart';
import '../../data/services/habit_extraction_service.dart';
import '../../data/services/metrics_extraction_service.dart';

import '../../data/services/sync_service.dart';
import '../../domain/repositories/auth_repository.dart';
// Calendar imports
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../domain/usecases/auth/sign_up_usecase.dart';
import '../../domain/usecases/calendar/create_calendar_event.dart';
import '../../domain/usecases/calendar/get_calendar_events.dart';
import '../../domain/usecases/calendar/mark_event_completed.dart';
import '../../domain/usecases/get_daily_week_progress.dart';
import '../../domain/usecases/get_user_progress.dart';
import '../../domain/usecases/get_user_streak.dart';
import '../../domain/usecases/get_monthly_progress.dart';
import '../../domain/usecases/get_monthly_indicators.dart';
import '../../domain/usecases/habit/add_habit_usecase.dart';
import '../../domain/usecases/habit/delete_habit_usecase.dart';
import '../../domain/usecases/habit/delete_user_habit_usecase.dart';
import '../../domain/usecases/habit/get_categories_usecase.dart';
import '../../domain/usecases/habit/get_category_evolution_usecase.dart';
import '../../domain/usecases/habit/get_dashboard_habits_usecase.dart';
import '../../domain/usecases/habit/get_habit_statistics_usecase.dart';
import '../../domain/usecases/habit/get_habit_suggestions_usecase.dart';
import '../../domain/usecases/get_monthly_habits_breakdown.dart';
import '../../domain/usecases/habit/get_user_habit_by_id_usecase.dart';
import '../../domain/usecases/habit/get_user_habits_usecase.dart';
import '../../domain/usecases/habit/log_habit_completion_usecase.dart';
import '../../domain/usecases/habit/update_user_habit_usecase.dart';
import '../../domain/usecases/onboarding/complete_onboarding.dart';
import '../../domain/usecases/onboarding/get_current_step_index.dart';
import '../../domain/usecases/onboarding/get_onboarding_steps.dart';
import '../../domain/usecases/onboarding/set_current_step_index.dart';
// Use cases
import '../../domain/usecases/user/get_current_user.dart';
import '../../domain/usecases/user/has_completed_onboarding.dart';
import '../../domain/usecases/user/is_first_time_user.dart';
import '../../domain/usecases/user/save_user.dart';
import '../../domain/usecases/user/set_first_time_user.dart';
import '../../domain/usecases/user/set_onboarding_completed.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/calendar/calendar_bloc.dart';
import '../../presentation/blocs/category_evolution/category_evolution_bloc.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/dashboard/dashboard_bloc.dart';
import '../../presentation/blocs/habit/habit_bloc.dart';
// Blocs
import '../../presentation/blocs/habit_breakdown/habit_breakdown_bloc.dart';
import '../../presentation/blocs/habit_statistics/habit_statistics_bloc.dart';
import '../../presentation/blocs/progress/progress_bloc.dart';
import '../../presentation/blocs/profile/profile_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Reset GetIt instance to avoid duplicate registrations
  if (sl.isRegistered<HabitBloc>()) {
    await sl.reset();
  }

  //! Features - User
  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SaveUser(sl()));
  sl.registerLazySingleton(() => IsFirstTimeUser(sl()));
  sl.registerLazySingleton(() => SetFirstTimeUser(sl()));
  sl.registerLazySingleton(() => HasCompletedOnboarding(sl()));
  sl.registerLazySingleton(() => SetOnboardingCompleted(sl()));

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      userLocalRepository: sl(),
      connectivityService: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(localDb: sl()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Local repositories
  sl.registerLazySingleton<UserLocalRepository>(
    () => UserLocalRepository(databaseService: sl()),
  );

  sl.registerLazySingleton<ProgressLocalRepository>(
    () => ProgressLocalRepository(databaseService: sl()),
  );

  sl.registerLazySingleton<ChatLocalRepository>(
    () => ChatLocalRepository(databaseService: sl()),
  );

  sl.registerLazySingleton<PendingOperationsLocalRepository>(
    () => PendingOperationsLocalRepository(databaseHelper: sl()),
  );

  //! Features - Onboarding
  // Use cases
  sl.registerLazySingleton(() => GetOnboardingSteps(sl()));
  sl.registerLazySingleton(() => GetCurrentStepIndex(sl()));
  sl.registerLazySingleton(() => SetCurrentStepIndex(sl()));
  sl.registerLazySingleton(() => CompleteOnboarding(sl()));

  // Repository
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      signInUseCase: sl(),
      signUpUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      resetPasswordUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  // Usar la implementación de Supabase para autenticación
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );

  //! Features - Chat
  // Bloc
  sl.registerFactory(
    () => ChatBloc(chatRepository: sl()),
  );

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl()),
  );

  //! Features - Deep Learning
  // Auth Repository
  sl.registerLazySingleton<DeepLearningAuthRepositoryImpl>(
    () => DeepLearningAuthRepositoryImpl(
      datasource: sl(),
    ),
  );

  // Auth Data Source
  sl.registerLazySingleton<DeepLearningAuthDatasource>(
    () => DeepLearningAuthDatasourceImpl(
      client: sl(),
      baseUrl: sl<SharedPreferences>().getString('DL_BASE_URL') ?? 'https://api.jeysson.cloud/api/v1',
      prefs: sl(),
    ),
  );

  // Deep Learning Data Source
  sl.registerLazySingleton<DeepLearningDatasource>(
    () => DeepLearningDatasource(
      httpClient: sl(),
      authRepository: sl(),
    ),
  );

  //! Features - Notification
  // Bloc
  sl.registerFactory(
    () => NotificationBloc(
      scheduleHabitNotificationUseCase: sl(),
      cancelHabitNotificationUseCase: sl(),
      snoozeNotificationUseCase: sl(),
      getPendingNotificationsUseCase: sl(),
      updateHabitNotificationUseCase: sl(),
      getSchedulesByNotificationIdUseCase: sl(),
      getNotificationSettingsUseCase: sl(),
      updateNotificationSettingsUseCase: sl(),
      requestNotificationPermissionsUseCase: sl(),
      checkNotificationPermissionsUseCase: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      notificationLocalRepository: sl(),
      notificationService: sl(),
    ),
  );

  // Local repositories
  sl.registerLazySingleton<NotificationLocalRepository>(
    () => NotificationLocalRepository(databaseService: sl()),
  );

  // Services
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Use cases
  sl.registerLazySingleton(() => ScheduleHabitNotificationUseCase(sl()));
  sl.registerLazySingleton(() => CancelHabitNotificationUseCase(sl()));
  sl.registerLazySingleton(() => CancelAllNotificationsForHabitUseCase(sl()));
  sl.registerLazySingleton(() => SnoozeNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => CreateHabitNotificationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateHabitNotificationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHabitNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetHabitNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllHabitNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNotificationSettingsUseCase(sl()));
  sl.registerLazySingleton(() => RequestNotificationPermissionsUseCase(sl()));
  sl.registerLazySingleton(() => CheckNotificationPermissionsUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleAllNotificationsUseCase(sl()));

  //! Features - Habit
  // Habit BLoC
  sl.registerFactory<HabitBloc>(
    () => HabitBloc(
      getUserHabitsUseCase: sl(),
      getUserHabitByIdUseCase: sl(),
      getCategoriesUseCase: sl(),
      logHabitCompletionUseCase: sl(),
      getHabitSuggestionsUseCase: sl(),
      getDashboardHabitsUseCase: sl(),
      addHabitUseCase: sl(),
      deleteHabitUseCase: sl(),
      updateUserHabitUseCase: sl(),
      deleteUserHabitUseCase: sl(),
      scheduleHabitNotificationUseCase: sl(),
      cancelHabitNotificationUseCase: sl(),
      cancelAllNotificationsForHabitUseCase: sl(),
      createHabitNotificationUseCase: sl(),
      updateHabitNotificationUseCase: sl(),
      deleteHabitNotificationUseCase: sl(),
    ),
  );

  //! Features - Dashboard
  // Bloc
  sl.registerFactory(
    () => DashboardBloc(
      getDashboardHabitsUseCase: sl(),
      getCategoriesUseCase: sl(),
    ),
  );

  //! Features - Progress
  // Bloc
  sl.registerFactory(
    () => ProgressBloc(
      getUserProgress: sl(),
      getDailyWeekProgress: sl(),
      getUserStreak: sl(),
      getMonthlyProgress: sl(),
      getMonthlyIndicators: sl(),
    ),
  );

  //! Features - Profile
  // Bloc
  sl.registerFactory(
    () => ProfileBloc(supabaseClient: sl()),
  );

  //! Features - Calendar
  // Bloc
  sl.registerFactory(
    () => CalendarBloc(
      getCalendarEvents: sl(),
      createCalendarEvent: sl(),
      markEventCompleted: sl(),
      habitCalendarSyncService: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(
      calendarService: sl(),
      notificationService: sl(),
      supabaseClient: sl(),
    ),
  );

  // Services
  sl.registerLazySingleton(() => CalendarService(sl()));
  sl.registerLazySingleton(() => HabitCalendarSyncService(sl(), sl()));
  sl.registerLazySingleton(() => MetricsExtractionService(sl()));
  sl.registerLazySingleton(() => HabitExtractionService());
  sl.registerLazySingleton(
    () => HabitAutoCreationService(
      habitRepository: sl(),
      habitExtractionService: sl(),
    ),
  );
  sl.registerLazySingleton(() => DocumentationService());

  // Use cases
  sl.registerLazySingleton(() => GetUserProgress(sl()));
  sl.registerLazySingleton(() => GetDailyWeekProgress(sl()));
  sl.registerLazySingleton(() => GetUserStreak(sl()));
  sl.registerLazySingleton(() => GetMonthlyProgress(sl()));
  sl.registerLazySingleton(() => GetMonthlyIndicators(sl()));

  // Calendar Use cases
  sl.registerLazySingleton(() => GetCalendarEvents(sl()));
  sl.registerLazySingleton(() => CreateCalendarEvent(sl()));
  sl.registerLazySingleton(() => MarkEventCompleted(sl()));

  // Repository
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      connectivityService: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProgressRemoteDataSource>(
    () => ProgressRemoteDataSourceImpl(client: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AddHabitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHabitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUserHabitUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardHabitsUseCase(sl()));
  sl.registerLazySingleton(() => GetHabitSuggestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserHabitsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserHabitByIdUseCase(sl()));
  sl.registerLazySingleton(() => LogHabitCompletionUseCase(sl()));
  sl.registerLazySingleton(() => GetMonthlyHabitsBreakdown(sl()));
  sl.registerLazySingleton(() => UpdateUserHabitUseCase(sl()));
  sl.registerLazySingleton(() => GetHabitStatisticsUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryEvolutionUseCase(sl()));

  //! Features - Habit Breakdown
  // Bloc
  sl.registerFactory(() => HabitBreakdownBloc(getMonthlyHabitsBreakdown: sl()));

  //! Features - Habit Statistics
  // Bloc
  sl.registerFactory(
    () => HabitStatisticsBloc(getHabitStatisticsUseCase: sl()),
  );

  //! Features - Category Evolution
  // Bloc
  sl.registerFactory(
    () => CategoryEvolutionBloc(getCategoryEvolutionUseCase: sl()),
  );

  // Repository
  sl.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      habitLocalRepository: sl(),
      connectivityService: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<HabitLocalDataSource>(
    () => HabitLocalDataSourceImpl(localDb: sl()),
  );
  sl.registerLazySingleton<HabitRemoteDataSource>(
    () => HabitRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Local repositories
  sl.registerLazySingleton<HabitLocalRepository>(
    () => HabitLocalRepository(databaseService: sl<DatabaseService>()),
  );

  // Services
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService.instance,
  );

  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      connectivityService: sl(),
      habitLocalRepository: sl(),
      progressLocalRepository: sl(),
      userLocalRepository: sl(),
      chatLocalRepository: sl(),
      pendingOperationsRepository: sl(),
      habitRemoteDataSource: sl(),
      progressRemoteDataSource: sl(),
      userRemoteDataSource: sl(),
      chatRemoteDataSource: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://numrwrjuslomfbsnllbe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51bXJ3cmp1c2xvbWZic25sbGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MjE4MTksImV4cCI6MjA3MzM5NzgxOX0.chEXoTra7OoRtqsET0lcBtUnhsPup8Fmvv5d2tMyy20',
  );
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Apply database migrations
  // Note: conversations table migration removed - using chat_sessions instead
  // try {
  //   await Supabase.instance.client.rpc('apply_conversations_and_metrics_migration');
  // } catch (e) {
  //   // Migration might already be applied or function might not exist
  //   print('Migration info: $e');
  // }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(OnboardingStepModelAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(HabitNotificationLocalModelAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(NotificationScheduleLocalModelAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(NotificationLogLocalModelAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(NotificationSettingsLocalModelAdapter());
  }

  // Register LocalDatabaseService
  sl.registerLazySingleton<LocalDatabaseService>(() => LocalDatabaseService());

  // Register DatabaseService
  sl.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);

  // Register DatabaseHelper
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
}
