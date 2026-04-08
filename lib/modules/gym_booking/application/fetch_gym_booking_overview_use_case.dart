import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_booking_overview.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchGymBookingOverviewUseCase {
  const FetchGymBookingOverviewUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<GymBookingOverview>> call({
    required AppSession session,
    required DateTime date,
    bool forceRefresh = false,
  }) {
    return _repository.fetchOverview(
      session: session,
      date: date,
      forceRefresh: forceRefresh,
    );
  }
}
