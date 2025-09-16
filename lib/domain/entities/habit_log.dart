class HabitLog {
  final String id;
  final String userHabitId;
  final DateTime completedAt;
  final String? notes;
  final DateTime createdAt;

  const HabitLog({
    required this.id,
    required this.userHabitId,
    required this.completedAt,
    this.notes,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}