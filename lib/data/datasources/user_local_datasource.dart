import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class UserLocalDataSource {
  Future<UserModel?> getCurrentUser();
  Future<void> saveUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser();
  Future<bool> isFirstTimeUser();
  Future<void> setFirstTimeUser(bool isFirstTime);
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted(bool completed);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const String _userBoxName = 'user_box';
  static const String _userKey = 'current_user';
  static const String _firstTimeKey = 'is_first_time';
  static const String _onboardingKey = 'onboarding_completed';

  Box<UserModel>? _userBox;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  UserLocalDataSourceImpl();

  Future<void> _initializeBoxes() async {
    if (_isInitialized) return;
    
    // Verificar si la caja ya está abierta
    if (Hive.isBoxOpen(_userBoxName)) {
      _userBox = Hive.box<UserModel>(_userBoxName);
    } else {
      _userBox = await Hive.openBox<UserModel>(_userBoxName);
    }
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await _initializeBoxes();
    return _userBox!.get(_userKey);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _initializeBoxes();
    await _userBox!.put(_userKey, user);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _initializeBoxes();
    await _userBox!.put(_userKey, user);
  }

  @override
  Future<void> deleteUser() async {
    await _initializeBoxes();
    await _userBox!.delete(_userKey);
  }

  @override
  Future<bool> isFirstTimeUser() async {
    await _initializeBoxes();
    return _prefs!.getBool(_firstTimeKey) ?? true;
  }

  @override
  Future<void> setFirstTimeUser(bool isFirstTime) async {
    await _initializeBoxes();
    await _prefs!.setBool(_firstTimeKey, isFirstTime);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    await _initializeBoxes();
    return _prefs!.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _initializeBoxes();
    await _prefs!.setBool(_onboardingKey, completed);
  }
}