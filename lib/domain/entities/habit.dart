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
  final String? userId;

  const Habit({
    required this.id,
    required this.name,
    required this.description,
    this.categoryId,
    this.iconName,
    this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.createdBy,
    this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }

  @override
  int get hashCode => Object.hash(
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
    userId,
  );

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId'] as String?,
      iconName: map['iconName'] as String?,
      iconColor: map['iconColor'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      isPublic: map['isPublic'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'iconName': iconName,
      'iconColor': iconColor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublic': isPublic,
      'createdBy': createdBy,
      'userId': userId,
    };
  }
}
