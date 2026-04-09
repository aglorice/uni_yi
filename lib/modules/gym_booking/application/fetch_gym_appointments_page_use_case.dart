import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_appointment_page.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchGymAppointmentsPageUseCase {
  const FetchGymAppointmentsPageUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<GymAppointmentPage>> call({
    required AppSession session,
    required GymAppointmentQuery query,
  }) {
    return _repository.fetchMyAppointmentsPage(session: session, query: query);
  }
}
