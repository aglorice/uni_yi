import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_search_filter.dart';
import '../domain/repositories/gym_booking_repository.dart';

class FetchGymSearchModelUseCase {
  const FetchGymSearchModelUseCase(this._repository);

  final GymBookingRepository _repository;

  Future<Result<GymSearchModel>> call({required AppSession session}) {
    return _repository.fetchSearchModel(session: session);
  }
}
