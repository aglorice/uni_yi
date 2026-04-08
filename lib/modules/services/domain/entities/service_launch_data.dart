import '../../../auth/domain/entities/app_session.dart';

class ServiceLaunchData {
  const ServiceLaunchData({
    required this.initialUrl,
    required this.resolvedUrl,
    required this.cookies,
  });

  final String initialUrl;
  final String resolvedUrl;
  final List<PortalCookie> cookies;
}
