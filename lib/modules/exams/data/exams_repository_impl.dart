import '../../../core/logging/app_logger.dart';
import '../../../core/models/data_origin.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../../integrations/school_portal/school_portal_gateway.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/exam_schedule_snapshot.dart';
import '../domain/repositories/exams_repository.dart';

class ExamsRepositoryImpl implements ExamsRepository {
  const ExamsRepositoryImpl({
    required SchoolPortalGateway gateway,
    required JsonCacheStore cacheStore,
    required AppLogger logger,
  }) : _gateway = gateway,
       _cacheStore = cacheStore,
       _logger = logger;

  static const _cacheKey = 'exams.snapshot.current';

  final SchoolPortalGateway _gateway;
  final JsonCacheStore _cacheStore;
  final AppLogger _logger;

  @override
  Future<Result<ExamScheduleSnapshot>> fetchExamSchedule({
    required AppSession session,
    String? termId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = termId == null || termId.isEmpty
        ? _cacheKey
        : '$_cacheKey.$termId';
    final remote = await _gateway.fetchExamSchedule(session, termId: termId);
    if (remote case Success<ExamScheduleSnapshot>(data: final snapshot)) {
      await _cacheStore.writeMap(cacheKey, snapshot.toJson());
      return Success(snapshot);
    }

    final cached = await _cacheStore.readMap(cacheKey);
    if (cached != null) {
      _logger.warn('Falling back to cached exam schedule data.');
      return Success(
        ExamScheduleSnapshot.fromJson(
          cached,
        ).copyWith(origin: DataOrigin.cache),
      );
    }

    return FailureResult(remote.failureOrNull!);
  }
}
