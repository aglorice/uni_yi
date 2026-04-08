import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_session.dart';
import '../entities/campus_notice.dart';

abstract class NoticesRepository {
  Future<Result<CampusNoticeSnapshot>> fetchSnapshot({
    required AppSession session,
    bool forceRefresh = false,
  });

  Future<Result<CampusNoticeCategoryPage>> fetchCategoryPage({
    required AppSession session,
    required CampusNoticeCategory category,
    required Uri pageUri,
    bool forceRefresh = false,
  });

  Future<Result<CampusNoticeDetail>> fetchDetail({
    required AppSession session,
    required CampusNoticeItem item,
    bool forceRefresh = false,
  });
}
