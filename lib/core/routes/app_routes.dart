import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/welcome/welcome_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/main/main_page.dart';
import '../../presentation/pages/calendar/calendar_view_page.dart';
import '../../views/profile/edit_profile_view.dart';
import '../../models/user_profile.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String calendar = '/calendar';
  static const String editProfile = '/edit-profile';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashPage()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: welcome, builder: (context, state) => const WelcomePage()),
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(path: register, builder: (context, state) => const RegisterPage()),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: main,
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: calendar,
        builder: (context, state) => const CalendarViewPage(),
      ),
      GoRoute(
        path: editProfile,
        builder: (context, state) {
          final profile = state.extra as UserProfile;
          return EditProfileView(profile: profile);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Página no encontrada'))),
  );
}
