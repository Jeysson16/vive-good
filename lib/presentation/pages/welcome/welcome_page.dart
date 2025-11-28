import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeView();
  }
}

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLargeScreen = screenSize.width > 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isLargeScreen ? 48.0 : (isSmallScreen ? 16.0 : 24.0),
            right: isLargeScreen ? 48.0 : (isSmallScreen ? 16.0 : 24.0),
            top: isSmallScreen ? 16.0 : (isLargeScreen ? 24.0 : 20.0),
            bottom: keyboardHeight > 0 ? 16.0 : (isSmallScreen ? 40.0 : 60.0),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenSize.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  keyboardHeight,
              maxWidth: isLargeScreen ? 500 : double.infinity,
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo/Image
                    SizedBox(
                      width: isSmallScreen ? 100 : (isLargeScreen ? 140 : 124),
                      height: isSmallScreen ? 104 : (isLargeScreen ? 145 : 129),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: isSmallScreen
                            ? 100
                            : (isLargeScreen ? 140 : 124),
                        height: isSmallScreen
                            ? 104
                            : (isLargeScreen ? 145 : 129),
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(
                      height: isSmallScreen ? 40 : (isLargeScreen ? 80 : 63),
                    ),

                    // Welcome Text
                    SizedBox(
                      width: double.infinity,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Bienvenido a\n',
                              style: TextStyle(
                                fontSize: isSmallScreen
                                    ? 32
                                    : (isLargeScreen ? 48 : 40),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212121),
                                height: 1.6,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                            TextSpan(
                              text: 'Vive',
                              style: TextStyle(
                                fontSize: isSmallScreen
                                    ? 32
                                    : (isLargeScreen ? 48 : 40),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF219540),
                                height: 1.6,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                            TextSpan(
                              text: 'Good',
                              style: TextStyle(
                                fontSize: isSmallScreen
                                    ? 32
                                    : (isLargeScreen ? 48 : 40),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D57AF),
                                height: 1.6,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: isSmallScreen ? 40 : (isLargeScreen ? 80 : 63),
                    ),

                    // Buttons Container
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen
                            ? 0
                            : (isLargeScreen ? 16 : 8),
                      ),
                      child: Column(
                        children: [
                          // Iniciar Sesión Button
                          Container(
                            width: double.infinity,
                            height: isSmallScreen
                                ? 56
                                : (isLargeScreen ? 70 : 63),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(95),
                              color: const Color(0xFF090D3A),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF17CE92,
                                  ).withOpacity(0.25),
                                  offset: const Offset(4, 8),
                                  blurRadius: 24,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                context.go(AppRoutes.login);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF090D3A),
                                foregroundColor: const Color(0xFFFFFFFF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(95),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen
                                      ? 14
                                      : (isLargeScreen ? 20 : 17),
                                  horizontal: isSmallScreen
                                      ? 12
                                      : (isLargeScreen ? 18 : 15),
                                ),
                              ),
                              child: Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 16
                                      : (isLargeScreen ? 20 : 18),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 16
                                : (isLargeScreen ? 30 : 23),
                          ),

                          // Registrarse Button
                          Container(
                            width: double.infinity,
                            height: isSmallScreen
                                ? 56
                                : (isLargeScreen ? 70 : 63),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(95),
                              color: const Color(0xFFE3E3E3),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                context.go(AppRoutes.register);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3E3E3),
                                foregroundColor: const Color(0xFFB1B1B1),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(95),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen
                                      ? 14
                                      : (isLargeScreen ? 20 : 17),
                                  horizontal: isSmallScreen
                                      ? 12
                                      : (isLargeScreen ? 18 : 15),
                                ),
                              ),
                              child: Text(
                                'Registrarse',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 15
                                      : (isLargeScreen ? 19 : 17),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.19,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
