import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/error_display.dart';
import '../../../../core/result/result.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../domain/entities/gym_booking_overview.dart';
import '../controllers/gym_booking_controller.dart';

class GymBookingPage extends ConsumerWidget {
  const GymBookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymAsync = ref.watch(gymBookingControllerProvider);
    final controller = ref.read(gymBookingControllerProvider.notifier);
    final selectedDate = controller.selectedDate;

    return AsyncValueView(
      value: gymAsync,
      onRetry: controller.refresh,
      loadingLabel: '场馆预约信息同步中',
      dataBuilder: (overview) => RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(4, (index) {
                final date = DateTime.now().add(Duration(days: index));
                final normalized = DateTime(date.year, date.month, date.day);
                final selected = normalized == selectedDate;

                return ChoiceChip(
                  label: Text(DateFormat('M/d E', 'zh_CN').format(normalized)),
                  selected: selected,
                  onSelected: (_) => controller.changeDate(normalized),
                );
              }),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预约规则',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(overview.rule.summary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final venue in overview.venues) ...[
              ...() {
                final slots =
                    overview.slotsByVenue[venue.id] ?? const <BookableSlot>[];
                return [
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(venue.location),
                        const SizedBox(height: 16),
                        for (final slot in slots) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${slot.startTime}-${slot.endTime}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '剩余 ${slot.remaining}/${slot.capacity} · ¥${slot.price.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: slot.isAvailable
                                    ? () => _confirmBooking(
                                        context: context,
                                        ref: ref,
                                        venue: venue,
                                        slot: slot,
                                      )
                                    : null,
                                child: Text(slot.isAvailable ? '预约' : '已满'),
                              ),
                            ],
                          ),
                          if (slot != slots.last) ...[
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ];
              }(),
            ],
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最近预约记录',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final record in overview.records) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.venueName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${record.slotLabel} · ${DateFormat('MM-dd').format(record.date.toLocal())}',
                              ),
                            ],
                          ),
                        ),
                        Text(record.status),
                      ],
                    ),
                    if (record != overview.records.last) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking({
    required BuildContext context,
    required WidgetRef ref,
    required Venue venue,
    required BookableSlot slot,
  }) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('确认预约'),
              content: Text(
                '确认预约 ${venue.name} ${slot.startTime}-${slot.endTime} 吗？提交动作会走统一认证链路。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('确认提交'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final result = await ref
        .read(gymBookingControllerProvider.notifier)
        .bookSlot(venue: venue, slot: slot);

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    switch (result) {
      case Success<BookingRecord>(data: final record):
        messenger.showSnackBar(
          SnackBar(
            content: Text('${record.venueName} ${record.slotLabel} 已提交'),
          ),
        );
      case FailureResult<BookingRecord>(failure: final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(formatError(failure).message)),
        );
    }
  }
}
