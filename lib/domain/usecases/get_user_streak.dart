import 'package:dartz/dartz.dart';
import '../repositories/progress_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class GetUserStreak implements UseCase<int, GetUserStreakParams> {
  final ProgressRepository repository;

  GetUserStreak(this.repository);

  @override
  Future<Either<Failure, int>> call(GetUserStreakParams params) async {
    return await repository.getUserStreak(params.userId);
  }
}

class GetUserStreakParams {
  final String userId;

  const GetUserStreakParams({required this.userId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetUserStreakParams && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}