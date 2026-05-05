import 'package:flutter/material.dart';

/// Centers and constrains its [child] on wide viewports so the
/// mobile-first UI no longer stretches to 1440px on desktop with
/// empty gutters — but does NOT pin the entire app shell to a
/// 480px phone column on desktop either (that was the regression
/// shipped in 79ba32d on 2026-05-03).
///
/// When [maxWidth] is provided, that explicit cap wins (used by
/// form screens like login/register/onboarding/subscription where
/// 1200px-wide form fields look terrible).
///
/// When [maxWidth] is null, the cap becomes responsive based on
/// the available viewport width:
///   - viewport <  600px → no constraint (mobile, full-width)
///   - viewport <  1024px → 720px cap (tablet)
///   - viewport >= 1024px → 1200px cap (desktop)
///
/// This way the shell screens (Home/Cases/Deadlines/Settings) breathe
/// out on desktop instead of looking like a "tiny app stuck in the
/// middle of a wide page" while the bottom-nav goes full-width.
class MaxWidthWrapper extends StatelessWidget {
  const MaxWidthWrapper({
    super.key,
    required this.child,
    this.maxWidth,
  });

  /// Legacy default — exposed for tests and any caller that wants the
  /// historical 480px phone-column cap explicitly. New callers should
  /// either pass an explicit value (forms) or pass nothing and let the
  /// responsive default kick in (shell screens).
  static const double defaultMaxWidth = 480;

  /// Responsive breakpoints used when [maxWidth] is null.
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double tabletMaxWidth = 720;
  static const double desktopMaxWidth = 1200;

  final Widget child;

  /// Optional explicit cap. When null the cap becomes responsive
  /// (see class docs).
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final cap = maxWidth ?? _responsiveCap(viewportWidth);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: child,
          ),
        );
      },
    );
  }

  static double _responsiveCap(double viewportWidth) {
    if (viewportWidth < tabletBreakpoint) return double.infinity;
    if (viewportWidth < desktopBreakpoint) return tabletMaxWidth;
    return desktopMaxWidth;
  }
}
