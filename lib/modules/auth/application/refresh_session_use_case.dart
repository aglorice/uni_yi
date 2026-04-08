import '../../../core/result/result.dart';
import '../domain/entities/app_session.dart';
import '../domain/repositories/auth_repository.dart';

class RefreshSessionUseCase {
  const RefreshSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppSession>> call() => _repository.refreshSession();
}