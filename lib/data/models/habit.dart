import 'package:vive_good_app/domain/entities/habit.dart' as entities;

class HabitModel {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? iconName;
  final String? iconColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final String? createdBy;

  const HabitModel({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.iconName,
    this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublic,
    this.createdBy,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      iconName: json['icon_name'] as String?,
      iconColor: json['icon_color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPublic: json['is_public'] as bool,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'icon_name': iconName,
      'icon_color': iconColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_public': isPublic,
      'created_by': createdBy,
    };
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? iconName,
    String? iconColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? createdBy,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      iconName: iconName ?? this.iconName,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  entities.Habit toEntity() {
    return entities.Habit(
      id: id,
      name: name,
      description: description ?? '',
      categoryId: categoryId,
      iconName: iconName,
      iconColor: iconColor,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublic: isPublic,
      createdBy: createdBy,
    );
  }

  factory HabitModel.fromEntity(entities.Habit entity) {
    return HabitModel(
      id: entity.id,
      name: entity.name,
      description: entity.description.isEmpty ? null : entity.description,
      categoryId: entity.categoryId,
      iconName: entity.iconName,
      iconColor: entity.iconColor,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPublic: entity.isPublic,
      createdBy: entity.createdBy,
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.iconName == iconName &&
        other.iconColor == iconColor &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isPublic == isPublic &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      categoryId,
      iconName,
      iconColor,
      createdAt,
      updatedAt,
      isPublic,
      createdBy,
    );
  }

  @override
  String toString() {
    return 'HabitModel(id: $id, name: $name, description: $description, categoryId: $categoryId, iconName: $iconName, iconColor: $iconColor, createdAt: $createdAt, updatedAt: $updatedAt, isPublic: $isPublic, createdBy: $createdBy)';
  }
}