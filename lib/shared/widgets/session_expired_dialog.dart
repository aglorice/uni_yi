import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/presentation/controllers/auth_controller.dart';
import 'app_snackbar.dart';

enum _SessionExpiredAction { relogin, logout }

/// Shows a dialog when the school portal session has expired.
///
/// Offers two options:
/// - "重新登录": re-login using saved credentials
/// - "退出登录": clear session and go back to login page
Future<void> showSessionExpiredDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final action = await showDialog<_SessionExpiredAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.lock_outline,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('登录已过期'),
      content: const Text('学校门户登录态已失效。已为你保存了账号密码，是否重新登录？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _SessionExpiredAction.logout),
          child: const Text('退出登录'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _SessionExpiredAction.relogin),
          child: const Text('重新登录'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;

  switch (action) {
    case _SessionExpiredAction.relogin:
      final success = await ref.read(authControllerProvider.notifier).relogin();
      if (context.mounted && !success) {
        AppSnackBar.show(
          context,
          message: '重新登录失败，请检查网络或重新输入密码。',
          tone: AppSnackBarTone.error,
        );
      }
    case _SessionExpiredAction.logout:
      await ref.read(authControllerProvider.notifier).logout();
    case null:
      break;
  }
}
