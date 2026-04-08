import '../../../../core/models/data_origin.dart';

class Venue {
  const Venue({required this.id, required this.name, required this.location});

  final String id;
  final String name;
  final String location;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
  };

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
    );
  }
}

class BookableSlot {
  const BookableSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.remaining,
    required this.price,
  });

  final String id;
  final String startTime;
  final String endTime;
  final int capacity;
  final int remaining;
  final double price;

  bool get isAvailable => remaining > 0;

  BookableSlot copyWith({int? remaining}) {
    return BookableSlot(
      id: id,
      startTime: startTime,
      endTime: endTime,
      capacity: capacity,
      remaining: remaining ?? this.remaining,
      price: price,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime,
    'endTime': endTime,
    'capacity': capacity,
    'remaining': remaining,
    'price': price,
  };

  factory BookableSlot.fromJson(Map<String, dynamic> json) {
    return BookableSlot(
      id: json['id'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      capacity: json['capacity'] as int,
      remaining: json['remaining'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class BookingRule {
  const BookingRule({
    required this.summary,
    required this.advanceWindowDays,
    required this.supportsSameDay,
  });

  final String summary;
  final int advanceWindowDays;
  final bool supportsSameDay;

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'advanceWindowDays': advanceWindowDays,
    'supportsSameDay': supportsSameDay,
  };

  factory BookingRule.fromJson(Map<String, dynamic> json) {
    return BookingRule(
      summary: json['summary'] as String,
      advanceWindowDays: json['advanceWindowDays'] as int,
      supportsSameDay: json['supportsSameDay'] as bool,
    );
  }
}

class BookingDraft {
  const BookingDraft({
    required this.venue,
    required this.slot,
    required this.attendeeName,
    required this.date,
  });

  final Venue venue;
  final BookableSlot slot;
  final String attendeeName;
  final DateTime date;
}

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.venueName,
    required this.slotLabel,
    required this.date,
    required this.status,
  });

  final String id;
  final String venueName;
  final String slotLabel;
  final DateTime date;
  final String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'venueName': venueName,
    'slotLabel': slotLabel,
    'date': date.toIso8601String(),
    'status': status,
  };

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    return BookingRecord(
      id: json['id'] as String,
      venueName: json['venueName'] as String,
      slotLabel: json['slotLabel'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
    );
  }
}

class GymBookingOverview {
  const GymBookingOverview({
    required this.date,
    required this.venues,
    required this.slotsByVenue,
    required this.rule,
    required this.records,
    required this.fetchedAt,
    required this.origin,
  });

  final DateTime date;
  final List<Venue> venues;
  final Map<String, List<BookableSlot>> slotsByVenue;
  final BookingRule rule;
  final List<BookingRecord> records;
  final DateTime fetchedAt;
  final DataOrigin origin;

  GymBookingOverview copyWith({
    DateTime? date,
    List<Venue>? venues,
    Map<String, List<BookableSlot>>? slotsByVenue,
    BookingRule? rule,
    List<BookingRecord>? records,
    DateTime? fetchedAt,
    DataOrigin? origin,
  }) {
    return GymBookingOverview(
      date: date ?? this.date,
      venues: venues ?? this.venues,
      slotsByVenue: slotsByVenue ?? this.slotsByVenue,
      rule: rule ?? this.rule,
      records: records ?? this.records,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      origin: origin ?? this.origin,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'venues': venues.map((venue) => venue.toJson()).toList(),
    'slotsByVenue': slotsByVenue.map(
      (key, value) =>
          MapEntry(key, value.map((slot) => slot.toJson()).toList()),
    ),
    'rule': rule.toJson(),
    'records': records.map((record) => record.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'origin': origin.name,
  };

  factory GymBookingOverview.fromJson(Map<String, dynamic> json) {
    final slotsRaw = json['slotsByVenue'] as Map<String, dynamic>;

    return GymBookingOverview(
      date: DateTime.parse(json['date'] as String),
      venues: (json['venues'] as List<dynamic>)
          .map((item) => Venue.fromJson(item as Map<String, dynamic>))
          .toList(),
      slotsByVenue: slotsRaw.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map(
                (item) => BookableSlot.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
        ),
      ),
      rule: BookingRule.fromJson(json['rule'] as Map<String, dynamic>),
      records: (json['records'] as List<dynamic>)
          .map((item) => BookingRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      origin: DataOrigin.values.byName(json['origin'] as String),
    );
  }
}
