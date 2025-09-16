import 'package:dartz/dartz.dart';
import '../entities/progress.dart';
import '../../core/error/failures.dart';

abstract class ProgressRepository {
  /// Obtiene el progreso del usuario por su ID
  Future<Either<Failure, Progress>> getUserProgress(String userId);
  
  /// Actualiza las métricas de progreso del usuario
  Future<Either<Failure, Progress>> updateUserProgress(Progress progress);
  
  /// Obtiene el progreso semanal del usuario
  Future<Either<Failure, Progress>> getWeeklyProgress(String userId);
  
  /// Obtiene el progreso mensual del usuario
  Future<Either<Failure, List<Progress>>> getMonthlyProgress(String userId);
  
  /// Obtiene el progreso diario de la semana actual
  /// Retorna un mapa con los nombres de los días y sus porcentajes de completitud
  Future<Either<Failure, Map<String, double>>> getDailyWeekProgress(String userId);
}