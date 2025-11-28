import '../../domain/entities/habit_schedule.dart';

class HabitScheduleModel extends HabitSchedule {
  const HabitScheduleModel({
    required super.id,
    required super.userId,
    required super.habitId,
    required super.scheduledTime,
    super.scheduledDate,
    super.recurrenceType = 'none',
    super.recurrenceDays,
    super.isActive = true,
    super.notificationEnabled = false,
    super.notificationMinutes,
    super.isCompleted = false,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HabitScheduleModel.fromJson(Map<String, dynamic> json) {
    return HabitScheduleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitId: json['habit_id'] as String,
      scheduledTime: json['scheduled_time'] as String,
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date'] as String) 
          : null,
      recurrenceType: json['recurrence_type'] as String? ?? 'none',
      recurrenceDays: json['recurrence_days'] != null 
          ? List<int>.from(json['recurrence_days'] as List) 
          : null,
      isActive: json['is_active'] as bool? ?? true,
      notificationEnabled: json['notification_enabled'] as bool? ?? false,
      notificationMinutes: json['notification_minutes'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': (userId.isNotEmpty) ? userId : null,
      'habit_id': (habitId.isNotEmpty) ? habitId : null,
      'scheduled_time': scheduledTime,
      'scheduled_date': scheduledDate?.toIso8601String().split('T')[0],
      'recurrence_type': recurrenceType,
      'recurrence_days': recurrenceDays,
      'is_active': isActive,
      'notification_enabled': notificationEnabled,
      'notification_minutes': notificationMinutes,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    final json = toJson();
    json.remove('id'); // Remove ID for insert operations
    json.remove('created_at'); // Let database handle created_at
    json.remove('updated_at'); // Let database handle updated_at
    return json;
  }

  Map<String, dynamic> toJsonForUpdate() {
    final json = toJson();
    json.remove('id'); // Remove ID for update operations
    json.remove('created_at'); // Don't update created_at
    json.remove('updated_at'); // Let database handle updated_at
    return json;
  }

  factory HabitScheduleModel.fromEntity(HabitSchedule entity) {
    return HabitScheduleModel(
      id: entity.id,
      userId: entity.userId,
      habitId: entity.habitId,
      scheduledTime: entity.scheduledTime,
      scheduledDate: entity.scheduledDate,
      recurrenceType: entity.recurrenceType,
      recurrenceDays: entity.recurrenceDays,
      isActive: entity.isActive,
      notificationEnabled: entity.notificationEnabled,
      notificationMinutes: entity.notificationMinutes,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  HabitScheduleModel copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? scheduledTime,
    DateTime? scheduledDate,
    String? recurrenceType,
    List<int>? recurrenceDays,
    bool? isActive,
    bool? notificationEnabled,
    int? notificationMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      isActive: isActive ?? this.isActive,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}