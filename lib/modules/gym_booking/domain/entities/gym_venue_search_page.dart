import '../../../../core/models/data_origin.dart';
import 'gym_booking_overview.dart';

class GymVenueSearchQuery {
  const GymVenueSearchQuery({
    required this.date,
    this.pageNumber = 1,
    this.pageSize = 12,
    this.keyword = '',
    this.venueTypeId,
    this.venueTypeLabel,
    this.venueTypeBuilder,
    this.venueTypeBuilderList,
    this.sportId,
    this.sportLabel,
    this.sportBuilder,
    this.sportBuilderList,
    this.venueId,
  });

  final DateTime date;
  final int pageNumber;
  final int pageSize;
  final String keyword;
  final String? venueTypeId;
  final String? venueTypeLabel;
  final String? venueTypeBuilder;
  final String? venueTypeBuilderList;
  final String? sportId;
  final String? sportLabel;
  final String? sportBuilder;
  final String? sportBuilderList;
  final String? venueId;

  GymVenueSearchQuery copyWith({
    DateTime? date,
    int? pageNumber,
    int? pageSize,
    String? keyword,
    String? venueTypeId,
    String? venueTypeLabel,
    String? venueTypeBuilder,
    String? venueTypeBuilderList,
    String? sportId,
    String? sportLabel,
    String? sportBuilder,
    String? sportBuilderList,
    String? venueId,
    bool clearVenueTypeId = false,
    bool clearSportId = false,
    bool clearVenueId = false,
  }) {
    return GymVenueSearchQuery(
      date: date ?? this.date,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      keyword: keyword ?? this.keyword,
      venueTypeId: clearVenueTypeId ? null : (venueTypeId ?? this.venueTypeId),
      venueTypeLabel: clearVenueTypeId
          ? null
          : (venueTypeLabel ?? this.venueTypeLabel),
      venueTypeBuilder: clearVenueTypeId
          ? null
          : (venueTypeBuilder ?? this.venueTypeBuilder),
      venueTypeBuilderList: clearVenueTypeId
          ? null
          : (venueTypeBuilderList ?? this.venueTypeBuilderList),
      sportId: clearSportId ? null : (sportId ?? this.sportId),
      sportLabel: clearSportId ? null : (sportLabel ?? this.sportLabel),
      sportBuilder: clearSportId ? null : (sportBuilder ?? this.sportBuilder),
      sportBuilderList: clearSportId
          ? null
          : (sportBuilderList ?? this.sportBuilderList),
      venueId: clearVenueId ? null : (venueId ?? this.venueId),
    );
  }
}

class GymVenueSearchPage {
  const GymVenueSearchPage({
    required this.query,
    required this.venues,
    required this.slotsByVenue,
    required this.totalSize,
    required this.fetchedAt,
    required this.origin,
  });

  final GymVenueSearchQuery query;
  final List<Venue> venues;
  final Map<String, List<BookableSlot>> slotsByVenue;
  final int totalSize;
  final DateTime fetchedAt;
  final DataOrigin origin;

  bool get hasMore => query.pageNumber * query.pageSize < totalSize;

  int get totalSlotCount =>
      slotsByVenue.values.fold<int>(0, (sum, slots) => sum + slots.length);

  GymVenueSearchPage copyWith({
    GymVenueSearchQuery? query,
    List<Venue>? venues,
    Map<String, List<BookableSlot>>? slotsByVenue,
    int? totalSize,
    DateTime? fetchedAt,
    DataOrigin? origin,
  }) {
    return GymVenueSearchPage(
      query: query ?? this.query,
      venues: venues ?? this.venues,
      slotsByVenue: slotsByVenue ?? this.slotsByVenue,
      totalSize: totalSize ?? this.totalSize,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      origin: origin ?? this.origin,
    );
  }
}
