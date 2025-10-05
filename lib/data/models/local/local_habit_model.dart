import 'package:hive/hive.dart';
import 'package:vive_good_app/domain/entities/habit.dart';

part 'local_habit_model.g.dart';

@HiveType(typeId: 1)
class LocalHabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? categoryId;

  @HiveField(4)
  final String? iconName;

  @HiveField(5)
  final String? color;

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
  final bool isActive;

  @HiveField(12)
  final int? targetFrequency;

  @HiveField(13)
  final String? frequencyType; // 'daily', 'weekly', 'monthly'

  LocalHabitModel({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.iconName,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isLocalOnly = false,
    this.needsSync = false,
    this.lastSyncAt,
    this.isActive = true,
    this.targetFrequency,
    this.frequencyType,
  });

  // Convertir desde entidad de dominio
  factory LocalHabitModel.fromEntity(Habit habit) {
    return LocalHabitModel(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      categoryId: habit.categoryId,
      iconName: habit.iconName,
      color: habit.iconColor, // Mapear iconColor a color
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      // Propiedades específicas del modelo local con valores por defecto
      isActive: true,
      targetFrequency: null,
      frequencyType: null,
    );
  }

  // Convertir a entidad de dominio
  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      description: description ?? '',
      categoryId: categoryId,
      iconName: iconName,
      iconColor: color, // Mapear color a iconColor
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublic: false, // Valor por defecto
      createdBy: null,
      userId: null,
    );
  }

  // Marcar como que necesita sincronización
  LocalHabitModel markAsNeedsSync() {
    return LocalHabitModel(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      iconName: iconName,
      color: color,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isLocalOnly: isLocalOnly,
      needsSync: true,
      lastSyncAt: lastSyncAt,
      isActive: isActive,
      targetFrequency: targetFrequency,
      frequencyType: frequencyType,
    );
  }

  // Marcar como sincronizado
  LocalHabitModel markAsSynced() {
    return LocalHabitModel(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      iconName: iconName,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocalOnly: false,
      needsSync: false,
      lastSyncAt: DateTime.now(),
      isActive: isActive,
      targetFrequency: targetFrequency,
      frequencyType: frequencyType,
    );
  }

  // Convertir a Map para sincronización
  Map<String, dynamic> toSyncMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'icon_name': iconName,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'target_frequency': targetFrequency,
      'frequency_type': frequencyType,
    };
  }
}