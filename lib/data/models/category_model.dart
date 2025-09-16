import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    required super.iconName,
    required super.color,
    super.createdAt,
    super.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      description: json['description'] as String?,
      iconName: json['icon'] as String? ?? 'help_circle',
      color: json['color'] as String? ?? '#6B7280',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': iconName,
      'color': color,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      iconName: category.iconName,
      color: category.color,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}