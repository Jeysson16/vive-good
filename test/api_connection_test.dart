import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('API Connection Tests', () {
    setUpAll(() async {
      await dotenv.load(fileName: ".env");
    });

    test('should connect to Supabase successfully', () async {
      final supabaseUrl = dotenv.get('SUPABASE_URL');
      final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');

      expect(supabaseUrl, isNotEmpty);
      expect(supabaseAnonKey, isNotEmpty);

      try {
        final supabase = await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );

        final client = supabase.client;

        // Test connection by fetching user habits
        final response = await client.from('user_habits').select().limit(1);

        expect(response, isNotNull);
        print('✅ Supabase connection successful');
        print('Found ${response.length} user habits');
      } catch (e) {
        fail('Supabase connection failed: $e');
      }
    });

    test('should connect to Gemini AI successfully', () async {
      final geminiApiKey = dotenv.get('GOOGLE_API_KEY');

      expect(geminiApiKey, isNotEmpty);
      expect(geminiApiKey, isNot('your-gemini-api-key-here'));

      try {
        final model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: geminiApiKey,
        );

        final prompt =
            'Hello, this is a test message. Please respond with "Test successful".';
        final response = await model.generateContent([Content.text(prompt)]);

        expect(response.text, isNotEmpty);
        print('✅ Gemini AI connection successful');
        print('Response: ${response.text}');
      } catch (e) {
        if (e.toString().contains('429')) {
          print('⚠️ Gemini AI rate limited (expected with demo key)');
          // This is expected with the demo API key
        } else {
          fail('Gemini AI connection failed: $e');
        }
      }
    });

    test('should validate JWT token format', () {
      final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');

      // JWT tokens should have 3 parts separated by dots
      final parts = supabaseAnonKey.split('.');
      expect(parts.length, equals(3));

      // Each part should be base64 encoded
      for (final part in parts) {
        expect(part, isNotEmpty);
        // Basic base64 validation
        expect(part.length % 4, equals(0));
      }

      print('✅ JWT token format valid');
    });
  });
}
