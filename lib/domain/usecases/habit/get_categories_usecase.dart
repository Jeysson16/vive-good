import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/category.dart';
import '../../repositories/habit_repository.dart';

class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final HabitRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return await repository.getHabitCategories();
  }
}