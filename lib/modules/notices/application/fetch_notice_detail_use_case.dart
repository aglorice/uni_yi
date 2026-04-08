import '../../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/campus_notice.dart';
import '../domain/repositories/notices_repository.dart';

class FetchNoticeDetailUseCase {
  const FetchNoticeDetailUseCase(this._repository);

  final NoticesRepository _repository;

  Future<Result<CampusNoticeDetail>> call({
    required AppSession session,
    required CampusNoticeItem item,
    bool forceRefresh = false,
  }) {
    return _repository.fetchDetail(
      session: session,
      item: item,
      forceRefresh: forceRefresh,
    );
  }
}
