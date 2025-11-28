import 'package:equatable/equatable.dart';

class AdminCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? iconName;
  final String? colorCode;
  final int habitCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdminCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    this.colorCode,
    required this.habitCount,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconName,
        colorCode,
        habitCount,
        isActive,
        createdAt,
        updatedAt,
      ];

  AdminCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
    int? habitCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      habitCount: habitCount ?? this.habitCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}