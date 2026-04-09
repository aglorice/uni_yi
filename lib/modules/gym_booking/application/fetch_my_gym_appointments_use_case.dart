import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_booking_overview.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchMyGymAppointmentsUseCase {
  const FetchMyGymAppointmentsUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<List<BookingRecord>>> call({
    required AppSession session,
    bool forceRefresh = false,
  }) {
    return _repository.fetchMyAppointments(
      session: session,
      forceRefresh: forceRefresh,
    );
  }
}
