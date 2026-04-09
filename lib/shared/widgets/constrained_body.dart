import 'package:flutter/material.dart';

import '../../app/layout/breakpoints.dart';

/// Constrains its [child] to [AppBreakpoints.maxContentWidth] and centers it
/// on wide screens. On screens narrower than [AppBreakpoints.desktop], the
/// child is returned unchanged — no extra widgets are inserted.
class ConstrainedBody extends StatelessWidget {
  const ConstrainedBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.desktop) return child;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
