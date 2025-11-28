import '../../../domain/entities/admin/admin_dashboard_stats.dart';

class AdminDashboardStatsModel extends AdminDashboardStats {
  const AdminDashboardStatsModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.totalHabits,
    required super.totalEvaluations,
    required super.totalConsultations,
    required super.averageRating,
    required super.totalCategories,
    required super.totalRoles,
    required super.lastUpdated,
  });

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalHabits: json['total_habits'] ?? 0,
      totalEvaluations: json['total_evaluations'] ?? 0,
      totalConsultations: json['total_consultations'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalCategories: json['total_categories'] ?? 0,
      totalRoles: json['total_roles'] ?? 0,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'total_habits': totalHabits,
      'total_evaluations': totalEvaluations,
      'total_consultations': totalConsultations,
      'average_rating': averageRating,
      'total_categories': totalCategories,
      'total_roles': totalRoles,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  @override
  AdminDashboardStatsModel copyWith({
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
    return AdminDashboardStatsModel(
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