import '../../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/campus_notice.dart';
import '../domain/repositories/notices_repository.dart';

class FetchNoticeCategoryPageUseCase {
  const FetchNoticeCategoryPageUseCase(this._repository);

  final NoticesRepository _repository;

  Future<Result<CampusNoticeCategoryPage>> call({
    required AppSession session,
    required CampusNoticeCategory category,
    required Uri pageUri,
    bool forceRefresh = false,
  }) {
    return _repository.fetchCategoryPage(
      session: session,
      category: category,
      pageUri: pageUri,
      forceRefresh: forceRefresh,
    );
  }
}
