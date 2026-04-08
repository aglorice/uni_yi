import '../../../core/result/result.dart';
import '../../../modules/auth/domain/entities/app_session.dart';
import '../../../modules/auth/domain/entities/school_credential.dart';
import '../wyu_portal_api.dart';

class SsoLoginOrchestrator {
  const SsoLoginOrchestrator({required WyuPortalApi portalApi})
    : _portalApi = portalApi;

  final WyuPortalApi _portalApi;

  Future<Result<AppSession>> login(SchoolCredential credential) {
    return _portalApi.login(credential);
  }
}
