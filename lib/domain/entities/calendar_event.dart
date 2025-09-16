import 'package:equatable/equatable.dart';

class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String eventType;
  final DateTime startDate;
  final DateTime? startTime;
  final DateTime? endDate;
  final DateTime? endTime;
  final String userId;
  final String? habitId;
  final bool isCompleted;
  final DateTime? completedAt;
  final String recurrenceType;
  final DateTime? recurrenceEndDate;
  final List<int>? recurrenceDays;
  final bool notificationEnabled;
  final int? notificationMinutes;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    required this.userId,
    this.habitId,
    this.isCompleted = false,
    this.completedAt,
    this.recurrenceType = 'none',
    this.recurrenceEndDate,
    this.recurrenceDays,
    this.notificationEnabled = false,
    this.notificationMinutes,
    this.location,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRecurring => recurrenceType != 'none';
  
  // Getter para compatibilidad con table_calendar
  DateTime get date => startDate;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        eventType,
        startDate,
        startTime,
        endDate,
        endTime,
        userId,
        habitId,
        isCompleted,
        completedAt,
        recurrenceType,
        recurrenceEndDate,
        recurrenceDays,
        notificationEnabled,
        notificationMinutes,
        location,
        notes,
        createdAt,
        updatedAt,
      ];

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    DateTime? startDate,
    DateTime? startTime,
    DateTime? endDate,
    DateTime? endTime,
    String? userId,
    String? habitId,
    bool? isCompleted,
    DateTime? completedAt,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
    List<int>? recurrenceDays,
    bool? notificationEnabled,
    int? notificationMinutes,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'start_date': startDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_date': endDate?.toIso8601String().split('T')[0],
      'end_time': endTime,
      'user_id': userId,
      'habit_id': habitId,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'recurrence_type': recurrenceType,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String().split('T')[0],
      'recurrence_days': recurrenceDays,
      'notification_enabled': notificationEnabled,
      'notification_minutes': notificationMinutes,
      'location': location,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      eventType: json['event_type'] ?? 'activity',
      startDate: DateTime.parse(json['start_date']),
      startTime: json['start_time'],
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      endTime: json['end_time'],
      userId: json['user_id'],
      habitId: json['habit_id'],
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      recurrenceType: json['recurrence_type'] ?? 'none',
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTime.parse(json['recurrence_end_date'])
          : null,
      recurrenceDays: json['recurrence_days'] != null
          ? List<int>.from(json['recurrence_days'])
          : null,
      notificationEnabled: json['notification_enabled'] ?? false,
      notificationMinutes: json['notification_minutes'],
      location: json['location'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}