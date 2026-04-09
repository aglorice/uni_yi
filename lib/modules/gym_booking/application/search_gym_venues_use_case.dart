import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_venue_search_page.dart';
import '../domain/repositories/gym_booking_repository.dart';

class SearchGymVenuesUseCase {
  const SearchGymVenuesUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<GymVenueSearchPage>> call({
    required AppSession session,
    required GymVenueSearchQuery query,
  }) {
    return _repository.searchVenues(session: session, query: query);
  }
}
