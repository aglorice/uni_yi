import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/venue_detail.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchVenueDetailUseCase {
  const FetchVenueDetailUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<VenueDetail>> call({
    required AppSession session,
    required String wid,
  }) {
    return _repository.fetchVenueDetail(session: session, wid: wid);
  }
}
