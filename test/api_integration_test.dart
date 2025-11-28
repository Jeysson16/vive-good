import 'package:flutter_test/flutter_test.dart';
import 'package:vive_good_app/core/config/app_config.dart';
import 'package:vive_good_app/core/di/injection_container.dart' as di;
import 'package:vive_good_app/domain/usecases/habit/get_monthly_habits_breakdown.dart';
import 'package:vive_good_app/domain/usecases/habit/get_habit_statistics_usecase.dart';
import 'package:vive_good_app/domain/usecases/habit/get_category_evolution_usecase.dart';
import 'package:vive_good_app/data/datasources/gemini_ai_datasource.dart';

void main() {
  group('API Integration Tests', () {
    setUpAll(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize dependencies
      await di.init();
      await AppConfig.initialize();
    });

    group('Supabase Integration Tests', () {
      test('should have valid Supabase configuration', () {
        expect(AppConfig.isSupabaseConfigured, isTrue);
        expect(AppConfig.supabaseUrl, isNotEmpty);
        expect(AppConfig.supabaseAnonKey, isNotEmpty);
      });

      test('should fetch monthly habits breakdown from Supabase', () async {
        // Use a test user ID that exists in the database
        const testUserId = '8d90c3a0-83ac-4f80-ba69-4f650de0dd29';
        
        final getMonthlyBreakdown = di.sl<GetMonthlyHabitsBreakdown>();
        final result = await getMonthlyBreakdown(
          GetMonthlyHabitsBreakdownParams(
            userId: testUserId,
            year: 2025,
            month: 10,
          ),
        );
        
        result.fold(
          (failure) {
            print('Error fetching monthly breakdown: ${failure.message}');
            fail('Failed to fetch monthly habits breakdown: ${failure.message}');
          },
          (breakdown) {
            print('Successfully fetched ${breakdown.length} monthly breakdown records');
            expect(breakdown, isNotNull);
            expect(breakdown, isA<List>());
          },
        );
      });

      test('should fetch habit statistics from Supabase', () async {
        const testUserId = '8d90c3a0-83ac-4f80-ba69-4f650de0dd29';
        
        final getHabitStatistics = di.sl<GetHabitStatisticsUseCase>();
        final result = await getHabitStatistics(
          GetHabitStatisticsParams(
            userId: testUserId,
            year: 2025,
            month: 10,
          ),
        );
        
        result.fold(
          (failure) {
            print('Error fetching habit statistics: ${failure.message}');
            fail('Failed to fetch habit statistics: ${failure.message}');
          },
          (statistics) {
            print('Successfully fetched habit statistics');
            expect(statistics, isNotNull);
          },
        );
      });

      test('should fetch category evolution from Supabase', () async {
        const testUserId = '8d90c3a0-83ac-4f80-ba69-4f650de0dd29';
        
        final getCategoryEvolution = di.sl<GetCategoryEvolutionUseCase>();
        final result = await getCategoryEvolution(
          GetCategoryEvolutionParams(
            userId: testUserId,
            year: 2025,
            month: 10,
          ),
        );
        
        result.fold(
          (failure) {
            print('Error fetching category evolution: ${failure.message}');
            fail('Failed to fetch category evolution: ${failure.message}');
          },
          (evolution) {
            print('Successfully fetched category evolution');
            expect(evolution, isNotNull);
            expect(evolution, isA<List>());
          },
        );
      });
    });

    group('Gemini AI Integration Tests', () {
      test('should have valid Gemini AI configuration', () {
        expect(AppConfig.isGeminiConfigured, isTrue);
        expect(AppConfig.geminiApiKey, isNotEmpty);
      });

      test('should generate habit suggestions from Gemini AI', () async {
        final geminiDataSource = GeminiAIDataSourceImpl();
        
        try {
          final suggestions = await geminiDataSource.generateHabitSuggestions(
            habitName: 'Beber agua',
            category: 'Hidratación',
            description: 'Mantenerse hidratado durante el día',
            userGoals: 'Mejorar la salud digestiva',
          );
          
          print('Successfully generated habit suggestions from Gemini AI');
          expect(suggestions, isNotNull);
          expect(suggestions, isA<Map<String, dynamic>>());
          expect(suggestions.containsKey('optimizedName'), isTrue);
          expect(suggestions.containsKey('suggestedDuration'), isTrue);
          expect(suggestions.containsKey('bestTimes'), isTrue);
          expect(suggestions.containsKey('difficulty'), isTrue);
          expect(suggestions.containsKey('tips'), isTrue);
          expect(suggestions.containsKey('frequency'), isTrue);
          expect(suggestions.containsKey('motivation'), isTrue);
        } catch (e) {
          print('Error generating habit suggestions: $e');
          // Don't fail the test if Gemini AI is not available (rate limit, etc.)
          if (e.toString().contains('quota') || e.toString().contains('429')) {
            print('Gemini AI rate limit exceeded - skipping test');
            return;
          }
          fail('Failed to generate habit suggestions: $e');
        }
      });

      test('should generate schedule suggestions from Gemini AI', () async {
        final geminiDataSource = GeminiAIDataSourceImpl();
        
        try {
          final scheduleSuggestions = await geminiDataSource.generateScheduleSuggestions(
            habitName: 'Beber agua',
            category: 'Hidratación',
            userPreferences: 'Preferencia por las mañanas',
          );
          
          print('Successfully generated schedule suggestions from Gemini AI');
          expect(scheduleSuggestions, isNotNull);
          expect(scheduleSuggestions, isA<List<String>>());
          expect(scheduleSuggestions.length, greaterThan(0));
        } catch (e) {
          print('Error generating schedule suggestions: $e');
          // Don't fail the test if Gemini AI is not available (rate limit, etc.)
          if (e.toString().contains('quota') || e.toString().contains('429')) {
            print('Gemini AI rate limit exceeded - skipping test');
            return;
          }
          fail('Failed to generate schedule suggestions: $e');
        }
      });
    });

    group('Configuration Validation Tests', () {
      test('should validate all required environment variables are present', () {
        final config = AppConfig.allConfig;
        
        print('Current configuration:');
        config.forEach((key, value) {
          final maskedValue = key.contains('KEY') && value.isNotEmpty 
              ? '${value.substring(0, 10)}...' 
              : value;
          print('$key: $maskedValue');
        });
        
        expect(config['SUPABASE_URL'], isNotEmpty);
        expect(config['SUPABASE_ANON_KEY'], isNotEmpty);
        expect(config['GOOGLE_API_KEY'], isNotEmpty);
      });
    });
  });
}