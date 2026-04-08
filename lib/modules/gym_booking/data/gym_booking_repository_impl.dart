import '../../../core/logging/app_logger.dart';
import '../../../core/models/data_origin.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../../integrations/school_portal/school_portal_gateway.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/gym_booking_overview.dart';
import '../domain/repositories/gym_booking_repository.dart';

class GymBookingRepositoryImpl implements GymBookingRepository {
  const GymBookingRepositoryImpl({
    required SchoolPortalGateway gateway,
    required JsonCacheStore cacheStore,
    required AppLogger logger,
  }) : _gateway = gateway,
       _cacheStore = cacheStore,
       _logger = logger;

  final SchoolPortalGateway _gateway;
  final JsonCacheStore _cacheStore;
  final AppLogger _logger;

  String _cacheKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return 'gym.overview.${normalized.toIso8601String()}';
  }

  @override
  Future<Result<GymBookingOverview>> fetchOverview({
    required AppSession session,
    required DateTime date,
    bool forceRefresh = false,
  }) async {
    final remote = await _gateway.fetchGymBookingOverview(session, date: date);

    if (remote case Success<GymBookingOverview>(data: final overview)) {
      await _cacheStore.writeMap(_cacheKey(date), overview.toJson());
      return Success(overview);
    }

    final cached = await _cacheStore.readMap(_cacheKey(date));
    if (cached != null) {
      _logger.warn('Falling back to cached gym booking overview.');
      return Success(
        GymBookingOverview.fromJson(cached).copyWith(origin: DataOrigin.cache),
      );
    }

    return FailureResult(remote.failureOrNull!);
  }

  @override
  Future<Result<BookingRecord>> submitBooking({
    required AppSession session,
    required BookingDraft draft,
  }) async {
    final result = await _gateway.submitGymBooking(session, draft: draft);

    if (result case Success<BookingRecord>(data: final record)) {
      final cacheKey = _cacheKey(draft.date);
      final cached = await _cacheStore.readMap(cacheKey);
      if (cached != null) {
        final overview = GymBookingOverview.fromJson(cached);
        final updatedSlots = <String, List<BookableSlot>>{
          for (final entry in overview.slotsByVenue.entries)
            entry.key: entry.value
                .map(
                  (slot) => slot.id == draft.slot.id
                      ? slot.copyWith(remaining: slot.remaining - 1)
                      : slot,
                )
                .toList(),
        };

        final updated = overview.copyWith(
          slotsByVenue: updatedSlots,
          records: [record, ...overview.records],
          fetchedAt: DateTime.now(),
          origin: overview.origin,
        );

        await _cacheStore.writeMap(cacheKey, updated.toJson());
      }

      return Success(record);
    }

    return FailureResult(result.failureOrNull!);
  }
}
