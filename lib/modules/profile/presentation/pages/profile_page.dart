import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../app/settings/app_preferences.dart';
import '../../../../app/settings/app_preferences_controller.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).value;
    final preferences = ref.watch(appPreferencesControllerProvider);
    final controller = ref.read(appPreferencesControllerProvider.notifier);
    final session = authState?.session;
    final rawDisplayName = session?.displayName.trim() ?? '';
    final displayName = rawDisplayName.isEmpty ? '未登录' : rawDisplayName;
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1) : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: [
        const SizedBox(height: 16),
        SurfaceCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session?.userId ?? '-'} · ${session?.profile?.deptName ?? '暂未同步院系'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: '外观主题',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: '深色主题',
                subtitle: '晚上或低亮度环境更耐看',
                value: preferences.darkMode,
                onChanged: controller.setDarkMode,
              ),
              const SizedBox(height: 8),
              _SettingSwitchTile(
                icon: Icons.contrast_outlined,
                title: '增强对比',
                subtitle: '让文字和边界更清楚',
                value: preferences.highContrast,
                onChanged: controller.setHighContrast,
              ),
              const SizedBox(height: 20),
              Text(
                '主题色',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final preset in AppThemePreset.values) ...[
                _ThemePresetTile(
                  preset: preset,
                  selected: preferences.themePreset == preset,
                  onTap: () => controller.setThemePreset(preset),
                ),
                if (preset != AppThemePreset.values.last)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '字体大小',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    preferences.fontScaleLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                value: preferences.fontScale,
                min: 0.9,
                max: 1.2,
                divisions: 6,
                label: preferences.fontScaleLabel,
                onChanged: controller.setFontScale,
              ),
              Text(
                '字体风格',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SegmentedButton<AppFontPreset>(
                multiSelectionEnabled: false,
                showSelectedIcon: false,
                segments: AppFontPreset.values
                    .map(
                      (preset) => ButtonSegment<AppFontPreset>(
                        value: preset,
                        label: Text(preset.label),
                      ),
                    )
                    .toList(),
                selected: {preferences.fontPreset},
                onSelectionChanged: (selection) {
                  controller.setFontPreset(selection.first);
                },
              ),
              const SizedBox(height: 10),
              Text(
                preferences.fontPreset.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: '首页布局',
          child: Column(
            children: [
              _SettingSwitchTile(
                icon: Icons.view_compact_alt_outlined,
                title: '紧凑布局',
                subtitle: '让页面更利落，信息密度更高',
                value: preferences.compactMode,
                onChanged: controller.setCompactMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: '课表显示',
          child: Column(
            children: [
              _SettingSwitchTile(
                icon: Icons.view_week_outlined,
                title: '显示周六周天',
                subtitle: '关闭后整周课表只显示周一到周五',
                value: preferences.showWeekends,
                onChanged: controller.setShowWeekends,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: '应用操作',
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.refresh_outlined,
                title: '重置外观偏好',
                subtitle: '恢复默认主题、字号和布局设置',
                onTap: () async {
                  await controller.reset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('外观偏好已恢复默认')));
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1),
              ),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                title: '清除业务缓存',
                subtitle: '删除课表、成绩、考试等本地缓存',
                onTap: () => _clearBusinessCache(context, ref),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1),
              ),
              _ActionTile(
                icon: Icons.info_outline_rounded,
                title: '关于应用',
                subtitle: '查看版本和应用说明',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.28),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('退出登录'),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/logo/pixel_cat_logo_1024.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '拾邑',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '五邑大学校园助手，一站式管理你的校园生活。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _AboutFeature(
                icon: Icons.calendar_today_rounded,
                label: '课表查询',
              ),
              const SizedBox(height: 10),
              _AboutFeature(
                icon: Icons.school_outlined,
                label: '成绩与考试',
              ),
              const SizedBox(height: 10),
              _AboutFeature(
                icon: Icons.bolt_rounded,
                label: '宿舍电量',
              ),
              const SizedBox(height: 10),
              _AboutFeature(
                icon: Icons.notifications_rounded,
                label: '校内通知',
              ),
              const SizedBox(height: 10),
              _AboutFeature(
                icon: Icons.grid_view_rounded,
                label: '校园服务',
              ),
              const SizedBox(height: 10),
              _AboutFeature(
                icon: Icons.sports_tennis_rounded,
                label: '体育馆预约',
              ),
              const SizedBox(height: 20),
              Text(
                '拾取校园点滴，邑你相伴同行。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearBusinessCache(BuildContext context, WidgetRef ref) async {
    final preferences = ref.read(sharedPreferencesProvider);
    final prefixes = [
      'schedule.snapshot.',
      'grades.snapshot.',
      'exams.snapshot.',
      'electricity.dashboard.',
      'gym.overview.',
    ];
    final keysToDelete = preferences
        .getKeys()
        .where((key) => prefixes.any((prefix) => key.startsWith(prefix)))
        .toList();

    for (final key in keysToDelete) {
      await preferences.remove(key);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(keysToDelete.isEmpty ? '当前没有可清除的业务缓存' : '业务缓存已清除'),
        ),
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.75)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: preset.seedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
