import 'package:equatable/equatable.dart';

class HabitCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String color;

  const HabitCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  List<Object> get props => [id, name, icon, color];
}