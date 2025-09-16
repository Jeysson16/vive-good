import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/calendar_event.dart';
import '../../repositories/calendar_repository.dart';

class MarkEventCompleted implements UseCase<CalendarEvent, MarkEventCompletedParams> {
  final CalendarRepository repository;

  MarkEventCompleted(this.repository);

  @override
  Future<Either<Failure, CalendarEvent>> call(
    MarkEventCompletedParams params,
  ) async {
    return await repository.markEventAsCompleted(params.eventId);
  }
}

class MarkEventCompletedParams extends Equatable {
  final String eventId;

  const MarkEventCompletedParams({
    required this.eventId,
  });

  @override
  List<Object?> get props => [eventId];
}