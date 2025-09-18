import 'package:equatable/equatable.dart';

/// Modelo de datos para el perfil completo del usuario
/// Corresponde con la tabla 'profiles' extendida en Supabase
class UserProfile extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Datos personales adicionales
  final int? age;
  final String? institution;
  final String? profileImageUrl;
  final String? phone;

  // Datos de salud
  final double? heightCm;
  final double? weightKg;
  final List<String> riskFactors;

  // Hábitos activos con progreso
  final int hydrationProgress;
  final int hydrationGoal;
  final int sleepProgress;
  final int sleepGoal;
  final int activityProgress;
  final int activityGoal;

  // Configuraciones inteligentes
  final bool autoSuggestionsEnabled;
  final String morningReminderTime; // Formato HH:mm:ss
  final String eveningReminderTime; // Formato HH:mm:ss
  final bool dailyRemindersEnabled;

  // Metadatos
  final bool isProfileComplete;
  final DateTime? lastProfileUpdate;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.createdAt,
    this.updatedAt,
    this.age,
    this.institution = 'UCV',
    this.profileImageUrl,
    this.phone,
    this.heightCm,
    this.weightKg,
    this.riskFactors = const [],
    this.hydrationProgress = 0,
    this.hydrationGoal = 5,
    this.sleepProgress = 0,
    this.sleepGoal = 5,
    this.activityProgress = 0,
    this.activityGoal = 5,
    this.autoSuggestionsEnabled = true,
    this.morningReminderTime = '08:00:00',
    this.eveningReminderTime = '21:30:00',
    this.dailyRemindersEnabled = true,
    this.isProfileComplete = false,
    this.lastProfileUpdate,
  });

  /// Crea una instancia desde un Map (típicamente desde Supabase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      age: json['age'] as int?,
      institution: json['institution'] as String? ?? 'UCV',
      profileImageUrl: json['profile_image_url'] as String?,
      phone: json['phone'] as String?,
      heightCm: json['height_cm'] != null
          ? double.parse(json['height_cm'].toString())
          : null,
      weightKg: json['weight_kg'] != null
          ? double.parse(json['weight_kg'].toString())
          : null,
      riskFactors: json['risk_factors'] != null
          ? List<String>.from(json['risk_factors'] as List)
          : [],
      hydrationProgress: json['hydration_progress'] as int? ?? 0,
      hydrationGoal: json['hydration_goal'] as int? ?? 5,
      sleepProgress: json['sleep_progress'] as int? ?? 0,
      sleepGoal: json['sleep_goal'] as int? ?? 5,
      activityProgress: json['activity_progress'] as int? ?? 0,
      activityGoal: json['activity_goal'] as int? ?? 5,
      autoSuggestionsEnabled: json['auto_suggestions_enabled'] as bool? ?? true,
      morningReminderTime:
          json['morning_reminder_time'] as String? ?? '08:00:00',
      eveningReminderTime:
          json['evening_reminder_time'] as String? ?? '21:30:00',
      dailyRemindersEnabled: json['daily_reminders_enabled'] as bool? ?? true,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      lastProfileUpdate: json['last_profile_update'] != null
          ? DateTime.parse(json['last_profile_update'] as String)
          : null,
    );
  }

  /// Convierte la instancia a un Map para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'age': age,
      'institution': institution,
      'profile_image_url': profileImageUrl,
      'phone': phone,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'risk_factors': riskFactors,
      'hydration_progress': hydrationProgress,
      'hydration_goal': hydrationGoal,
      'sleep_progress': sleepProgress,
      'sleep_goal': sleepGoal,
      'activity_progress': activityProgress,
      'activity_goal': activityGoal,
      'auto_suggestions_enabled': autoSuggestionsEnabled,
      'morning_reminder_time': morningReminderTime,
      'evening_reminder_time': eveningReminderTime,
      'daily_reminders_enabled': dailyRemindersEnabled,
      'is_profile_complete': isProfileComplete,
    };
  }

  /// Crea una copia con campos modificados
  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? age,
    String? institution,
    String? profileImageUrl,
    String? phone,
    double? heightCm,
    double? weightKg,
    List<String>? riskFactors,
    int? hydrationProgress,
    int? hydrationGoal,
    int? sleepProgress,
    int? sleepGoal,
    int? activityProgress,
    int? activityGoal,
    bool? autoSuggestionsEnabled,
    String? morningReminderTime,
    String? eveningReminderTime,
    bool? dailyRemindersEnabled,
    bool? isProfileComplete,
    DateTime? lastProfileUpdate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      institution: institution ?? this.institution,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      riskFactors: riskFactors ?? this.riskFactors,
      hydrationProgress: hydrationProgress ?? this.hydrationProgress,
      hydrationGoal: hydrationGoal ?? this.hydrationGoal,
      sleepProgress: sleepProgress ?? this.sleepProgress,
      sleepGoal: sleepGoal ?? this.sleepGoal,
      activityProgress: activityProgress ?? this.activityProgress,
      activityGoal: activityGoal ?? this.activityGoal,
      autoSuggestionsEnabled:
          autoSuggestionsEnabled ?? this.autoSuggestionsEnabled,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
      dailyRemindersEnabled:
          dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      lastProfileUpdate: lastProfileUpdate ?? this.lastProfileUpdate,
    );
  }

  /// Nombre completo del usuario
  String get fullName => '$firstName $lastName';

  /// Altura formateada para mostrar (ej: "1.72 m")
  String get formattedHeight {
    if (heightCm == null) return 'No especificado';
    return '${(heightCm! / 100).toStringAsFixed(2)} m';
  }

  /// Peso formateado para mostrar (ej: "68 kg")
  String get formattedWeight {
    if (weightKg == null) return 'No especificado';
    return '${weightKg!.toStringAsFixed(0)} kg';
  }

  /// Progreso de hidratación formateado (ej: "4/5 días")
  String get formattedHydrationProgress =>
      '$hydrationProgress/$hydrationGoal días';

  /// Progreso de sueño formateado (ej: "2/5 días")
  String get formattedSleepProgress => '$sleepProgress/$sleepGoal días';

  /// Progreso de actividad formateado (ej: "3/5 días")
  String get formattedActivityProgress =>
      '$activityProgress/$activityGoal días';

  /// Hora del recordatorio matutino formateada (ej: "8:00 am")
  String get formattedMorningTime {
    final parts = morningReminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Hora del recordatorio nocturno formateada (ej: "9:30 pm")
  String get formattedEveningTime {
    final parts = eveningReminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Verifica si los datos básicos están completos
  bool get hasBasicInfo =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      age != null;

  /// Verifica si los datos de salud están completos
  bool get hasHealthInfo => heightCm != null && weightKg != null;

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    createdAt,
    updatedAt,
    age,
    institution,
    profileImageUrl,
    phone,
    heightCm,
    weightKg,
    riskFactors,
    hydrationProgress,
    hydrationGoal,
    sleepProgress,
    sleepGoal,
    activityProgress,
    activityGoal,
    autoSuggestionsEnabled,
    morningReminderTime,
    eveningReminderTime,
    dailyRemindersEnabled,
    isProfileComplete,
    lastProfileUpdate,
  ];

  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: $fullName, email: $email, isComplete: $isProfileComplete)';
  }
}

/// Factores de riesgo predefinidos
class RiskFactors {
  static const String eatsOutFrequently = 'Come fuera frecuentemente';
  static const String drinksCoffeeOnEmptyStomach = 'Consume café en ayunas';
  static const String smokes = 'Fuma';
  static const String sedentaryLifestyle = 'Vida sedentaria';
  static const String irregularSleep = 'Sueño irregular';
  static const String highStress = 'Alto estrés';
  static const String poorHydration = 'Hidratación deficiente';

  static const List<String> all = [
    eatsOutFrequently,
    drinksCoffeeOnEmptyStomach,
    smokes,
    sedentaryLifestyle,
    irregularSleep,
    highStress,
    poorHydration,
  ];
}
