import 'portal_response_meta.dart';

class PortalDocument {
  const PortalDocument({required this.rawBody, required this.meta});

  final String rawBody;
  final PortalResponseMeta meta;
}
