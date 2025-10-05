import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static const String _isDarkModeKey = 'is_dark_mode';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Obtener el tema actual desde SharedPreferences
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
      return isDarkMode ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      return ThemeMode.light;
    }
  }
  
  // Obtener si está en modo oscuro
  Future<bool> isDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isDarkModeKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Guardar el tema localmente
  Future<void> saveThemeMode(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, isDarkMode);
    } catch (e) {
    }
  }
  
  // Sincronizar tema con Supabase
  Future<void> syncThemeWithSupabase(bool isDarkMode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from('user_settings')
            .upsert({
              'user_id': user.id,
              'theme': isDarkMode ? 'dark' : 'light',
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
    }
  }
  
  // Cargar tema desde Supabase
  Future<bool?> loadThemeFromSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('user_settings')
            .select('theme')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (response != null && response['theme'] != null) {
          return response['theme'] == 'dark';
        }
      }
    } catch (e) {
    }
    return null;
  }
  
  // Cambiar tema (guardar local y sincronizar con Supabase)
  Future<void> toggleTheme(bool isDarkMode) async {
    await saveThemeMode(isDarkMode);
    await syncThemeWithSupabase(isDarkMode);
  }
  
  // Inicializar tema (cargar desde Supabase si existe, sino usar local)
  Future<bool> initializeTheme() async {
    try {
      // Primero intentar cargar desde Supabase
      final supabaseTheme = await loadThemeFromSupabase();
      
      if (supabaseTheme != null) {
        // Si existe en Supabase, guardar localmente y usar ese
        await saveThemeMode(supabaseTheme);
        return supabaseTheme;
      } else {
        // Si no existe en Supabase, usar el local
        return await isDarkMode();
      }
    } catch (e) {
      return false;
    }
  }
  
  // Definir temas de la aplicación
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF4CAF50),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF090D3A)),
        bodyMedium: TextStyle(color: Color(0xFF090D3A)),
        titleLarge: TextStyle(color: Color(0xFF090D3A)),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF090D3A),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF4CAF50),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    );
  }
}