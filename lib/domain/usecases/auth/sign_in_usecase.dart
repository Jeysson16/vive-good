import 'package:dartz/dartz.dart';
import '../../entities/auth_result.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class SignInUseCase implements UseCase<AuthResult, SignInParams> {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(SignInParams params) async {
    return await repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}