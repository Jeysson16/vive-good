class Category {
  final String id;
  final String name;
  final String? description;
  final String iconName;
  final String color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}