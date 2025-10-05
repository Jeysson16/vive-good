import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../datasources/user_remote_datasource.dart';
import '../services/connectivity_service.dart';
import '../models/user_model.dart';
import 'local/user_local_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;
  final UserRemoteDataSource remoteDataSource;
  final UserLocalRepository userLocalRepository;
  final ConnectivityService connectivityService;

  UserRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.userLocalRepository,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Intentar obtener usuario local primero usando el nuevo repositorio
      final localUserResult = await userLocalRepository.getCurrentUser();
      
      // Verificar conectividad
      final connectivityStatus = await connectivityService.currentStatus;
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar obtener datos remotos
          final remoteUser = await remoteDataSource.getCurrentUser();
          if (remoteUser != null) {
            // Actualizar datos locales con los remotos
            await userLocalRepository.saveUserFromServer(remoteUser.toEntity());
            return Right(remoteUser.toEntity());
          }
        } catch (e) {
          // Si falla el remoto pero hay usuario local, usar local
          return localUserResult.fold(
            (failure) => Left(failure),
            (localUser) => Right(localUser),
          );
        }
      }
      
      // Sin conexión o sin datos remotos, usar datos locales
      return localUserResult;
    } catch (e) {
      return Left(CacheFailure('Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUser(User user) async {
    try {
      // Siempre guardar localmente primero usando el nuevo repositorio
      final localResult = await userLocalRepository.saveUser(user);
      
      return localResult.fold(
        (failure) => Left(failure),
        (_) async {
          // Verificar conectividad
          final connectivityStatus = await connectivityService.currentStatus;
          
          if (connectivityStatus.isOnline) {
            try {
              // Si hay conexión, intentar sincronizar con remoto
              final userModel = UserModel.fromEntity(user);
              await remoteDataSource.saveUser(userModel);
              
              // Marcar como sincronizado
              await userLocalRepository.markUserAsSynced(user.id);
            } catch (e) {
              // Si falla el remoto, los datos ya están guardados localmente
              // La sincronización se hará automáticamente cuando se restablezca la conexión
            }
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to save user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(User user) async {
    try {
      // Siempre actualizar localmente primero
      await localDataSource.updateUser(user.id, {
        'email': user.email,
        'full_name': user.fullName,
        'avatar_url': user.avatarUrl,
      });
      
      // Verificar conectividad
      final connectivityStatus = await connectivityService.currentStatus;
      
      if (connectivityStatus.isOnline) {
        try {
          // Si hay conexión, intentar sincronizar con remoto
          await remoteDataSource.updateUser(user.id, {
            'first_name': user.firstName,
            'last_name': user.lastName,
            'email': user.email,
            'avatar_url': user.avatarUrl,
          });
        } catch (e) {
          // Si falla el remoto, los datos ya están guardados localmente
          // La sincronización se hará automáticamente cuando se restablezca la conexión
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser() async {
    try {
      final currentUser = await localDataSource.getCurrentUser();
      if (currentUser != null) {
        await localDataSource.deleteUser(currentUser.id);
      }
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