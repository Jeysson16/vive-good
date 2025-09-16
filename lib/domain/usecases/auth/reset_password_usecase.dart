import 'package:dartz/dartz.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(params.email);
  }
}

class ResetPasswordParams {
  final String email;

  ResetPasswordParams({required this.email});
}