import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, void>> saveUser(User user);
  Future<Either<Failure, void>> updateUser(User user);
  Future<Either<Failure, void>> deleteUser();
  Future<Either<Failure, bool>> isFirstTimeUser();
  Future<Either<Failure, void>> setFirstTimeUser(bool isFirstTime);
  Future<Either<Failure, bool>> hasCompletedOnboarding();
  Future<Either<Failure, void>> setOnboardingCompleted(bool completed);
  Future<Either<Failure, bool>> completeOnboarding();
}