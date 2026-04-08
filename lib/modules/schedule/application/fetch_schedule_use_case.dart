import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/schedule_snapshot.dart';
import '../domain/repositories/schedule_repository.dart';

class FetchScheduleUseCase {
  const FetchScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Result<ScheduleSnapshot>> call({
    required AppSession session,
    String? termId,
    bool forceRefresh = false,
  }) {
    return _repository.fetchCurrentSchedule(
      session: session,
      termId: termId,
      forceRefresh: forceRefresh,
    );
  }
}
