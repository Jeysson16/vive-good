import 'package:equatable/equatable.dart';

class HabitProgress extends Equatable {
  final String id;
  final String userId;
  final String habitId;
  final DateTime date;
  final bool completed;
  final int? count;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? value;
  final String? unit;

  const HabitProgress({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    required this.completed,
    this.count,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.value,
    this.unit,
  });

  HabitProgress copyWith({
    String? id,
    String? userId,
    String? habitId,
    DateTime? date,
    bool? completed,
    int? count,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? value,
    String? unit,
  }) {
    return HabitProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        habitId,
        date,
        completed,
        count,
        notes,
        createdAt,
        updatedAt,
        value,
        unit,
      ];

  factory HabitProgress.fromMap(Map<String, dynamic> map) {
    return HabitProgress(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      habitId: map['habitId'] as String? ?? '',
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      completed: map['completed'] as bool? ?? false,
      count: map['count'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      value: map['value'] as double?,
      unit: map['unit'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'habitId': habitId,
      'date': date.toIso8601String().split('T')[0],
      'completed': completed,
      'count': count,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'value': value,
      'unit': unit,
    };
  }
}