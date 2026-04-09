import 'package:flutter/material.dart';

enum AppSnackBarTone { info, success, error }

class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarTone tone = AppSnackBarTone.info,
    IconData? icon,
    Duration? duration,
    bool clearCurrent = true,
  }) {
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    if (clearCurrent) {
      messenger.hideCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        duration: duration ?? const Duration(seconds: 2),
        content: _AppSnackBarBody(message: message, tone: tone, icon: icon),
      ),
    );
  }
}

class _AppSnackBarBody extends StatelessWidget {
  const _AppSnackBarBody({
    required this.message,
    required this.tone,
    this.icon,
  });

  final String message;
  final AppSnackBarTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final toneColor = switch (tone) {
      AppSnackBarTone.info => colorScheme.primary,
      AppSnackBarTone.success => const Color(0xFF1C8C6E),
      AppSnackBarTone.error => colorScheme.error,
    };
    final surfaceColor = theme.brightness == Brightness.light
        ? Colors.white
        : colorScheme.surfaceContainerLow;
    final borderColor =
        Color.lerp(colorScheme.outlineVariant, toneColor, 0.28) ?? toneColor;
    final shadowColor = colorScheme.shadow.withValues(
      alpha: theme.brightness == Brightness.light ? 0.10 : 0.24,
    );

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon ?? _defaultIconForTone(tone),
                size: 18,
                color: toneColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _defaultIconForTone(AppSnackBarTone tone) {
    return switch (tone) {
      AppSnackBarTone.info => Icons.info_outline_rounded,
      AppSnackBarTone.success => Icons.check_circle_outline_rounded,
      AppSnackBarTone.error => Icons.error_outline_rounded,
    };
  }
}
