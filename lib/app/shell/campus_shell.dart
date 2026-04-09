import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/failure.dart';
import '../../modules/auth/presentation/controllers/auth_controller.dart';
import '../../modules/electricity/presentation/controllers/electricity_controller.dart';
import '../../modules/schedule/presentation/controllers/schedule_controller.dart';
import '../layout/breakpoints.dart';
import '../../shared/widgets/constrained_body.dart';
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
  bool _desktopRailExpanded = true;

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
    if (authAsync.isLoading) {
      return const Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppBreakpoints.rail;
    final isDesktop = width >= AppBreakpoints.desktop;
    final railExpanded = isDesktop && _desktopRailExpanded;

    if (useRail) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  );
                },
                extended: railExpanded,
                minWidth: 72,
                minExtendedWidth: 196,
                leading: isDesktop
                    ? _DesktopRailHeader(
                        expanded: railExpanded,
                        onToggle: () {
                          setState(() {
                            _desktopRailExpanded = !_desktopRailExpanded;
                          });
                        },
                      )
                    : null,
                labelType: isDesktop
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: ConstrainedBody(child: widget.navigationShell)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: widget.navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
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

class _DesktopRailHeader extends StatelessWidget {
  const _DesktopRailHeader({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: expanded
          ? Padding(
              key: const ValueKey('expanded'),
              padding: const EdgeInsets.fromLTRB(14, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '拾邑',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RailToggleButton(expanded: true, onPressed: onToggle),
                ],
              ),
            )
          : Padding(
              key: const ValueKey('collapsed'),
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RailToggleButton(expanded: false, onPressed: onToggle),
                ],
              ),
            ),
    );
  }
}

class _RailToggleButton extends StatelessWidget {
  const _RailToggleButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: expanded ? '收起导航' : '展开导航',
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              expanded
                  ? Icons.keyboard_double_arrow_left_rounded
                  : Icons.keyboard_double_arrow_right_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
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
