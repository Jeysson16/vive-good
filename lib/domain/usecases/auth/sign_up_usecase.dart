import 'package:dartz/dartz.dart';
import '../../entities/auth_result.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';

class SignUpUseCase implements UseCase<AuthResult, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(SignUpParams params) async {
    return await repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      firstName: params.firstName,
      lastName: params.lastName,
    );
  }
}

class SignUpParams {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  SignUpParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });
}