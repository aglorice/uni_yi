import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/grades_snapshot.dart';

final gradesControllerProvider =
    AsyncNotifierProvider<GradesController, GradesSnapshot>(
      GradesController.new,
    );

class GradesController extends AsyncNotifier<GradesSnapshot> {
  @override
  Future<GradesSnapshot> build() async {
    return _load(forceRefresh: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<GradesSnapshot> _load({required bool forceRefresh}) async {
    final authState = await ref.watch(authControllerProvider.future);
    final session = authState.session;
    if (session == null) {
      throw const AuthenticationFailure('当前未登录，无法加载成绩。');
    }

    final result = await ref.read(fetchGradesUseCaseProvider)(
      session: session,
      forceRefresh: forceRefresh,
    );
    return result.requireValue();
  }
}
