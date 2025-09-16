import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource localDataSource;

  OnboardingRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<OnboardingStep>>> getOnboardingSteps() async {
    try {
      final stepModels = await localDataSource.getOnboardingSteps();
      final steps = stepModels.map((model) => model.toEntity()).toList();
      return Right(steps);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, OnboardingStep?>> getOnboardingStepById(String id) async {
    try {
      final stepModel = await localDataSource.getOnboardingStepById(id);
      final step = stepModel?.toEntity();
      return Right(step);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getCurrentStepIndex() async {
    try {
      final index = await localDataSource.getCurrentStepIndex();
      return Right(index);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> setCurrentStepIndex(int index) async {
    try {
      await localDataSource.setCurrentStepIndex(index);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> completeOnboarding() async {
    try {
      await localDataSource.completeOnboarding();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isOnboardingCompleted() async {
    try {
      final isCompleted = await localDataSource.isOnboardingCompleted();
      return Right(isCompleted);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}