import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/failure.dart';
import '../../modules/auth/presentation/controllers/auth_controller.dart';
import '../../modules/electricity/presentation/controllers/electricity_controller.dart';
import '../../modules/schedule/presentation/controllers/schedule_controller.dart';
import '../../shared/widgets/session_expired_dialog.dart';

Widget buildCampusShellNavigatorContainer(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  return _AnimatedBranchNavigatorContainer(
    currentIndex: navigationShell.currentIndex,
    children: children,
  );
}

class CampusShell extends ConsumerStatefulWidget {
  const CampusShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<CampusShell> createState() => _CampusShellState();
}

class _CampusShellState extends ConsumerState<CampusShell> {
  bool _sessionDialogShown = false;

  static const _destinations = [
    _CampusDestination(
      label: '总览',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _CampusDestination(
      label: '课表',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
    ),
    _CampusDestination(
      label: '通知',
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
    ),
    _CampusDestination(
      label: '设置',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
    ),
  ];

  void _onSessionExpired() {
    if (_sessionDialogShown || !mounted) return;
    _sessionDialogShown = true;
    showSessionExpiredDialog(context, ref).whenComplete(() {
      _sessionDialogShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scheduleControllerProvider, (_, next) {
      if (next.hasError && next.error is SessionExpiredFailure) {
        _onSessionExpired();
      }
    });
    ref.listen(electricityControllerProvider, (_, next) {
      if (next.hasError && next.error is SessionExpiredFailure) {
        _onSessionExpired();
      }
    });

    final authAsync = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: authAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : widget.navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: _ShellNavigationBar(
          destinations: _destinations,
          currentIndex: widget.navigationShell.currentIndex,
          onSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class _CampusDestination {
  const _CampusDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<_CampusDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _ShellNavigationItem(
                  destination: destinations[index],
                  selected: index == currentIndex,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShellNavigationItem extends StatelessWidget {
  const _ShellNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _CampusDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.38)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: selected ? 42 : 36,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 20,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style:
                    theme.textTheme.labelSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: selected ? 0.15 : 0.05,
                    ) ??
                    const TextStyle(),
                child: Text(destination.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBranchNavigatorContainer extends StatefulWidget {
  const _AnimatedBranchNavigatorContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<_AnimatedBranchNavigatorContainer> createState() =>
      _AnimatedBranchNavigatorContainerState();
}

class _AnimatedBranchNavigatorContainerState
    extends State<_AnimatedBranchNavigatorContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..value = 1;

  late int _previousIndex = widget.currentIndex;

  @override
  void didUpdateWidget(covariant _AnimatedBranchNavigatorContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) {
      return;
    }

    _previousIndex = oldWidget.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;

          return ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final index in _visibleIndexes())
                  if (_shouldKeepMounted(index))
                    _buildBranch(
                      index: index,
                      child: widget.children[index],
                      progress: progress,
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _shouldKeepMounted(int index) {
    if (index == widget.currentIndex) {
      return true;
    }
    return _controller.isAnimating && index == _previousIndex;
  }

  List<int> _visibleIndexes() {
    final indexes = <int>[];
    if (_controller.isAnimating && _previousIndex != widget.currentIndex) {
      indexes.add(_previousIndex);
    }
    indexes.add(widget.currentIndex);
    return indexes;
  }

  Widget _buildBranch({
    required int index,
    required Widget child,
    required double progress,
  }) {
    final isCurrent = index == widget.currentIndex;
    final isPrevious = _controller.isAnimating && index == _previousIndex;

    final outgoingProgress = Curves.easeOutCubic.transform(
      Interval(0, 0.35).transform(progress),
    );
    final incomingProgress = Curves.easeOutCubic.transform(
      Interval(0.22, 1).transform(progress),
    );

    final opacity = switch ((isCurrent, isPrevious, _controller.isAnimating)) {
      (true, _, true) => incomingProgress,
      (_, true, true) => 1 - outgoingProgress,
      (true, _, false) => 1.0,
      _ => 0.0,
    };

    final scale = switch ((isCurrent, isPrevious, _controller.isAnimating)) {
      (true, _, true) => 0.96 + 0.04 * incomingProgress,
      (_, true, true) => 1.0,
      _ => 1.0,
    };

    return IgnorePointer(
      ignoring: !isCurrent,
      child: TickerMode(
        enabled: isCurrent || isPrevious,
        child: RepaintBoundary(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Opacity(opacity: opacity, child: child),
          ),
        ),
      ),
    );
  }
}
