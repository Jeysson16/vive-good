import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() {
  group('API Configuration Tests', () {
    setUpAll(() async {
      // Load environment variables
      await dotenv.load(fileName: ".env");
    });

    test('should have valid Supabase configuration', () {
      final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
      final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
      
      print('Supabase URL: ${supabaseUrl.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
      print('Supabase Anon Key: ${supabaseAnonKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
      
      expect(supabaseUrl, isNotEmpty, reason: 'SUPABASE_URL should be configured');
      expect(supabaseAnonKey, isNotEmpty, reason: 'SUPABASE_ANON_KEY should be configured');
      
      // Validate URL format
      expect(supabaseUrl, startsWith('https://'), reason: 'Supabase URL should be HTTPS');
      expect(supabaseUrl, contains('supabase.co'), reason: 'Supabase URL should contain supabase.co');
      
      // Validate key format (JWT)
      expect(supabaseAnonKey, contains('.'), reason: 'Supabase key should be a JWT token');
      expect(supabaseAnonKey.length, greaterThan(50), reason: 'Supabase key should be a reasonable length');
    });

    test('should have valid Gemini AI configuration', () {
      final geminiApiKey = dotenv.get('GOOGLE_API_KEY', fallback: '');
      
      print('Gemini API Key: ${geminiApiKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
      
      expect(geminiApiKey, isNotEmpty, reason: 'GOOGLE_API_KEY should be configured');
      
      // Validate key format (Google API key)
      expect(geminiApiKey, startsWith('AIza'), reason: 'Google API key should start with AIza');
      expect(geminiApiKey.length, greaterThan(30), reason: 'Google API key should be a reasonable length');
    });

    test('should validate environment file exists', () {
      final envFile = File('.env');
      expect(envFile.existsSync(), isTrue, reason: '.env file should exist');
      
      final content = envFile.readAsStringSync();
      expect(content, contains('SUPABASE_URL'), reason: 'Should contain SUPABASE_URL');
      expect(content, contains('SUPABASE_ANON_KEY'), reason: 'Should contain SUPABASE_ANON_KEY');
      expect(content, contains('GOOGLE_API_KEY'), reason: 'Should contain GOOGLE_API_KEY');
    });

    test('should validate environment variables are not placeholders', () {
      final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
      final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
      final geminiApiKey = dotenv.get('GOOGLE_API_KEY', fallback: '');
      
      // Check for common placeholder patterns
      expect(supabaseUrl, isNot(contains('your-project-url')), reason: 'Supabase URL should not be a placeholder');
      expect(supabaseUrl, isNot(contains('placeholder')), reason: 'Supabase URL should not be a placeholder');
      
      expect(supabaseAnonKey, isNot(contains('your-anon-key')), reason: 'Supabase key should not be a placeholder');
      expect(supabaseAnonKey, isNot(contains('placeholder')), reason: 'Supabase key should not be a placeholder');
      
      expect(geminiApiKey, isNot(contains('your-api-key')), reason: 'Gemini API key should not be a placeholder');
      expect(geminiApiKey, isNot(contains('placeholder')), reason: 'Gemini API key should not be a placeholder');
    });
  });

  group('Security Configuration Tests', () {
    test('should not contain hardcoded credentials in source code', () async {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory should exist');
      
      // Search for hardcoded Supabase URLs
      final supabasePattern = RegExp(r'supabase\.co');
      final hardcodedKeyPattern = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'); // JWT pattern
      
      bool foundHardcodedCredentials = false;
      
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = await entity.readAsString();
          
          // Skip the config files which may contain legitimate references
          if (entity.path.contains('config') || entity.path.contains('test')) {
            continue;
          }
          
          if (supabasePattern.hasMatch(content) && !content.contains('dotenv')) {
            print('⚠️  Found potential hardcoded Supabase reference in: ${entity.path}');
            foundHardcodedCredentials = true;
          }
          
          if (hardcodedKeyPattern.hasMatch(content) && !content.contains('dotenv')) {
            print('⚠️  Found potential hardcoded API key in: ${entity.path}');
            foundHardcodedCredentials = true;
          }
        }
      }
      
      expect(foundHardcodedCredentials, isFalse, reason: 'Should not contain hardcoded credentials in source code');
    });
  });
}