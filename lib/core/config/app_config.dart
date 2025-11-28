import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  static String get supabaseUrl {
    return dotenv.get('SUPABASE_URL', fallback: '');
  }

  static String get supabaseAnonKey {
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  }

  static String get geminiApiKey {
    return dotenv.get('GOOGLE_API_KEY', fallback: '');
  }

  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static bool get isGeminiConfigured {
    return geminiApiKey.isNotEmpty;
  }

  static Map<String, String> get allConfig {
    return {
      'SUPABASE_URL': supabaseUrl,
      'SUPABASE_ANON_KEY': supabaseAnonKey,
      'GOOGLE_API_KEY': geminiApiKey,
    };
  }
}
