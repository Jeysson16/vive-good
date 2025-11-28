import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/admin_repository.dart';

class CheckAdminPermissionsUseCase implements UseCase<bool, CheckAdminPermissionsParams> {
  final AdminRepository repository;

  CheckAdminPermissionsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckAdminPermissionsParams params) async {
    print('🎯 [USECASE] CheckAdminPermissionsUseCase llamado con userId: ${params.userId}');
    
    final result = await repository.checkAdminPermissions(params.userId);
    
    result.fold(
      (failure) => print('❌ [USECASE] Error en CheckAdminPermissionsUseCase: $failure'),
      (hasPermissions) => print('✅ [USECASE] CheckAdminPermissionsUseCase resultado: $hasPermissions'),
    );
    
    return result;
  }
}

class CheckAdminPermissionsParams extends Equatable {
  final String userId;

  const CheckAdminPermissionsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}