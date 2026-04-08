import '../../../core/result/result.dart';
import '../../../modules/auth/domain/entities/app_session.dart';
import '../wyu_portal_api.dart';

class SessionValidator {
  const SessionValidator({required WyuPortalApi portalApi})
    : _portalApi = portalApi;

  final WyuPortalApi _portalApi;

  Future<Result<void>> validate(AppSession session) {
    return _portalApi.validateSession(session);
  }
}
