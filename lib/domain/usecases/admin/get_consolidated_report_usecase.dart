import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/admin/consolidated_report.dart';
import '../../repositories/admin_repository.dart';

class GetConsolidatedReportUseCase implements UseCase<List<ConsolidatedReport>, GetConsolidatedReportParams> {
  final AdminRepository repository;

  GetConsolidatedReportUseCase(this.repository);

  @override
  Future<Either<Failure, List<ConsolidatedReport>>> call(GetConsolidatedReportParams params) async {
    return await repository.getConsolidatedReport(
      startDate: params.startDate,
      endDate: params.endDate,
      roleFilter: params.roleFilter,
    );
  }
}

class GetConsolidatedReportParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? roleFilter;

  const GetConsolidatedReportParams({
    this.startDate,
    this.endDate,
    this.roleFilter,
  });

  @override
  List<Object?> get props => [startDate, endDate, roleFilter];
}