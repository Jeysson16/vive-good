import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getCurrentUser();
      return Right(userModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await localDataSource.saveUser(userModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await localDataSource.updateUser(userModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser() async {
    try {
      await localDataSource.deleteUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isFirstTimeUser() async {
    try {
      final isFirstTime = await localDataSource.isFirstTimeUser();
      return Right(isFirstTime);
    } catch (e) {
      return Left(CacheFailure('Failed to check first time user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setFirstTimeUser(bool isFirstTime) async {
    try {
      await localDataSource.setFirstTimeUser(isFirstTime);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    try {
      final result = await localDataSource.hasCompletedOnboarding();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> setOnboardingCompleted(bool completed) async {
    try {
      await localDataSource.setOnboardingCompleted(completed);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> completeOnboarding() async {
    try {
      await localDataSource.setOnboardingCompleted(true);
      return Right(true);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}