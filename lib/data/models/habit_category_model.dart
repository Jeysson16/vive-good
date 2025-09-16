import 'package:vive_good_app/domain/entities/habit_category.dart';

class HabitCategoryModel extends HabitCategory {
  const HabitCategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
  });

  factory HabitCategoryModel.fromJson(Map<String, dynamic> json) {
    return HabitCategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}