import '../../../core/result/result.dart';
import '../domain/entities/app_session.dart';
import '../domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppSession?>> call() {
    return _repository.restoreSession();
  }
}
