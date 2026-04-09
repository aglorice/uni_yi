import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/gym_booking_overview.dart';

Color gymStatusColor(BuildContext context, String? statusCode) {
  return switch (statusCode) {
    '001' => const Color(0xFFE8A838),
    '002' => const Color(0xFF5478A7),
    '003' => Theme.of(context).colorScheme.outline,
    _ => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}

class GymDateSelector extends StatelessWidget {
  const GymDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.dayCount = 7,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final days = List.generate(
      dayCount.clamp(1, 14),
      (index) => today.add(Duration(days: index)),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((date) {
          final normalized = DateTime(date.year, date.month, date.day);
          final selected =
              normalized ==
              DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '${date.month}/${date.day} ${DateFormat('EEE', 'zh_CN').format(date)}',
              ),
              selected: selected,
              onSelected: (_) => onDateChanged(normalized),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GymStatusBadge extends StatelessWidget {
  const GymStatusBadge({
    super.key,
    required this.label,
    required this.statusCode,
  });

  final String label;
  final String? statusCode;

  @override
  Widget build(BuildContext context) {
    final color = gymStatusColor(context, statusCode);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class GymAppointmentTile extends StatelessWidget {
  const GymAppointmentTile({super.key, required this.record, this.onTap});

  final BookingRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = gymStatusColor(context, record.statusCode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.venueName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MM-dd', 'zh_CN').format(record.date.toLocal())} · ${record.slotLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GymStatusBadge(label: record.status, statusCode: record.statusCode),
          ],
        ),
      ),
    );
  }
}

class GymSlotTile extends StatelessWidget {
  const GymSlotTile({
    super.key,
    required this.slot,
    required this.onBook,
    this.capacity,
    this.enabled = true,
  });

  final BookableSlot slot;
  final VoidCallback onBook;
  final int? capacity;
  final bool enabled;

  static const _accentColors = [
    Color(0xFF5B8DEF),
    Color(0xFF4CAF50),
    Color(0xFFE8A838),
    Color(0xFFE57373),
    Color(0xFF00ACC1),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor =
        _accentColors[slot.startTime.hashCode.abs() % _accentColors.length];
    final isBookable = enabled && slot.isAvailable;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: isBookable ? accentColor : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.timeLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  capacity != null && capacity! > 0
                      ? '建议使用人数不超过 $capacity 人'
                      : '该时段当前可预约',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: isBookable ? onBook : null,
            child: Text(isBookable ? '预约' : '暂不可约'),
          ),
        ],
      ),
    );
  }
}
