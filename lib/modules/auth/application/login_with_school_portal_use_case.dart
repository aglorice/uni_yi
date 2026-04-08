import '../../../core/result/result.dart';
import '../domain/entities/app_session.dart';
import '../domain/entities/school_credential.dart';
import '../domain/repositories/auth_repository.dart';

class LoginWithSchoolPortalUseCase {
  const LoginWithSchoolPortalUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppSession>> call(SchoolCredential credential) {
    return _repository.login(credential);
  }
}
