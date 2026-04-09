class VenueDetail {
  const VenueDetail({
    required this.id,
    required this.name,
    this.address,
    this.venueType,
    this.department,
    this.capacity = 0,
    this.maxAdvanceDays,
    this.openStatus,
    this.bookable,
    this.description,
  });

  final String id;
  final String name;
  final String? address;
  final String? venueType;
  final String? department;
  final int capacity;
  final int? maxAdvanceDays;
  final String? openStatus;
  final String? bookable;
  final String? description;
}
