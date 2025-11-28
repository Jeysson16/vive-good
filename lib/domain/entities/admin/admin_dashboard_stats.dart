import 'package:equatable/equatable.dart';

class AdminDashboardStats extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int totalHabits;
  final int totalEvaluations;
  final int totalConsultations;
  final double averageRating;
  final int totalCategories;
  final int totalRoles;
  final DateTime lastUpdated;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalHabits,
    required this.totalEvaluations,
    required this.totalConsultations,
    required this.averageRating,
    required this.totalCategories,
    required this.totalRoles,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        activeUsers,
        totalHabits,
        totalEvaluations,
        totalConsultations,
        averageRating,
        totalCategories,
        totalRoles,
        lastUpdated,
      ];

  AdminDashboardStats copyWith({
    int? totalUsers,
    int? activeUsers,
    int? totalHabits,
    int? totalEvaluations,
    int? totalConsultations,
    double? averageRating,
    int? totalCategories,
    int? totalRoles,
    DateTime? lastUpdated,
  }) {
    return AdminDashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      totalHabits: totalHabits ?? this.totalHabits,
      totalEvaluations: totalEvaluations ?? this.totalEvaluations,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      averageRating: averageRating ?? this.averageRating,
      totalCategories: totalCategories ?? this.totalCategories,
      totalRoles: totalRoles ?? this.totalRoles,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}