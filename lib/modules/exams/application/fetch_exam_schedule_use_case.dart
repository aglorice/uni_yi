import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/exam_schedule_snapshot.dart';
import '../domain/repositories/exams_repository.dart';

class FetchExamScheduleUseCase {
  const FetchExamScheduleUseCase(this._repository);

  final ExamsRepository _repository;

  Future<Result<ExamScheduleSnapshot>> call({
    required AppSession session,
    String? termId,
    bool forceRefresh = false,
  }) {
    return _repository.fetchExamSchedule(
      session: session,
      termId: termId,
      forceRefresh: forceRefresh,
    );
  }
}
