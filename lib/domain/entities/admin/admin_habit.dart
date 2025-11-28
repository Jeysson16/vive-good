import 'package:equatable/equatable.dart';

class AdminHabit extends Equatable {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? iconName;
  final String? colorCode;
  final int userCount;
  final double averageCompletion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdminHabit({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.iconName,
    this.colorCode,
    required this.userCount,
    required this.averageCompletion,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        categoryId,
        categoryName,
        iconName,
        colorCode,
        userCount,
        averageCompletion,
        isActive,
        createdAt,
        updatedAt,
      ];

  AdminHabit copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    String? iconName,
    String? colorCode,
    int? userCount,
    double? averageCompletion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      userCount: userCount ?? this.userCount,
      averageCompletion: averageCompletion ?? this.averageCompletion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}