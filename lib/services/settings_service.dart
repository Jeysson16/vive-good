import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  static const String _themeKey = 'app_theme';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _alarmsKey = 'alarms_enabled';
  static const String _languageKey = 'app_language';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Theme Settings
  Future<bool> isDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }
  
  Future<void> setTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    
    // Sync with Supabase if user is logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_settings').upsert({
          'user_id': user.id,
          'theme': isDark ? 'dark' : 'light',
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
      }
    }
  }
  
  // Notification Settings
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }
  
  Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    
    // Sync with Supabase if user is logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_settings').upsert({
          'user_id': user.id,
          'notifications_enabled': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
      }
    }
  }
  
  // Alarm Settings
  Future<bool> areAlarmsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alarmsKey) ?? true;
  }
  
  Future<void> setAlarms(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmsKey, enabled);
    
    // Sync with Supabase if user is logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_settings').upsert({
          'user_id': user.id,
          'alarms_enabled': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
      }
    }
  }
  
  // Language Settings
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'es';
  }
  
  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Sync with Supabase if user is logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_settings').upsert({
          'user_id': user.id,
          'language': languageCode,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
      }
    }
  }
  
  // Load all settings from Supabase
  Future<void> loadSettingsFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        
        if (response['theme'] != null) {
          await prefs.setBool(_themeKey, response['theme'] == 'dark');
        }
        
        if (response['notifications_enabled'] != null) {
          await prefs.setBool(_notificationsKey, response['notifications_enabled']);
        }
        
        if (response['alarms_enabled'] != null) {
          await prefs.setBool(_alarmsKey, response['alarms_enabled']);
        }
        
        if (response['language'] != null) {
          await prefs.setString(_languageKey, response['language']);
        }
      }
    } catch (e) {
    }
  }
  
  // Save methods for compatibility
  Future<void> saveDarkTheme(bool isDark) async {
    await setTheme(isDark);
  }
  
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await setNotifications(enabled);
  }
  
  Future<void> saveAlarmsEnabled(bool enabled) async {
    await setAlarms(enabled);
  }
  
  Future<void> saveLanguage(String languageCode) async {
    await setLanguage(languageCode);
  }
  
  // Get all user settings as a map
  Future<Map<String, dynamic>?> getUserSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response != null) {
        return response;
      } else {
        // Return default settings if no settings found
        return {
          'user_id': user.id,
          'theme': 'light',
          'notifications_enabled': true,
          'alarms_enabled': true,
          'language': 'es',
        };
      }
    } catch (e) {
      return null;
    }
  }
  
  // Clear all local settings
  Future<void> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
    }
  }
  
  // Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      // Get user profile
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      // Get user habits
      final habitsResponse = await _supabase
          .from('user_habits')
          .select('*, habits(*)')
          .eq('user_id', user.id);
      
      // Get habit completions
      final completionsResponse = await _supabase
          .from('habit_completions')
          .select()
          .eq('user_id', user.id);
      
      // Get user settings
      final settingsResponse = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      return {
        'profile': profileResponse,
        'habits': habitsResponse,
        'completions': completionsResponse,
        'settings': settingsResponse,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }
}