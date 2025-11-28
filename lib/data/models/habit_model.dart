import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.name,
    required super.description,
    super.categoryId,
    super.iconName,
    super.iconColor,
    required super.createdAt,
    required super.updatedAt,
    super.isPublic = true,
    super.createdBy,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      // Mapear iconName desde category_icon si está disponible, sino usar icon_name
      iconName: json['category_icon'] as String? ?? json['icon_name'] as String? ?? 'default',
      // Mapear iconColor desde category_color si está disponible, sino usar icon_color
      iconColor: json['category_color'] as String? ?? json['icon_color'] as String? ?? '#219540',
      // Para campos de fecha, usar valores por defecto si no están disponibles (caso del SP)
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isPublic: json['is_public'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': (categoryId?.isNotEmpty == true) ? categoryId : null,
      'icon_name': iconName,
      'icon_color': iconColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_public': isPublic,
      'created_by': (createdBy?.isNotEmpty == true) ? createdBy : null,
    };
  }

  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      categoryId: habit.categoryId,
      iconName: habit.iconName,
      iconColor: habit.iconColor,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      isPublic: habit.isPublic,
      createdBy: habit.createdBy,
    );
  }

  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      iconName: iconName,
      iconColor: iconColor,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPublic: isPublic,
      createdBy: createdBy,
    );
  }
}
