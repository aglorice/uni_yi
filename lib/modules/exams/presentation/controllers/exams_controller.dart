import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/models/data_origin.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/exam_schedule_snapshot.dart';
import '../../../schedule/domain/entities/schedule_snapshot.dart';

final examsControllerProvider =
    AsyncNotifierProvider<ExamsController, ExamScheduleSnapshot>(
      ExamsController.new,
    );

class ExamsController extends AsyncNotifier<ExamScheduleSnapshot> {
  String? _selectedTermId;

  @override
  Future<ExamScheduleSnapshot> build() async {
    return _load(forceRefresh: false);
  }

  Future<void> changeTerm(String termId) async {
    if (_selectedTermId == termId && state.value != null) {
      return;
    }
    final previousSnapshot = state.value;
    _selectedTermId = termId;
    state = const AsyncLoading();
    final newState = await AsyncValue.guard(() => _load(forceRefresh: true));
    if (newState is AsyncError && previousSnapshot != null) {
      final term = previousSnapshot.availableTerms.firstWhere(
        (t) => t.id == termId,
        orElse: () => Term(id: termId, name: termId),
      );
      state = AsyncData(
        ExamScheduleSnapshot(
          term: term,
          availableTerms: previousSnapshot.availableTerms,
          records: [],
          fetchedAt: DateTime.now(),
          origin: DataOrigin.remote,
        ),
      );
    } else {
      state = newState;
    }
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
      termId: _selectedTermId,
      forceRefresh: forceRefresh,
    );

    final snapshot = result.requireValue();
    _selectedTermId = snapshot.term.id;
    return snapshot;
  }
}
