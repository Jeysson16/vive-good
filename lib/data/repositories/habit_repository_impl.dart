import 'package:dartz/dartz.dart';
import 'package:vive_good_app/core/error/failures.dart';
import 'package:vive_good_app/core/errors/exceptions.dart' as custom_exceptions;
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/entities/category.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import 'package:vive_good_app/domain/entities/habit_breakdown.dart';
import 'package:vive_good_app/domain/repositories/habit_repository.dart';
import 'package:vive_good_app/data/datasources/habit_remote_datasource.dart';
import 'package:vive_good_app/data/models/habit_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource remoteDataSource;

  HabitRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<UserHabit>>> getUserHabits(String userId) async {
    try {
      final remoteHabits = await remoteDataSource.getUserHabits(userId);
      return Right(remoteHabits.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get user habits'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getHabitCategories() async {
    try {
      final remoteCategories = await remoteDataSource.getHabitCategories();
      return Right(remoteCategories.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get habit categories'));
    }
  }

  @override
  Future<Either<Failure, List<Habit>>> getHabitSuggestions({
    String? userId,
    String? categoryId,
    int? limit,
  }) async {
    try {
      final habits = await remoteDataSource.getHabitSuggestions(
        userId: userId,
        categoryId: categoryId,
        limit: limit,
      );
      return Right(habits.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get habit suggestions'));
    }
  }

  @override
  Future<Either<Failure, void>> logHabitCompletion(String habitId, DateTime date) async {
    try {
      await remoteDataSource.logHabitCompletion(habitId, date);
      return const Right(null);
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to log habit completion'));
    }
  }

  @override
  Future<Either<Failure, void>> addHabit(Habit habit) async {
    try {
      final habitModel = HabitModel.fromEntity(habit);
      await remoteDataSource.addHabit(habitModel);
      return const Right(null);
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to add habit'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabit(String habitId) async {
    try {
      await remoteDataSource.deleteHabit(habitId);
      return const Right(null);
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to delete habit'));
    }
  }

  @override
  Future<Either<Failure, List<UserHabit>>> getDashboardHabits(String userId, int limit, bool includeCompletionStatus) async {
    try {
      final remoteDashboardHabits = await remoteDataSource.getDashboardHabits(userId, limit, includeCompletionStatus);
      return Right(remoteDashboardHabits.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get dashboard habits'));
    }
  }

  @override
  Future<Either<Failure, List<HabitBreakdown>>> getMonthlyHabitsBreakdown(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final remoteBreakdown = await remoteDataSource.getMonthlyHabitsBreakdown(userId, year, month);
      return Right(remoteBreakdown.map((model) => model.toEntity()).toList());
    } on custom_exceptions.ServerException {
      return Left(ServerFailure('Failed to get monthly habits breakdown'));
    }
  }
}
