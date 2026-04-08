import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_session.dart';
import '../entities/gym_booking_overview.dart';

abstract class GymBookingRepository {
  Future<Result<GymBookingOverview>> fetchOverview({
    required AppSession session,
    required DateTime date,
    bool forceRefresh = false,
  });

  Future<Result<BookingRecord>> submitBooking({
    required AppSession session,
    required BookingDraft draft,
  });
}
