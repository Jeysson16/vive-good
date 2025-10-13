import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/splash/splash_bloc.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/routes/app_routes.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc(
        isFirstTimeUser: di.sl(),
        hasCompletedOnboarding: di.sl(),
        getCurrentUser: di.sl(),
        saveUser: di.sl(),
        habitBloc: context.read<HabitBloc>(),
        dashboardBloc: context.read<DashboardBloc>(),
        authBloc: context.read<AuthBloc>(),
      ),
      child: const SplashView(),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;

  bool _showLogo = true;
  bool _showText = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5s for bounce animation
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 1s for text animation
      vsync: this,
    );

    // Logo bounce animation with elastic effect
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Text slide up animation from bottom
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Start animation sequence
    _startAnimationSequence();

    // Start app status check after 4 seconds (after both animation phases)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        context.read<SplashBloc>().add(const CheckAppStatus());
      }
    });
  }

  void _startAnimationSequence() async {
    // Phase 1: Logo appears and bounces (2 seconds)
    if (!mounted) return;
    await _logoController.forward();

    // Wait for logo phase to complete (total 2 seconds)
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 2: Hide logo and show text (2 seconds)
    if (!mounted) return;
    setState(() {
      _showLogo = false;
      _showText = true;
    });

    // Start text animation from bottom
    if (!mounted) return;
    await _textController.forward();

    // Wait for text phase to complete (total 2 seconds)
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 3: Navigation will be handled by SplashBloc after 4 seconds total
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLargeScreen = screenSize.width > 600;

    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToOnboarding) {
          context.go(AppRoutes.onboarding);
        } else if (state is SplashNavigateToWelcome) {
          context.go(AppRoutes.welcome);
        } else if (state is SplashNavigateToMain) {
          context.go(AppRoutes.main);
        } else if (state is SplashError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Stack(
          children: [
            // First Splash - Logo with bounce animation
            if (_showLogo)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: isSmallScreen ? 280 : (isLargeScreen ? 450 : 384),
                    ), // Top padding from Figma
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoOpacityAnimation.value,
                            child: Container(
                              width: isSmallScreen
                                  ? 100
                                  : (isLargeScreen ? 150 : 124),
                              height: isSmallScreen
                                  ? 104
                                  : (isLargeScreen ? 156 : 129),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: isSmallScreen
                                    ? 100
                                    : (isLargeScreen ? 150 : 124),
                                height: isSmallScreen
                                    ? 104
                                    : (isLargeScreen ? 156 : 129),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Version text at bottom (from first design)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: isSmallScreen ? 30 : (isLargeScreen ? 50 : 39),
                      ), // Bottom padding from Figma
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Version',
                              style: TextStyle(
                                fontSize: isSmallScreen
                                    ? 14
                                    : (isLargeScreen ? 18 : 16),
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF757171),
                                letterSpacing: -0.32,
                                fontFamily: 'Poppins',
                                height: 24 / 16,
                              ),
                            ),
                            TextSpan(
                              text: ' 1.0',
                              style: TextStyle(
                                fontSize: isSmallScreen
                                    ? 12
                                    : (isLargeScreen ? 16 : 14),
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF757171),
                                letterSpacing: -0.28,
                                fontFamily: 'Poppins',
                                height: 24 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Second Splash - Text only (Splash V2 design)
            if (_showText)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: isSmallScreen ? 320 : (isLargeScreen ? 520 : 436),
                    ), // Top padding from Figma V2
                    // Animated ViveGood Text - Phase 2
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _textOpacityAnimation,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Vive',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 28
                                      : (isLargeScreen ? 42 : 35),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF219540),
                                  fontFamily: 'Poppins',
                                  letterSpacing: -0.7,
                                  height: 24 / 35,
                                ),
                              ),
                              TextSpan(
                                text: 'Good',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 28
                                      : (isLargeScreen ? 42 : 35),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2D57AF),
                                  fontFamily: 'Poppins',
                                  letterSpacing: -0.7,
                                  height: 24 / 35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: isSmallScreen ? 6 : (isLargeScreen ? 12 : 8),
                    ),

                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _textOpacityAnimation,
                        child: Text(
                          'Version 1.0',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 12
                                : (isLargeScreen ? 16 : 14),
                            color: const Color(0xFF757171),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
