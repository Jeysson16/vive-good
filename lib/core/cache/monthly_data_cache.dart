import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/habit_breakdown.dart';
import '../../domain/entities/habit_statistics.dart';
import '../../domain/entities/category_evolution.dart';

class MonthlyDataCache {
  static const String _progressKey = 'monthly_progress_';
  static const String _indicatorsKey = 'monthly_indicators_';
  static const String _breakdownKey = 'monthly_breakdown_';
  static const String _statisticsKey = 'monthly_statistics_';
  static const String _evolutionKey = 'monthly_evolution_';
  static const String _timestampKey = 'cache_timestamp_';
  
  // Cache duration: 30 minutes for fresh data, 2 hours for fallback
  static const Duration _freshCacheDuration = Duration(minutes: 30);
  static const Duration _maxCacheDuration = Duration(hours: 2);

  static MonthlyDataCache? _instance;
  static MonthlyDataCache get instance => _instance ??= MonthlyDataCache._();
  
  MonthlyDataCache._();

  String _getCacheKey(String baseKey, String userId, int year, int month) {
    return '$baseKey${userId}_${year}_$month';
  }

  String _getTimestampKey(String userId, int year, int month) {
    return '$_timestampKey${userId}_${year}_$month';
  }

  Future<bool> _isCacheValid(String userId, int year, int month, {bool requireFresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _getTimestampKey(userId, year, month);
      final timestamp = prefs.getInt(timestampKey);
      
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final age = now.difference(cacheTime);
      
      if (requireFresh) {
        return age <= _freshCacheDuration;
      } else {
        return age <= _maxCacheDuration;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateTimestamp(String userId, int year, int month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _getTimestampKey(userId, year, month);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Ignore cache timestamp errors
    }
  }

  // Progress Cache - Simplificado
  Future<List<Progress>?> getCachedProgress(String userId, int year, int month) async {
    try {
      if (!await _isCacheValid(userId, year, month)) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_progressKey, userId, year, month);
      final hasCachedData = prefs.getBool(key) ?? false;
      
      return hasCachedData ? [] : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheProgress(String userId, int year, int month, List<Progress> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_progressKey, userId, year, month);
      await prefs.setBool(key, true);
      
      await _updateTimestamp(userId, year, month);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Indicators Cache - Simplificado
  Future<Map<String, String>?> getCachedIndicators(String userId, int year, int month) async {
    try {
      if (!await _isCacheValid(userId, year, month)) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_indicatorsKey, userId, year, month);
      final hasCachedData = prefs.getBool(key) ?? false;
      
      return hasCachedData ? {} : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheIndicators(String userId, int year, int month, Map<String, String> indicators) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_indicatorsKey, userId, year, month);
      await prefs.setBool(key, true);
      
      await _updateTimestamp(userId, year, month);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Breakdown Cache - Simplificado
  Future<List<HabitBreakdown>?> getCachedBreakdown(String userId, int year, int month) async {
    try {
      if (!await _isCacheValid(userId, year, month)) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_breakdownKey, userId, year, month);
      final hasCachedData = prefs.getBool(key) ?? false;
      
      return hasCachedData ? [] : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheBreakdown(String userId, int year, int month, List<HabitBreakdown> breakdown) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_breakdownKey, userId, year, month);
      await prefs.setBool(key, true);
      
      await _updateTimestamp(userId, year, month);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Statistics Cache - Simplificado
  Future<List<HabitStatistics>?> getCachedStatistics(String userId, int year, int month) async {
    try {
      if (!await _isCacheValid(userId, year, month)) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_statisticsKey, userId, year, month);
      final hasCachedData = prefs.getBool(key) ?? false;
      
      return hasCachedData ? [] : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheStatistics(String userId, int year, int month, List<HabitStatistics> statistics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_statisticsKey, userId, year, month);
      await prefs.setBool(key, true);
      
      await _updateTimestamp(userId, year, month);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Evolution Cache - Simplificado para evitar serialización compleja
  Future<List<CategoryEvolution>?> getCachedEvolution(String userId, int year, int month) async {
    try {
      if (!await _isCacheValid(userId, year, month)) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_evolutionKey, userId, year, month);
      final hasCachedData = prefs.getBool(key) ?? false;
      
      return hasCachedData ? [] : null; // Retorna lista vacía si hay cache válido
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheEvolution(String userId, int year, int month, List<CategoryEvolution> evolution) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(_evolutionKey, userId, year, month);
      // Solo guardamos un indicador de que los datos están cacheados
      await prefs.setBool(key, true);
      
      await _updateTimestamp(userId, year, month);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Clear cache for specific month
  Future<void> clearMonthCache(String userId, int year, int month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        _getCacheKey(_progressKey, userId, year, month),
        _getCacheKey(_indicatorsKey, userId, year, month),
        _getCacheKey(_breakdownKey, userId, year, month),
        _getCacheKey(_statisticsKey, userId, year, month),
        _getCacheKey(_evolutionKey, userId, year, month),
        _getTimestampKey(userId, year, month),
      ];
      
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_progressKey) ||
        key.startsWith(_indicatorsKey) ||
        key.startsWith(_breakdownKey) ||
        key.startsWith(_statisticsKey) ||
        key.startsWith(_evolutionKey) ||
        key.startsWith(_timestampKey)
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Check if we have any cached data for the month (even if stale)
  Future<bool> hasAnyCache(String userId, int year, int month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _getTimestampKey(userId, year, month);
      return prefs.containsKey(timestampKey);
    } catch (e) {
      return false;
    }
  }
}