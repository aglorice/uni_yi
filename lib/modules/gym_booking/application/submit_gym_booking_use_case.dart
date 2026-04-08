import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_booking_overview.dart';
import '../domain/repositories/gym_booking_repository.dart';

class SubmitGymBookingUseCase {
  const SubmitGymBookingUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<BookingRecord>> call({
    required AppSession session,
    required BookingDraft draft,
  }) {
    return _repository.submitBooking(session: session, draft: draft);
  }
}
