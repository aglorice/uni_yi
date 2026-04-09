class VenueReview {
  const VenueReview({
    required this.id,
    required this.userName,
    required this.rating,
    this.content,
    this.createdAt,
  });

  final String id;
  final String userName;
  final double rating;
  final String? content;
  final DateTime? createdAt;
}

class VenueReviewPage {
  const VenueReviewPage({
    required this.reviews,
    required this.totalCount,
    this.pageNumber = 1,
    this.pageSize = 10,
  });

  final List<VenueReview> reviews;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  bool get hasMore => pageNumber * pageSize < totalCount;

  VenueReviewPage copyWith({
    List<VenueReview>? reviews,
    int? totalCount,
    int? pageNumber,
    int? pageSize,
  }) {
    return VenueReviewPage(
      reviews: reviews ?? this.reviews,
      totalCount: totalCount ?? this.totalCount,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
