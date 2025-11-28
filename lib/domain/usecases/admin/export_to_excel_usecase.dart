import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/admin_repository.dart';

class ExportToExcelUseCase implements UseCase<String, ExportToExcelParams> {
  final AdminRepository repository;

  ExportToExcelUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ExportToExcelParams params) async {
    return await repository.exportToExcel(
      reportType: params.reportType,
      startDate: params.startDate,
      endDate: params.endDate,
      filters: params.filters,
    );
  }
}

class ExportToExcelParams extends Equatable {
  final String reportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? filters;

  const ExportToExcelParams({
    required this.reportType,
    this.startDate,
    this.endDate,
    this.filters,
  });

  @override
  List<Object?> get props => [reportType, startDate, endDate, filters];
}