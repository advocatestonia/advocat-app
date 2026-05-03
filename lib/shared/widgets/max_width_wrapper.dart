import 'package:flutter/material.dart';

/// Centers and constrains its [child] to a phone-width column on wide
/// viewports, so the mobile-first UI no longer stretches to 1440px on
/// desktop with empty gutters.
///
/// This is a stop-gap until per-screen desktop layouts ship — the goal
/// is just to STOP the stretching, not to be a real desktop design.
///
/// On viewports narrower than [maxWidth] this widget is a no-op (it
/// just returns its child wrapped in a Center, which has zero visual
/// effect inside an already-tight constraint).
///
/// QA report 2026-05-03 flagged this as a P0 ship blocker:
/// "the same mobile UI stretches to 1440px wide, leaving ~150-200px
/// horizontal gaps between every quick-action tile."
class MaxWidthWrapper extends StatelessWidget {
  const MaxWidthWrapper({
    super.key,
    required this.child,
    this.maxWidth = defaultMaxWidth,
  });

  /// Default phone column width — slightly wider than a 390px iPhone
  /// viewport so the design has its natural breathing room without
  /// stretching tiles. Tuned to keep the home grid recognisable.
  static const double defaultMaxWidth = 480;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
