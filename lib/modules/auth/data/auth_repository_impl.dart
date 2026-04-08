import '../../../core/error/failure.dart';
import '../../../core/result/result.dart';
import '../../../integrations/school_portal/school_portal_gateway.dart';
import '../domain/entities/app_session.dart';
import '../domain/entities/school_credential.dart';
import '../domain/repositories/auth_repository.dart';
import 'credential_vault.dart';
import 'session_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required SchoolPortalGateway gateway,
    required CredentialVault credentialVault,
    required SessionStore sessionStore,
  }) : _gateway = gateway,
       _credentialVault = credentialVault,
       _sessionStore = sessionStore;

  final SchoolPortalGateway _gateway;
  final CredentialVault _credentialVault;
  final SessionStore _sessionStore;

  @override
  Future<Result<AppSession>> login(SchoolCredential credential) async {
    final result = await _gateway.login(credential);
    if (result case Success<AppSession>(data: final session)) {
      await _credentialVault.save(credential);
      await _sessionStore.save(session);
      return Success(session);
    }

    return FailureResult(result.failureOrNull!);
  }

  @override
  Future<void> logout() async {
    await _credentialVault.clear();
    await _sessionStore.clear();
  }

  @override
  Future<Result<AppSession>> refreshSession() async {
    final credential = await _credentialVault.read();
    if (credential == null) {
      return const FailureResult(AuthenticationFailure('未找到已保存的登录凭证。'));
    }

    final refreshed = await _gateway.refreshSession(credential);
    if (refreshed case Success<AppSession>(data: final session)) {
      await _sessionStore.save(session);
      return Success(session);
    }

    await _sessionStore.clear();
    return FailureResult(refreshed.failureOrNull!);
  }

  @override
  Future<Result<AppSession?>> restoreSession() async {
    final existing = await _sessionStore.read();
    if (existing == null) {
      return const Success(null);
    }

    final validation = await _gateway.validateSession(existing);
    if (validation.isSuccess) {
      return Success(existing);
    }

    final refreshed = await refreshSession();
    if (refreshed case Success<AppSession>(data: final session)) {
      return Success(session);
    }

    return FailureResult(refreshed.failureOrNull!);
  }
}
