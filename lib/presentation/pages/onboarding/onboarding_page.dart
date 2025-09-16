import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/routes/app_routes.dart';
import '../../widgets/onboarding_step_widget.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(
        getOnboardingSteps: di.sl(),
        getCurrentStepIndex: di.sl(),
        setCurrentStepIndex: di.sl(),
        completeOnboarding: di.sl(),
      ),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    context.read<OnboardingBloc>().add(const LoadOnboardingSteps());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLargeScreen = screenSize.width > 600;
    
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          context.go(AppRoutes.welcome);
        } else if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is OnboardingLoaded) {
          // Sincronizar PageController con el estado del bloc
          if (_pageController.hasClients && 
              _pageController.page?.round() != state.currentIndex) {
            _pageController.animateToPage(
              state.currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA), // Fondo según diseño Figma
        body: SafeArea(
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              if (state is OnboardingLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E5BFF),
                    ),
                  ),
                );
              }

              if (state is OnboardingLoaded) {
                return Column(
                  children: [
                    // Skip Button
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : (isLargeScreen ? 20.0 : 16.0)),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                          ),
                          onPressed: () {
                            context.read<OnboardingBloc>().add(
                              const CompleteOnboardingEvent(),
                            );
                          },
                          child: Text(
                            'Saltar',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: isSmallScreen ? 14 : (isLargeScreen ? 18 : 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Page View
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          context.read<OnboardingBloc>().add(
                            index > state.currentIndex
                                ? const NextStep()
                                : const PreviousStep(),
                          );
                        },
                        itemCount: state.steps.length,
                        itemBuilder: (context, index) {
                          return OnboardingStepWidget(step: state.steps[index]);
                        },
                      ),
                    ),

                    // Page Indicators
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : (isLargeScreen ? 24 : 20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          state.steps.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 3 : (isLargeScreen ? 6 : 4),
                            ),
                            width: isSmallScreen ? 6 : (isLargeScreen ? 10 : 8),
                            height: isSmallScreen ? 6 : (isLargeScreen ? 10 : 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == state.currentIndex
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Navigation Buttons
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : (isLargeScreen ? 32.0 : 24.0)),
                      child: Center(
                        child: Container(
                          width: isSmallScreen ? 120 : (isLargeScreen ? 180 : 154),
                          height: isSmallScreen ? 56 : (isLargeScreen ? 72 : 64),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : (isLargeScreen ? 20 : 16)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F0F0F0F),
                                blurRadius: 32,
                                offset: Offset(0, 40),
                                spreadRadius: -24,
                              ),
                            ],
                            color: const Color(0xFFFCFCFD),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Previous Button
                              if (!state.isFirstStep)
                                IconButton(
                                  style: IconButton.styleFrom(
                                    minimumSize: Size(
                                      isSmallScreen ? 40 : (isLargeScreen ? 52 : 44),
                                      isSmallScreen ? 40 : (isLargeScreen ? 52 : 44),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_pageController.hasClients) {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: const Color(0xFF6B7280),
                                    size: isSmallScreen ? 20 : (isLargeScreen ? 28 : 24),
                                  ),
                                )
                              else
                                SizedBox(width: isSmallScreen ? 20 : (isLargeScreen ? 28 : 24)),
                              
                              // Separator
                              if (!state.isFirstStep || !state.isLastStep)
                                Container(
                                  width: 2,
                                  height: isSmallScreen ? 20 : (isLargeScreen ? 28 : 24),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : (isLargeScreen ? 20 : 16),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: const Color(0xFFE6E8EC),
                                  ),
                                ),
                              
                              // Next/Finish Button
                              IconButton(
                                style: IconButton.styleFrom(
                                  minimumSize: Size(
                                    isSmallScreen ? 40 : (isLargeScreen ? 52 : 44),
                                    isSmallScreen ? 40 : (isLargeScreen ? 52 : 44),
                                  ),
                                ),
                                onPressed: () {
                                  if (state.isLastStep) {
                                    context.read<OnboardingBloc>().add(
                                      const CompleteOnboardingEvent(),
                                    );
                                  } else {
                                    if (_pageController.hasClients) {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  }
                                },
                                icon: Icon(
                                  state.isLastStep ? Icons.check : Icons.arrow_forward_ios,
                                  color: const Color(0xFF6B7280),
                                  size: isSmallScreen ? 20 : (isLargeScreen ? 28 : 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const Center(child: Text('Error loading onboarding'));
            },
          ),
        ),
      ),
    );
  }
}
