import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/habit_progress.dart';

part 'local_progress_model.g.dart';

@HiveType(typeId: 2)
class LocalProgressModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String habitId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final bool isLocalOnly;

  @HiveField(9)
  final bool needsSync;

  @HiveField(10)
  final DateTime? lastSyncAt;

  @HiveField(11)
  final double? value; // Para hábitos cuantificables

  @HiveField(12)
  final String? unit; // Unidad de medida

  LocalProgressModel({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    required this.completed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isLocalOnly = false,
    this.needsSync = false,
    this.lastSyncAt,
    this.value,
    this.unit,
  });

  // Convertir desde entidad de dominio
  factory LocalProgressModel.fromEntity(HabitProgress habitProgress) {
    return LocalProgressModel(
      id: habitProgress.id,
      userId: habitProgress.userId,
      habitId: habitProgress.habitId,
      date: habitProgress.date,
      completed: habitProgress.completed,
      notes: habitProgress.notes,
      createdAt: habitProgress.createdAt,
      updatedAt: habitProgress.updatedAt,
      value: habitProgress.value,
      unit: habitProgress.unit,
    );
  }

  HabitProgress toEntity() {
    return HabitProgress(
      id: id,
      userId: userId,
      habitId: habitId,
      date: date,
      completed: completed,
      count: null, // LocalProgressModel doesn't have count field
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      value: value,
      unit: unit,
    );
  }

  // Marcar como que necesita sincronización
  LocalProgressModel markAsNeedsSync() {
    return LocalProgressModel(
      id: id,
      userId: userId,
      habitId: habitId,
      date: date,
      completed: completed,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isLocalOnly: isLocalOnly,
      needsSync: true,
      lastSyncAt: lastSyncAt,
      value: value,
      unit: unit,
    );
  }

  // Marcar como sincronizado
  LocalProgressModel markAsSynced() {
    return LocalProgressModel(
      id: id,
      userId: userId,
      habitId: habitId,
      date: date,
      completed: completed,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocalOnly: false,
      needsSync: false,
      lastSyncAt: DateTime.now(),
      value: value,
      unit: unit,
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'value': value,
      'unit': unit,
    };
  }
}