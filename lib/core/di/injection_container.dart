import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data sources
import '../../data/datasources/user_local_datasource.dart';
import '../../data/datasources/onboarding_local_data_source.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/habit_local_datasource.dart';
import '../../data/datasources/habit_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/onboarding_step_model.dart';

// Repositories
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/habit_repository.dart';

// Use cases
import '../../domain/usecases/user/get_current_user.dart';
import '../../domain/usecases/user/save_user.dart';
import '../../domain/usecases/user/is_first_time_user.dart';
import '../../domain/usecases/user/set_first_time_user.dart';
import '../../domain/usecases/user/has_completed_onboarding.dart';
import '../../domain/usecases/user/set_onboarding_completed.dart';
import '../../domain/usecases/onboarding/get_onboarding_steps.dart';
import '../../domain/usecases/onboarding/get_current_step_index.dart';
import '../../domain/usecases/onboarding/set_current_step_index.dart';
import '../../domain/usecases/onboarding/complete_onboarding.dart';
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/sign_up_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import '../../domain/usecases/habit/add_habit_usecase.dart';
import '../../domain/usecases/habit/delete_habit_usecase.dart';
import '../../domain/usecases/habit/get_categories_usecase.dart';
import '../../domain/usecases/habit/get_dashboard_habits_usecase.dart';
import '../../domain/usecases/habit/get_habit_suggestions_usecase.dart';
import '../../domain/usecases/habit/get_user_habits_usecase.dart';
import '../../domain/usecases/habit/log_habit_completion_usecase.dart';
import '../../domain/usecases/habit/get_monthly_habits_breakdown.dart';
import '../../domain/usecases/calendar/get_calendar_events.dart';
import '../../domain/usecases/calendar/create_calendar_event.dart';
import '../../domain/usecases/calendar/mark_event_completed.dart';

// Blocs
import '../../presentation/blocs/habit_breakdown/habit_breakdown_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/habit/habit_bloc.dart';
import '../../presentation/blocs/progress/progress_bloc.dart';
import '../../presentation/bloc/calendar/calendar_bloc.dart';

// Calendar imports
import '../../domain/repositories/calendar_repository.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../data/services/calendar_service.dart';
import '../../data/services/notification_service.dart';
import '../../domain/usecases/get_user_progress.dart';
import '../../domain/usecases/get_daily_week_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/datasources/progress_remote_datasource.dart';
import '../../core/network/network_info.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';

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
    () => UserRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(),
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
  sl.registerFactory(() => AuthBloc(
    signInUseCase: sl(),
    signUpUseCase: sl(),
    signOutUseCase: sl(),
    getCurrentUserUseCase: sl(),
    resetPasswordUseCase: sl(),
    authRepository: sl(),
  ));

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
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );

  //! Features - Habit
  // Bloc
  sl.registerFactory(() => HabitBloc(
    addHabitUseCase: sl(),
    deleteHabitUseCase: sl(),
    getCategoriesUseCase: sl(),
    getDashboardHabitsUseCase: sl(),
    getHabitSuggestionsUseCase: sl(),
    getUserHabitsUseCase: sl(),
    logHabitCompletionUseCase: sl(),
  ));

  //! Features - Progress
  // Bloc
  sl.registerFactory(() => ProgressBloc(
    getUserProgress: sl(),
    getDailyWeekProgress: sl(),
  ));

  //! Features - Habit Breakdown
  // Bloc
  sl.registerFactory(() => HabitBreakdownBloc(
    getMonthlyHabitsBreakdown: sl(),
  ));

  //! Features - Calendar
  // Bloc
  sl.registerFactory(() => CalendarBloc(
    getCalendarEvents: sl(),
    createCalendarEvent: sl(),
    markEventCompleted: sl(),
  ));

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
  sl.registerLazySingleton(() => NotificationService());

  // Use cases
  sl.registerLazySingleton(() => GetUserProgress(sl()));
  sl.registerLazySingleton(() => GetDailyWeekProgress(sl()));

  // Calendar Use cases
  sl.registerLazySingleton(() => GetCalendarEvents(sl()));
  sl.registerLazySingleton(() => CreateCalendarEvent(sl()));
  sl.registerLazySingleton(() => MarkEventCompleted(sl()));

  // Repository
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProgressRemoteDataSource>(
    () => ProgressRemoteDataSourceImpl(
      client: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddHabitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHabitUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardHabitsUseCase(sl()));
  sl.registerLazySingleton(() => GetHabitSuggestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserHabitsUseCase(sl()));
  sl.registerLazySingleton(() => LogHabitCompletionUseCase(sl()));
  sl.registerLazySingleton(() => GetMonthlyHabitsBreakdown(sl()));

  // Repository
  sl.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<HabitLocalDataSource>(
    () => HabitLocalDataSourceImpl(hive: sl()),
  );
  sl.registerLazySingleton<HabitRemoteDataSource>(
    () => HabitRemoteDataSourceImpl(supabaseClient: sl()),
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
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51bXJ3cmp1c2xvbWZic25sbGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MjE4MTksImV4cCI6MjA3MzM5NzgxOX0.chEXoTra7OoRtqsET0lcBtUnhsPup8Fmvv5d2tMyy20',
  );
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(OnboardingStepModelAdapter());
  }
}
