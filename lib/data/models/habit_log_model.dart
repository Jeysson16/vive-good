import '../../domain/entities/habit_log.dart';

class HabitLogModel extends HabitLog {
  const HabitLogModel({
    required super.id,
    required super.userHabitId,
    required super.completedAt,
    super.notes,
    required super.createdAt,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['id'] as String,
      userHabitId: json['user_habit_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_habit_id': (userHabitId.isNotEmpty) ? userHabitId : null,
      'completed_at': completedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitLogModel.fromEntity(HabitLog habitLog) {
    return HabitLogModel(
      id: habitLog.id,
      userHabitId: habitLog.userHabitId,
      completedAt: habitLog.completedAt,
      notes: habitLog.notes,
      createdAt: habitLog.createdAt,
    );
  }

  HabitLog toEntity() {
    return HabitLog(
      id: id,
      userHabitId: userHabitId,
      completedAt: completedAt,
      notes: notes,
      createdAt: createdAt,
    );
  }
}