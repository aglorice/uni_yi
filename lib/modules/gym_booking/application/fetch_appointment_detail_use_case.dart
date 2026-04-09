import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/appointment_detail.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchAppointmentDetailUseCase {
  const FetchAppointmentDetailUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<AppointmentDetail>> call({
    required AppSession session,
    required String wid,
  }) {
    return _repository.fetchAppointmentDetail(session: session, wid: wid);
  }
}
