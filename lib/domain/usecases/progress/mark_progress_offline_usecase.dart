import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/progress.dart';
import '../../entities/habit_progress.dart';
import '../../repositories/progress_repository.dart';
import '../../../data/services/connectivity_service.dart';

class MarkProgressOfflineUseCase implements UseCase<void, MarkProgressOfflineParams> {
  final ProgressRepository repository;
  final ConnectivityService connectivityService;

  MarkProgressOfflineUseCase({
    required this.repository,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, void>> call(MarkProgressOfflineParams params) async {
    try {
      // Validar que el userId no esté vacío
      if (params.userId == null || params.userId!.isEmpty) {
        return Left(ValidationFailure('UserId es requerido'));
      }

      // Crear el progreso
      final progress = HabitProgress(
        id: params.progressId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: params.userId!,
        habitId: params.habitId,
        date: params.date,
        completed: params.completed,
        notes: params.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Siempre marcar el progreso (el repositorio híbrido maneja la lógica offline)
      final result = await repository.markProgress(progress);
      
      return result.fold(
        (failure) => Left(failure),
        (_) {
          // Si está offline, mostrar mensaje informativo
          if (connectivityService.isOffline) {
            // El progreso se guardó localmente y se sincronizará cuando haya conexión
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

class MarkProgressOfflineParams extends Equatable {
  final String? progressId;
  final String? userId;
  final String habitId;
  final DateTime date;
  final bool completed;
  final String? notes;
  final bool forceOffline;

  const MarkProgressOfflineParams({
    this.progressId,
    this.userId,
    required this.habitId,
    required this.date,
    required this.completed,
    this.notes,
    this.forceOffline = false,
  });

  @override
  List<Object?> get props => [progressId, userId, habitId, date, completed, notes, forceOffline];
}