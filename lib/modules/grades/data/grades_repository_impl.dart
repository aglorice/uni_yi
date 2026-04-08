import '../../../core/logging/app_logger.dart';
import '../../../core/models/data_origin.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../../integrations/school_portal/school_portal_gateway.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/grades_snapshot.dart';
import '../domain/repositories/grades_repository.dart';

class GradesRepositoryImpl implements GradesRepository {
  const GradesRepositoryImpl({
    required SchoolPortalGateway gateway,
    required JsonCacheStore cacheStore,
    required AppLogger logger,
  }) : _gateway = gateway,
       _cacheStore = cacheStore,
       _logger = logger;

  static const _cacheKey = 'grades.snapshot.current';

  final SchoolPortalGateway _gateway;
  final JsonCacheStore _cacheStore;
  final AppLogger _logger;

  @override
  Future<Result<GradesSnapshot>> fetchGrades({
    required AppSession session,
    bool forceRefresh = false,
  }) async {
    final remote = await _gateway.fetchGrades(session);
    if (remote case Success<GradesSnapshot>(data: final snapshot)) {
      await _cacheStore.writeMap(_cacheKey, snapshot.toJson());
      return Success(snapshot);
    }

    final cached = await _cacheStore.readMap(_cacheKey);
    if (cached != null) {
      _logger.warn('Falling back to cached grades data.');
      return Success(
        GradesSnapshot.fromJson(cached).copyWith(origin: DataOrigin.cache),
      );
    }

    return FailureResult(remote.failureOrNull!);
  }
}
