import '../../../core/logging/app_logger.dart';
import '../../../core/models/data_origin.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../../integrations/school_portal/school_portal_gateway.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/schedule_snapshot.dart';
import '../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl({
    required SchoolPortalGateway gateway,
    required JsonCacheStore cacheStore,
    required AppLogger logger,
  }) : _gateway = gateway,
       _cacheStore = cacheStore,
       _logger = logger;

  static const _cacheKey = 'schedule.snapshot.current';

  final SchoolPortalGateway _gateway;
  final JsonCacheStore _cacheStore;
  final AppLogger _logger;

  @override
  Future<Result<ScheduleSnapshot>> fetchCurrentSchedule({
    required AppSession session,
    String? termId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = termId == null || termId.isEmpty
        ? _cacheKey
        : '$_cacheKey.$termId';
    final remote = await _gateway.fetchSchedule(session, termId: termId);
    if (remote case Success<ScheduleSnapshot>(data: final snapshot)) {
      await _cacheStore.writeMap(cacheKey, snapshot.toJson());
      return Success(snapshot);
    }

    final cached = await _cacheStore.readMap(cacheKey);
    if (cached != null) {
      _logger.warn('Falling back to cached schedule data.');
      return Success(
        ScheduleSnapshot.fromJson(cached).copyWith(origin: DataOrigin.cache),
      );
    }

    return FailureResult(remote.failureOrNull!);
  }
}
