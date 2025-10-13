import '../../domain/entities/calendar_event.dart';

class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.userId,
    super.habitId,
    required super.title,
    required super.description,
    required super.eventType,
    required super.startDate,
    super.endDate,
    super.startTime,
    super.endTime,
    super.recurrenceType = 'none',
    super.recurrenceEndDate,
    super.recurrenceDays,
    super.notificationEnabled = false,
    super.notificationMinutes,
    super.isCompleted = false,
    super.completedAt,
    super.location,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitId: json['habit_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'event',
      startDate: _parseDate(json['start_date'] as String),
      endDate: json['end_date'] != null 
          ? _parseDate(json['end_date'] as String) 
          : null,
      startTime: json['start_time'] != null 
          ? _parseTime(json['start_time'] as String) 
          : null,
      endTime: json['end_time'] != null 
          ? _parseTime(json['end_time'] as String) 
          : null,
      recurrenceType: json['recurrence_type'] as String? ?? 'none',
      recurrenceEndDate: json['recurrence_end_date'] != null 
          ? _parseDate(json['recurrence_end_date'] as String) 
          : null,
      recurrenceDays: json['recurrence_days'] != null 
          ? List<int>.from(json['recurrence_days'] as List) 
          : null,
      notificationEnabled: json['notification_enabled'] as bool? ?? false,
      notificationMinutes: json['notification_minutes'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Helper method to parse date strings that might be in different formats
  static DateTime _parseDate(String dateString) {
    try {
      // Try parsing as ISO format first
      return DateTime.parse(dateString);
    } catch (e) {
      // If that fails, try parsing as date-only format (YYYY-MM-DD)
      if (dateString.length == 10 && dateString.contains('-')) {
        return DateTime.parse('${dateString}T00:00:00.000Z');
      }
      // If all else fails, rethrow the original exception
      rethrow;
    }
  }

  /// Helper method to parse datetime strings with better error handling
  static DateTime _parseDateTime(String dateTimeString) {
    try {
      print('DEBUG: Parsing datetime: $dateTimeString');
      return DateTime.parse(dateTimeString);
    } catch (e) {
      print('ERROR: Failed to parse datetime "$dateTimeString": $e');
      // Try to extract just the date part if it's a malformed datetime
      if (dateTimeString.contains('T')) {
        final datePart = dateTimeString.split('T')[0];
        print('DEBUG: Trying to parse date part: $datePart');
        return DateTime.parse('${datePart}T00:00:00.000Z');
      }
      // If all else fails, rethrow the original exception
      rethrow;
    }
  }

  /// Helper method to parse time strings (HH:MM:SS) and convert to DateTime
  static DateTime? _parseTime(String timeString) {
    try {
      print('DEBUG: Parsing time: $timeString');
      // If it's just a time string (HH:MM:SS), convert it to a DateTime for today
      if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(timeString)) {
        final now = DateTime.now();
        final timeParts = timeString.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = int.parse(timeParts[2]);
        return DateTime(now.year, now.month, now.day, hour, minute, second);
      }
      // If it's already a full datetime string, parse it normally
      return DateTime.parse(timeString);
    } catch (e) {
      print('ERROR: Failed to parse time "$timeString": $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'title': title,
      'description': description,
      'event_type': eventType,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'recurrence_type': recurrenceType,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String().split('T')[0],
      'recurrence_days': recurrenceDays,
      'notification_enabled': notificationEnabled,
      'notification_minutes': notificationMinutes,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'location': location,
      'notes': notes,
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

  factory CalendarEventModel.fromEntity(CalendarEvent entity) {
    return CalendarEventModel(
      id: entity.id,
      userId: entity.userId,
      habitId: entity.habitId,
      title: entity.title,
      description: entity.description,
      eventType: entity.eventType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      recurrenceType: entity.recurrenceType,
      recurrenceEndDate: entity.recurrenceEndDate,
      recurrenceDays: entity.recurrenceDays,
      notificationEnabled: entity.notificationEnabled,
      notificationMinutes: entity.notificationMinutes,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      location: entity.location,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CalendarEventModel copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? title,
    String? description,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startTime,
    DateTime? endTime,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
    List<int>? recurrenceDays,
    bool? notificationEnabled,
    int? notificationMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}