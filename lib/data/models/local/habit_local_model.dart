import '../../../domain/entities/habit.dart';

class HabitLocalModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? category;
  final String? color;
  final String? icon;
  final String frequency;
  final int targetCount;
  final String? reminderTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? lastSyncAt;

  const HabitLocalModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.category,
    this.color,
    this.icon,
    required this.frequency,
    this.targetCount = 1,
    this.reminderTime,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.lastSyncAt,
  });

  // Conversión desde Map (SQLite)
  factory HabitLocalModel.fromMap(Map<String, dynamic> map) {
    return HabitLocalModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      frequency: map['frequency'] as String,
      targetCount: map['target_count'] as int? ?? 1,
      reminderTime: map['reminder_time'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
    );
  }

  // Conversión a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'category': category,
      'color': color,
      'icon': icon,
      'frequency': frequency,
      'target_count': targetCount,
      'reminder_time': reminderTime,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  // Conversión desde entidad de dominio
  factory HabitLocalModel.fromEntity(Habit habit, {bool isSynced = false}) {
    return HabitLocalModel(
      id: habit.id,
      userId: habit.userId ?? '',
      name: habit.name,
      description: habit.description,
      category: habit.categoryId ?? '',
      color: habit.iconColor ?? '',
      icon: habit.iconName ?? '',
      frequency: 'daily', // Valor por defecto
      targetCount: 1, // Valor por defecto
      reminderTime: null, // No disponible en la entidad actual
      isActive: true, // Valor por defecto
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      isSynced: isSynced,
    );
  }

  // Conversión a entidad de dominio
  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      description: description ?? '',
      categoryId: category?.isNotEmpty == true ? category : null,
      iconName: icon?.isNotEmpty == true ? icon : null,
      iconColor: color?.isNotEmpty == true ? color : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublic: false,
      createdBy: null,
      userId: userId.isNotEmpty ? userId : null,
    );
  }

  // Crear copia con cambios
  HabitLocalModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? category,
    String? color,
    String? icon,
    String? frequency,
    int? targetCount,
    String? reminderTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAt,
  }) {
    return HabitLocalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return 'HabitLocalModel(id: $id, name: $name, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is HabitLocalModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.description == description &&
        other.category == category &&
        other.color == color &&
        other.icon == icon &&
        other.frequency == frequency &&
        other.targetCount == targetCount &&
        other.reminderTime == reminderTime &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSynced == isSynced &&
        other.lastSyncAt == lastSyncAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      description,
      category,
      color,
      icon,
      frequency,
      targetCount,
      reminderTime,
      isActive,
      createdAt,
      updatedAt,
      isSynced,
      lastSyncAt,
    );
  }
}