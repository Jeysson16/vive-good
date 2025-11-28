import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/admin/admin_dashboard_stats.dart';
import '../../repositories/admin_repository.dart';

class GetAdminDashboardStatsUseCase implements UseCase<AdminDashboardStats, NoParams> {
  final AdminRepository repository;

  GetAdminDashboardStatsUseCase(this.repository);

  @override
  Future<Either<Failure, AdminDashboardStats>> call(NoParams params) async {
    return await repository.getDashboardStats();
  }
}