import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../entities/user.dart';
import '../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResult>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResult>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, User?>> getCurrentUser();

  Future<Either<Failure, void>> resetPassword(String email);

  Stream<User?> get authStateChanges;
}