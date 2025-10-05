import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../../data/services/connectivity_service.dart';

class UpdateProfileOfflineUseCase implements UseCase<void, UpdateProfileOfflineParams> {
  final UserRepository repository;
  final ConnectivityService connectivityService;

  UpdateProfileOfflineUseCase({
    required this.repository,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, void>> call(UpdateProfileOfflineParams params) async {
    try {
      // Siempre actualizar el perfil (el repositorio híbrido maneja la lógica offline)
      final result = await repository.updateUser(params.user);
      
      return result.fold(
        (failure) => Left(failure),
        (_) {
          // Si está offline, mostrar mensaje informativo
          if (connectivityService.isOffline) {
            // El perfil se actualizó localmente y se sincronizará cuando haya conexión
            return const Right(null);
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

class UpdateProfileOfflineParams extends Equatable {
  final User user;
  final bool forceOffline;

  const UpdateProfileOfflineParams({
    required this.user,
    this.forceOffline = false,
  });

  @override
  List<Object> get props => [user, forceOffline];
}