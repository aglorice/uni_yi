class AppointmentDetail {
  const AppointmentDetail({
    required this.id,
    required this.venueName,
    required this.slotLabel,
    required this.date,
    required this.status,
    this.statusCode,
    this.address,
    this.attendeeName,
    this.phone,
    this.department,
    this.venueType,
    this.sportName,
    this.bookingType,
    this.attendeeCount,
    this.venueCode,
    this.businessWid,
    this.cancelReasonCode,
    this.cancelTime,
    this.rating,
    this.reviewContent,
    this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
    this.canCancel = false,
  });

  final String id;
  final String venueName;
  final String? address;
  final String slotLabel;
  final DateTime date;
  final String status;
  final String? statusCode;
  final String? attendeeName;
  final String? phone;
  final String? department;
  final String? venueType;
  final String? sportName;
  final String? bookingType;
  final String? attendeeCount;
  final String? venueCode;
  final String? businessWid;
  final String? cancelReasonCode;
  final String? cancelTime;
  final String? rating;
  final String? reviewContent;
  final String? checkInTime;
  final String? checkOutTime;
  final String? durationMinutes;
  final bool canCancel;
}
