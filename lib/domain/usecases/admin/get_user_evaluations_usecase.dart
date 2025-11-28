import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/admin/user_evaluation.dart';
import '../../repositories/admin_repository.dart';

class GetUserEvaluationsUseCase implements UseCase<List<UserEvaluation>, GetUserEvaluationsParams> {
  final AdminRepository repository;

  GetUserEvaluationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEvaluation>>> call(GetUserEvaluationsParams params) async {
    return await repository.getUserEvaluations(
      roleFilter: params.roleFilter,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetUserEvaluationsParams extends Equatable {
  final String? roleFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;
  final int? offset;

  const GetUserEvaluationsParams({
    this.roleFilter,
    this.startDate,
    this.endDate,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [roleFilter, startDate, endDate, limit, offset];
}