import 'gym_booking_overview.dart';

class GymRecommendationItem {
  const GymRecommendationItem({required this.venue, required this.slots});

  final Venue venue;
  final List<BookableSlot> slots;

  Map<String, dynamic> toJson() => {
    'venue': venue.toJson(),
    'slots': slots.map((item) => item.toJson()).toList(),
  };

  factory GymRecommendationItem.fromJson(Map<String, dynamic> json) {
    return GymRecommendationItem(
      venue: Venue.fromJson(json['venue'] as Map<String, dynamic>),
      slots: (json['slots'] as List<dynamic>? ?? const [])
          .map((item) => BookableSlot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GymRecommendationSnapshot {
  const GymRecommendationSnapshot({
    required this.date,
    required this.items,
    required this.preferenceSummary,
    this.fetchedAt,
  });

  final DateTime date;
  final List<GymRecommendationItem> items;
  final String preferenceSummary;
  final DateTime? fetchedAt;

  bool get isEmpty => items.isEmpty;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'preferenceSummary': preferenceSummary,
    'fetchedAt': fetchedAt?.toIso8601String(),
  };

  factory GymRecommendationSnapshot.fromJson(Map<String, dynamic> json) {
    return GymRecommendationSnapshot(
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                GymRecommendationItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      preferenceSummary: json['preferenceSummary'] as String? ?? '',
      fetchedAt: switch (json['fetchedAt']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      },
    );
  }
}
