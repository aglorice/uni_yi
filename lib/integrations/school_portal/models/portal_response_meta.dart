class PortalResponseMeta {
  const PortalResponseMeta({
    required this.endpoint,
    required this.fetchedAt,
    required this.isFixture,
  });

  final String endpoint;
  final DateTime fetchedAt;
  final bool isFixture;
}
