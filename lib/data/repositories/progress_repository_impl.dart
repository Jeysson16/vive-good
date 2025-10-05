import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_datasource.dart';
import '../models/progress.dart';
import '../services/connectivity_service.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final ConnectivityService connectivityService;

  ProgressRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, Progress>> getUserProgress(String userId) async {
    try {
      // Verificar conectividad
      final connectivityStatus = await connectivityService.currentStatus;
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar obtener datos remotos
          final remoteProgress = await remoteDataSource.getUserProgress(userId);
          
          return Right(remoteProgress.toEntity());
        } on ServerException catch (e) {
          // Si falla el remoto, no hay datos locales para el progreso general del usuario
          return Left(ServerFailure(e.message));
        } catch (e) {
          return Left(ServerFailure('Error inesperado: ${e.toString()}'));
        }
      } else {
        // Sin conexión, no hay datos locales para el progreso general del usuario
        return Left(NetworkFailure('No hay conexión a internet'));
      }
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Progress>> updateUserProgress(
    Progress progress,
  ) async {
    try {
      // Verificar conectividad
      final connectivityStatus = await connectivityService.currentStatus;
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar sincronizar con remoto
          final progressModel = ProgressModel.fromEntity(progress);
          final updatedProgress = await remoteDataSource.updateUserProgress(
            progress.userId,
            progressModel,
          );
          
          return Right(updatedProgress.toEntity());
        } on ServerException catch (e) {
          // Si falla el remoto, retornar error
          return Left(ServerFailure(e.message));
        } catch (e) {
          return Left(ServerFailure('Error inesperado: ${e.toString()}'));
        }
      } else {
        // Sin conexión, retornar error
        return Left(NetworkFailure('No hay conexión a internet'));
      }
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Progress>> getWeeklyProgress(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final weeklyProgress = await remoteDataSource.getWeeklyProgress(userId);
        return Right(weeklyProgress.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<Progress>>> getMonthlyProgress(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final monthlyProgressList = await remoteDataSource.getMonthlyProgress(userId);
        final progressEntities = monthlyProgressList
            .map((model) => model.toEntity())
            .toList();
        return Right(progressEntities);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getDailyWeekProgress(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final dailyProgress = await remoteDataSource.getDailyWeekProgress(userId);
        return Right(dailyProgress);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, int>> getUserStreak(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final streak = await remoteDataSource.getUserStreak(userId);
        return Right(streak);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No hay conexión a internet'));
    }
  }
}