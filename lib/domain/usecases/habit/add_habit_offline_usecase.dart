import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';
import '../../../data/services/connectivity_service.dart';

class AddHabitOfflineUseCase implements UseCase<void, AddHabitOfflineParams> {
  final HabitRepository repository;
  final ConnectivityService connectivityService;

  AddHabitOfflineUseCase({
    required this.repository,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, void>> call(AddHabitOfflineParams params) async {
    try {
      // Siempre agregar el hábito (el repositorio híbrido maneja la lógica offline)
      final result = await repository.addHabit(params.habit);
      
      return result.fold(
        (failure) => Left(failure),
        (_) {
          // Si está offline, mostrar mensaje informativo
          if (connectivityService.isOffline) {
            // El hábito se guardó localmente y se sincronizará cuando haya conexión
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

class AddHabitOfflineParams extends Equatable {
  final Habit habit;
  final bool forceOffline;

  const AddHabitOfflineParams({
    required this.habit,
    this.forceOffline = false,
  });

  @override
  List<Object> get props => [habit, forceOffline];
}