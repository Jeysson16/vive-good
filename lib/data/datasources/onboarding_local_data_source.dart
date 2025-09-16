import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_step_model.dart';

abstract class OnboardingLocalDataSource {
  Future<List<OnboardingStepModel>> getOnboardingSteps();
  Future<OnboardingStepModel?> getOnboardingStepById(String id);
  Future<int> getCurrentStepIndex();
  Future<void> setCurrentStepIndex(int index);
  Future<void> completeOnboarding();
  Future<bool> isOnboardingCompleted();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String CURRENT_STEP_INDEX_KEY = 'CURRENT_STEP_INDEX';
  static const String ONBOARDING_COMPLETED_KEY = 'ONBOARDING_COMPLETED';

  OnboardingLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<OnboardingStepModel>> getOnboardingSteps() async {
    // Datos hardcodeados para las pantallas de onboarding según diseños Figma
    return [
      const OnboardingStepModel(
        id: '1',
        title: 'Gestiona el\nEstrés',
        description:
            'Una mente positiva y resiliente es clave para el bienestar',
        imagePath: 'assets/images/onboarding_1.png',
        order: 0,
      ),
      const OnboardingStepModel(
        id: '2',
        title: 'Detecta\nSíntomas',
        description:
            'Identifica los signos tempranos de gastritis a tiempo',
        imagePath: 'assets/images/onboarding_2.png',
        order: 1,
      ),
      const OnboardingStepModel(
        id: '3',
        title: 'Come Mejor',
        description:
            'Come mejor con nuestras recetas y consejos',
        imagePath: 'assets/images/onboarding_3.png',
        order: 2,
      ),
    ];
  }

  @override
  Future<OnboardingStepModel?> getOnboardingStepById(String id) async {
    final steps = await getOnboardingSteps();
    try {
      return steps.firstWhere((step) => step.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> getCurrentStepIndex() async {
    return sharedPreferences.getInt(CURRENT_STEP_INDEX_KEY) ?? 0;
  }

  @override
  Future<void> setCurrentStepIndex(int index) async {
    await sharedPreferences.setInt(CURRENT_STEP_INDEX_KEY, index);
  }

  @override
  Future<void> completeOnboarding() async {
    await sharedPreferences.setBool(ONBOARDING_COMPLETED_KEY, true);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return sharedPreferences.getBool(ONBOARDING_COMPLETED_KEY) ?? false;
  }
}
