import '../../../../core/result/result.dart';
import '../entities/app_session.dart';
import '../entities/school_credential.dart';

abstract class AuthRepository {
  Future<Result<AppSession>> login(SchoolCredential credential);
  Future<Result<AppSession?>> restoreSession();
  Future<Result<AppSession>> refreshSession();
  Future<void> logout();
}
