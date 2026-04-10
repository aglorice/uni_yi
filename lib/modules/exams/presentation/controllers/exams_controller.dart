import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/exam_schedule_snapshot.dart';

final examsControllerProvider =
    AsyncNotifierProvider<ExamsController, ExamScheduleSnapshot>(
      ExamsController.new,
    );

class ExamsController extends AsyncNotifier<ExamScheduleSnapshot> {
  @override
  Future<ExamScheduleSnapshot> build() async {
    return _load(forceRefresh: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<ExamScheduleSnapshot> _load({required bool forceRefresh}) async {
    final authState = await ref.watch(authControllerProvider.future);
    final session = authState.session;
    if (session == null) {
      throw const AuthenticationFailure('当前未登录，无法加载考试安排。');
    }

    final result = await ref.read(fetchExamScheduleUseCaseProvider)(
      session: session,
      termId: null,
      forceRefresh: forceRefresh,
    );

    return result.requireValue();
  }
}
