import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_session.dart';
import '../entities/exam_schedule_snapshot.dart';

abstract class ExamsRepository {
  Future<Result<ExamScheduleSnapshot>> fetchExamSchedule({
    required AppSession session,
    String? termId,
    bool forceRefresh = false,
  });
}
