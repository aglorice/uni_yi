import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/repositories/gym_booking_repository.dart';

class CancelGymAppointmentUseCase {
  const CancelGymAppointmentUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<void>> call({
    required AppSession session,
    required String appointmentId,
    String? reason,
  }) {
    return _repository.cancelAppointment(
      session: session,
      appointmentId: appointmentId,
      reason: reason,
    );
  }
}
