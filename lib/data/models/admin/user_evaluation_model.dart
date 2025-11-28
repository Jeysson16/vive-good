import '../../../domain/entities/admin/user_evaluation.dart';

class UserEvaluationModel extends UserEvaluation {
  const UserEvaluationModel({
    required super.userId,
    required super.userName,
    required super.userEmail,
    super.roleName,
    super.lastLogin,
    required super.totalHabits,
    required super.completedHabits,
    required super.completionRate,
    required super.totalConsultations,
    super.averageRating,
    required super.createdAt,
    required super.isActive,
  });

  factory UserEvaluationModel.fromJson(Map<String, dynamic> json) {
    return UserEvaluationModel(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      roleName: json['role_name'],
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'])
          : null,
      totalHabits: json['total_habits'] ?? 0,
      completedHabits: json['completed_habits'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
      totalConsultations: json['total_consultations'] ?? 0,
      averageRating: json['average_rating'] != null 
          ? (json['average_rating']).toDouble()
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'role_name': roleName,
      'last_login': lastLogin?.toIso8601String(),
      'total_habits': totalHabits,
      'completed_habits': completedHabits,
      'completion_rate': completionRate,
      'total_consultations': totalConsultations,
      'average_rating': averageRating,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  UserEvaluationModel copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? roleName,
    DateTime? lastLogin,
    int? totalHabits,
    int? completedHabits,
    double? completionRate,
    int? totalConsultations,
    double? averageRating,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserEvaluationModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      roleName: roleName ?? this.roleName,
      lastLogin: lastLogin ?? this.lastLogin,
      totalHabits: totalHabits ?? this.totalHabits,
      completedHabits: completedHabits ?? this.completedHabits,
      completionRate: completionRate ?? this.completionRate,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}