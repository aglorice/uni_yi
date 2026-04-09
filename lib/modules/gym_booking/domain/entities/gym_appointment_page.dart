import '../../../../core/models/data_origin.dart';
import 'gym_booking_overview.dart';

class GymAppointmentQuery {
  const GymAppointmentQuery({
    this.pageNumber = 1,
    this.pageSize = 12,
    this.keyword = '',
    this.statusCode,
  });

  final int pageNumber;
  final int pageSize;
  final String keyword;
  final String? statusCode;

  GymAppointmentQuery copyWith({
    int? pageNumber,
    int? pageSize,
    String? keyword,
    String? statusCode,
    bool clearStatusCode = false,
  }) {
    return GymAppointmentQuery(
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      keyword: keyword ?? this.keyword,
      statusCode: clearStatusCode ? null : (statusCode ?? this.statusCode),
    );
  }
}

class GymAppointmentPage {
  const GymAppointmentPage({
    required this.query,
    required this.records,
    required this.totalSize,
    required this.fetchedAt,
    required this.origin,
  });

  final GymAppointmentQuery query;
  final List<BookingRecord> records;
  final int totalSize;
  final DateTime fetchedAt;
  final DataOrigin origin;

  bool get hasMore => query.pageNumber * query.pageSize < totalSize;

  GymAppointmentPage copyWith({
    GymAppointmentQuery? query,
    List<BookingRecord>? records,
    int? totalSize,
    DateTime? fetchedAt,
    DataOrigin? origin,
  }) {
    return GymAppointmentPage(
      query: query ?? this.query,
      records: records ?? this.records,
      totalSize: totalSize ?? this.totalSize,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      origin: origin ?? this.origin,
    );
  }
}
