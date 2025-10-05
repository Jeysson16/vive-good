import '../../../domain/entities/habit_progress.dart';

class ProgressLocalModel {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final int count;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final DateTime? lastSyncAt;

  const ProgressLocalModel({
    required this.id,
    required this.habitId,
    required this.date,
    this.completed = false,
    this.count = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.lastSyncAt,
  });

  // Conversión desde Map (SQLite)
  factory ProgressLocalModel.fromMap(Map<String, dynamic> map) {
    return ProgressLocalModel(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
      count: map['count'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
      lastSyncAt: map['last_sync_at'] != null 
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
    );
  }

  // Conversión a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0], // Solo la fecha
      'completed': completed ? 1 : 0,
      'count': count,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  // Conversión desde entidad de dominio
  factory ProgressLocalModel.fromEntity(HabitProgress progress, {bool isSynced = false}) {
    return ProgressLocalModel(
      id: progress.id,
      habitId: progress.habitId,
      date: progress.date,
      completed: progress.completed,
      count: progress.count ?? 0,
      notes: progress.notes,
      createdAt: progress.createdAt,
      updatedAt: progress.updatedAt,
      isSynced: isSynced,
    );
  }

  // Conversión a entidad de dominio
  HabitProgress toEntity() {
    return HabitProgress(
      id: id,
      userId: '', // Se debe proporcionar desde el contexto
      habitId: habitId,
      date: date,
      completed: completed,
      count: count,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Crear copia con cambios
  ProgressLocalModel copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
    int? count,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAt,
  }) {
    return ProgressLocalModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return 'ProgressLocalModel(id: $id, habitId: $habitId, date: $date, completed: $completed, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProgressLocalModel &&
        other.id == id &&
        other.habitId == habitId &&
        other.date == date &&
        other.completed == completed &&
        other.count == count &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSynced == isSynced &&
        other.lastSyncAt == lastSyncAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      habitId,
      date,
      completed,
      count,
      notes,
      createdAt,
      updatedAt,
      isSynced,
      lastSyncAt,
    );
  }
}