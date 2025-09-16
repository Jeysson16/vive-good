import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/calendar_event.dart';
import '../../repositories/calendar_repository.dart';

class CreateCalendarEvent implements UseCase<CalendarEvent, CreateCalendarEventParams> {
  final CalendarRepository repository;

  CreateCalendarEvent(this.repository);

  @override
  Future<Either<Failure, CalendarEvent>> call(
    CreateCalendarEventParams params,
  ) async {
    return await repository.createCalendarEvent(params.event);
  }
}

class CreateCalendarEventParams extends Equatable {
  final CalendarEvent event;

  const CreateCalendarEventParams({
    required this.event,
  });

  @override
  List<Object?> get props => [event];
}