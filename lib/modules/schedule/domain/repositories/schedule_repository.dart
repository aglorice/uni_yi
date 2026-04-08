import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_session.dart';
import '../entities/schedule_snapshot.dart';

abstract class ScheduleRepository {
  Future<Result<ScheduleSnapshot>> fetchCurrentSchedule({
    required AppSession session,
    String? termId,
    bool forceRefresh = false,
  });
}
