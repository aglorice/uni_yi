import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/venue_review.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchVenueReviewsUseCase {
  const FetchVenueReviewsUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<VenueReviewPage>> call({
    required AppSession session,
    required String bizWid,
    int page = 1,
    int pageSize = 10,
  }) {
    return _repository.fetchVenueReviews(
      session: session,
      bizWid: bizWid,
      page: page,
      pageSize: pageSize,
    );
  }
}
