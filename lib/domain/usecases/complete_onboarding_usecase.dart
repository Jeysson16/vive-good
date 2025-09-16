import '../repositories/onboarding_repository.dart';
import '../repositories/user_repository.dart';

class CompleteOnboardingUseCase {
  final OnboardingRepository onboardingRepository;
  final UserRepository userRepository;

  CompleteOnboardingUseCase({
    required this.onboardingRepository,
    required this.userRepository,
  });

  Future<void> call() async {
    await onboardingRepository.completeOnboarding();
    await userRepository.setOnboardingCompleted(true);
    await userRepository.setFirstTimeUser(false);
  }
}