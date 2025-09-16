import 'package:hive_flutter/hive_flutter.dart';
import 'package:vive_good_app/data/models/habit_model.dart';
import 'package:vive_good_app/data/models/category_model.dart';
import 'package:vive_good_app/data/models/user_habit_model.dart';

abstract class HabitLocalDataSource {
  Future<List<UserHabitModel>> getUserHabits();
  Future<List<CategoryModel>> getHabitCategories();
  Future<void> addHabit(HabitModel habit);
  Future<void> deleteHabit(String habitId);
  Future<void> logHabitCompletion(String habitId, DateTime date);
  Future<List<HabitModel>> getDashboardHabits();
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final HiveInterface hive;

  HabitLocalDataSourceImpl({required this.hive});

  @override
  Future<List<UserHabitModel>> getUserHabits() async {
    // Implementar lógica para obtener UserHabitModel de forma local si es necesario
    // Por ahora, se puede devolver una lista vacía o predefinida
    return [];
  }

  @override
  Future<List<CategoryModel>> getHabitCategories() async {
    // Implementar lógica para obtener categorías de forma local si es necesario
    // Por ahora, se puede devolver una lista vacía o predefinida
    return [];
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    final box = await hive.openBox<HabitModel>('habits');
    await box.put(habit.id, habit);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final box = await hive.openBox<HabitModel>('habits');
    await box.delete(habitId);
  }

  @override
  Future<void> logHabitCompletion(String habitId, DateTime date) async {
    // Implementar lógica para registrar la finalización del hábito localmente
    // Esto podría implicar una caja separada para registros de finalización
    print('Logging habit completion locally for habit $habitId on $date');
  }

  @override
  Future<List<HabitModel>> getDashboardHabits() async {
    final box = await hive.openBox<HabitModel>('habits');
    return box.values.toList();
  }
}
