import '../../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/campus_notice.dart';
import '../domain/repositories/notices_repository.dart';

class FetchNoticesUseCase {
  const FetchNoticesUseCase(this._repository);

  final NoticesRepository _repository;

  Future<Result<CampusNoticeSnapshot>> call({
    required AppSession session,
    bool forceRefresh = false,
  }) {
    return _repository.fetchSnapshot(
      session: session,
      forceRefresh: forceRefresh,
    );
  }
}
