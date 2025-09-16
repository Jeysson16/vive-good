class Habit {
  final String id;
  final String name;
  final String description;
  final String? categoryId;
  final String? iconName;
  final String? iconColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final String? createdBy;

  const Habit({
    required this.id,
    required this.name,
    required this.description,
    this.categoryId,
    this.iconName,
    this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = true,
    this.createdBy,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
