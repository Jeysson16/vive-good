import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/calendar_event.dart';
import '../../repositories/calendar_repository.dart';

class GetCalendarEvents implements UseCase<List<CalendarEvent>, GetCalendarEventsParams> {
  final CalendarRepository repository;

  GetCalendarEvents(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(
    GetCalendarEventsParams params,
  ) async {
    return await repository.getCalendarEvents(
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetCalendarEventsParams extends Equatable {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetCalendarEventsParams({
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}