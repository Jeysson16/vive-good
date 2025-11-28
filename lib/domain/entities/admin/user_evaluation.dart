import 'package:equatable/equatable.dart';

class UserEvaluation extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final String? roleName;
  final DateTime? lastLogin;
  final int totalHabits;
  final int completedHabits;
  final double completionRate;
  final int totalConsultations;
  final double? averageRating;
  final DateTime createdAt;
  final bool isActive;

  const UserEvaluation({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.roleName,
    this.lastLogin,
    required this.totalHabits,
    required this.completedHabits,
    required this.completionRate,
    required this.totalConsultations,
    this.averageRating,
    required this.createdAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        userEmail,
        roleName,
        lastLogin,
        totalHabits,
        completedHabits,
        completionRate,
        totalConsultations,
        averageRating,
        createdAt,
        isActive,
      ];

  UserEvaluation copyWith({
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
    return UserEvaluation(
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