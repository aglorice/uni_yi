import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/gym_booking_overview.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final gymBookingControllerProvider =
    AsyncNotifierProvider<GymBookingController, GymBookingOverview>(
      GymBookingController.new,
    );

class GymBookingController extends AsyncNotifier<GymBookingOverview> {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _normalize(_selectedDate);

  @override
  Future<GymBookingOverview> build() async {
    _selectedDate = _normalize(DateTime.now());
    return _load(forceRefresh: false);
  }

  Future<Result<BookingRecord>> bookSlot({
    required Venue venue,
    required BookableSlot slot,
  }) async {
    final authState = await ref.read(authControllerProvider.future);
    final session = authState.session;
    if (session == null) {
      return const FailureResult(AuthenticationFailure('当前未登录，无法提交预约。'));
    }

    final result = await ref.read(submitGymBookingUseCaseProvider)(
      session: session,
      draft: BookingDraft(
        venue: venue,
        slot: slot,
        attendeeName: session.displayName,
        date: selectedDate,
      ),
    );

    if (result case Success<BookingRecord>(data: final record)) {
      final current = state.value;
      if (current != null) {
        final updatedSlots = <String, List<BookableSlot>>{
          for (final entry in current.slotsByVenue.entries)
            entry.key: entry.value
                .map(
                  (item) => item.id == slot.id
                      ? item.copyWith(remaining: item.remaining - 1)
                      : item,
                )
                .toList(),
        };

        state = AsyncData(
          current.copyWith(
            slotsByVenue: updatedSlots,
            records: [record, ...current.records],
            fetchedAt: DateTime.now(),
          ),
        );
      }
    }

    return result;
  }

  Future<void> changeDate(DateTime date) async {
    _selectedDate = _normalize(date);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<GymBookingOverview> _load({required bool forceRefresh}) async {
    final authState = await ref.watch(authControllerProvider.future);
    final session = authState.session;
    if (session == null) {
      throw const AuthenticationFailure('当前未登录，无法加载场馆预约。');
    }

    final result = await ref.read(fetchGymBookingOverviewUseCaseProvider)(
      session: session,
      date: selectedDate,
      forceRefresh: forceRefresh,
    );

    return result.requireValue();
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
