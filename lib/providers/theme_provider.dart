import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  
  bool _isDarkMode = false;
  bool _isLoading = true;
  
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  ThemeData get themeData => _isDarkMode ? ThemeService.darkTheme : ThemeService.lightTheme;
  
  ThemeProvider() {
    _initializeTheme();
  }
  
  Future<void> _initializeTheme() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _isDarkMode = await _themeService.initializeTheme();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      notifyListeners();
      
      await _themeService.toggleTheme(_isDarkMode);
    } catch (e) {
      // Revertir el cambio si hay error
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }
  
  Future<void> setTheme(bool isDarkMode) async {
    try {
      if (_isDarkMode != isDarkMode) {
        _isDarkMode = isDarkMode;
        notifyListeners();
        
        await _themeService.toggleTheme(_isDarkMode);
      }
    } catch (e) {
    }
  }
  
  // Método para refrescar el tema desde Supabase
  Future<void> refreshTheme() async {
    try {
      final supabaseTheme = await _themeService.loadThemeFromSupabase();
      if (supabaseTheme != null && supabaseTheme != _isDarkMode) {
        _isDarkMode = supabaseTheme;
        await _themeService.saveThemeMode(_isDarkMode);
        notifyListeners();
      }
    } catch (e) {
    }
  }
}