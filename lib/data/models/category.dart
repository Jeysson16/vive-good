class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String? iconColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.iconColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      iconColor: json['icon_color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'icon_color': iconColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? iconColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.iconName == iconName &&
        other.iconColor == iconColor &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      iconName,
      iconColor,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, description: $description, iconName: $iconName, iconColor: $iconColor, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}