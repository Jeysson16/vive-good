import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/admin/tech_acceptance_indicators.dart';
import '../../repositories/admin_repository.dart';

class GetTechAcceptanceIndicatorsUseCase implements UseCase<List<TechAcceptanceIndicators>, GetTechAcceptanceIndicatorsParams> {
  final AdminRepository repository;

  GetTechAcceptanceIndicatorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TechAcceptanceIndicators>>> call(GetTechAcceptanceIndicatorsParams params) async {
    return await repository.getTechAcceptanceIndicators(
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetTechAcceptanceIndicatorsParams extends Equatable {
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetTechAcceptanceIndicatorsParams({
    this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}