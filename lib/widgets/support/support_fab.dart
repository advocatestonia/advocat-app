// widgets/support/support_fab.dart
//
// Edge-peek support tab anchored to the RIGHT edge of the viewport at the
// vertical centre of the bottom-third. Replaces the previous round teal disc
// in the bottom-right corner.
//
// Redesign rationale (2026-05-19, v3):
//   1. HOVER STILL LOOKED WHITE. v2 used a teal disc with a soft white tint
//      on hover; against the warm beige background that read as "still
//      white". v3 inverts the contrast: idle = warm beige edge-tab with a
//      thin border (looks like a recessed page tab), hover = saturated teal
//      with white text/icon. The colour change now clearly reads as
//      "active".
//   2. THE FAB BLOCKED THE CHAT. The round disc covered the send button and
//      message bubbles in `/chat/`. v3 hides the FAB entirely on any route
//      that starts with `/chat/` — chat surface is now FAB-free.
//   3. THE FAB OVERLAPPED CTAs. By moving to a 32px-wide edge tab anchored
//      flush to the right side at vertical-centre of the bottom-third, the
//      FAB no longer sits on top of pricing CTAs, hero buttons, or screen-
//      level FABs in the bottom-right corner.
//
// Public API preserved so main.dart needs no changes:
//   * SupportFab            — the widget itself
//   * SupportFabBus         — singleton ChangeNotifier (hide/show/scroll)
//   * SupportFabVisibility  — InheritedWidget escape hatch
//
// Removed in v3:
//   * One-time first-launch pulse animation (owner: "looks like it's
//     trying to steal navigation"). SharedPreferences dependency removed.
//   * Brand-tinted ink ripple — all Material default overlays are now
//     transparent; the AnimatedContainer alone drives the colour change.

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import 'support_sheet.dart';

/// Brand-locked teal used for the hover/press states of the support tab and
/// the in-app submit button.
const Color kSupportTeal = Color(0xFF0D9488);
const Color kSupportTealDark = Color(0xFF0F766E);

/// Routes on which the FAB must be completely hidden. The chat surface
/// owns its own bottom area (composer, attach, voice) and the FAB was
/// stealing taps there.
const List<String> _kHideOnRoutePrefixes = <String>['/chat/'];

/// Default-state dimensions (idle: collapsed edge tab).
const double _kIdleWidth = 32.0;
const double _kIdleHeight = 80.0;

/// Hover-state dimensions (web/desktop only — mobile doesn't hover).
const double _kHoverWidth = 120.0;
const double _kHoverHeight = 40.0;

/// Global visibility bus. Screens can call `kSupportFabBus.hide()` /
/// `.show()` from anywhere (e.g. when entering a checkout step). They can
/// also report scroll direction via `notifyScroll(direction)` and the FAB
/// will auto-hide on scroll-down, auto-show on scroll-up / idle.
///
/// This is intentionally a singleton ChangeNotifier (not a Riverpod
/// provider) because legacy call-sites already hold the singleton ref —
/// `main.dart`'s NotificationListener wrapper pumps scroll events into it.
final SupportFabBus kSupportFabBus = SupportFabBus._();

class SupportFabBus extends ChangeNotifier {
  SupportFabBus._();

  /// External hide requests (screens calling .hide()/.show()).
  bool _externallyVisible = true;

  /// Scroll-driven visibility. True (visible) unless the user is currently
  /// scrolling downward. We treat idle and scroll-up as visible.
  bool _scrollVisible = true;

  /// True when the FAB should render. Combines both signals.
  bool get visible => _externallyVisible && _scrollVisible;

  /// Hide the FAB from any screen. Pair with [show] in the matching
  /// `dispose`/`pop` callback to restore visibility.
  void hide() {
    if (!_externallyVisible) return;
    _externallyVisible = false;
    notifyListeners();
  }

  void show() {
    if (_externallyVisible) return;
    _externallyVisible = true;
    notifyListeners();
  }

  /// Report the latest scroll direction from a screen's scroll listener.
  /// Pass [ScrollDirection.reverse] when scrolling down (content moves up)
  /// and [ScrollDirection.forward] / [ScrollDirection.idle] otherwise.
  void notifyScroll(ScrollDirection direction) {
    final shouldShow = direction != ScrollDirection.reverse;
    if (shouldShow == _scrollVisible) return;
    _scrollVisible = shouldShow;
    notifyListeners();
  }

  /// Force-reset scroll visibility (called on route changes).
  void resetScroll() {
    if (_scrollVisible) return;
    _scrollVisible = true;
    notifyListeners();
  }
}

/// Edge-peek support tab. Mount in a Stack overlay above the
/// [MaterialApp.router] so it persists across every route.
///
/// The widget reads the current route via Riverpod's `routerProvider` and
/// hides itself when the active location starts with any entry in
/// [_kHideOnRoutePrefixes]. This is intentional rather than relying on
/// `GoRouterState.of(context)` because the FAB lives inside
/// `MaterialApp.builder`, where the `Router`/`InheritedGoRouter` may or
/// may not be an ancestor depending on Flutter framework internals — the
/// Riverpod path is rock-solid.
class SupportFab extends ConsumerStatefulWidget {
  const SupportFab({super.key, this.bottomOffset = 16.0});

  /// Kept for backward compatibility with main.dart. The new edge-peek
  /// positions itself at the vertical centre of the viewport bottom-third
  /// (computed from MediaQuery) and ignores this value, but we keep the
  /// constructor signature so call-sites don't break.
  final double bottomOffset;

  @override
  ConsumerState<SupportFab> createState() => _SupportFabState();
}

class _SupportFabState extends ConsumerState<SupportFab>
    with SingleTickerProviderStateMixin {
  /// Drives the press-down scale (1.0 -> 0.96, 100ms).
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  /// Hover state — drives the expand-and-recolour transition.
  bool _hovering = false;

  /// Press state — used to swap to the darker teal for tactile feedback.
  bool _pressed = false;

  /// Cached listener handle on the router's routeInformationProvider so we
  /// can detach in dispose() and trigger rebuilds on every route change.
  ValueListenable<RouteInformation>? _routeListenable;
  VoidCallback? _routeListener;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _detachRouteListener();
    _pressCtrl.dispose();
    super.dispose();
  }

  void _detachRouteListener() {
    if (_routeListenable != null && _routeListener != null) {
      _routeListenable!.removeListener(_routeListener!);
    }
    _routeListenable = null;
    _routeListener = null;
  }

  /// Subscribe to the current GoRouter's routeInformationProvider so the
  /// widget rebuilds whenever the user navigates. The provider is a
  /// `ValueListenable<RouteInformation>` exposed by the Router framework.
  void _ensureRouteListener(GoRouter router) {
    final listenable = router.routeInformationProvider;
    if (identical(_routeListenable, listenable)) return;
    _detachRouteListener();
    _routeListenable = listenable;
    _routeListener = () {
      if (!mounted) return;
      setState(() {}); // location changed -> re-evaluate visibility
    };
    listenable.addListener(_routeListener!);
  }

  bool _shouldHideForRoute(GoRouter router) {
    final loc = router.routeInformationProvider.value.uri.toString();
    for (final prefix in _kHideOnRoutePrefixes) {
      if (loc.startsWith(prefix)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the router via Riverpod and subscribe to its location stream.
    final router = ref.watch(routerProvider);
    _ensureRouteListener(router);

    if (_shouldHideForRoute(router)) {
      // Owner explicit ask: FAB MUST be invisible on /chat/* — return a
      // zero-sized box so it cannot intercept taps either.
      return const SizedBox.shrink();
    }

    // Combined visibility gate (everything-but-route):
    //   1. Keyboard open  -> hide (don't fight the IME).
    //   2. Inherited SupportFabVisibility(visible: false) -> hide.
    //   3. Global bus says hidden (scroll-down OR explicit .hide()) -> hide.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final inheritedVisible = SupportFabVisibility.of(context);

    return AnimatedBuilder(
      animation: kSupportFabBus,
      builder: (context, _) {
        final visible =
            !keyboardOpen && inheritedVisible && kSupportFabBus.visible;

        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: visible ? 1.0 : 0.0,
            // Slide IN from the right edge when hidden (matches the
            // edge-peek metaphor) instead of dropping down.
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: visible ? Offset.zero : const Offset(0.4, 0),
              child: _buildEdgeTab(context),
            ),
          ),
        );
      },
    );
  }

  /// Builds the peek-from-edge tab. Anchored to the right edge of the
  /// viewport at the vertical centre of the bottom-third — far away from
  /// the bottom-right corner where screen-level FABs and CTAs live.
  Widget _buildEdgeTab(BuildContext context) {
    final tooltip = _safeTooltip(context);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    // Vertical centre of the bottom third = viewport bottom +
    // (1/3 of viewport height) / 2 = viewport height / 6. We translate the
    // tab upward by that distance from the bottom edge that main.dart's
    // Positioned anchors us to.
    final bottomPadding = (viewportHeight / 6.0).clamp(80.0, 220.0);

    // Idle / hover dimensions and colours. Mobile devices never trigger
    // hover so the idle state is what they always see.
    final width = _hovering ? _kHoverWidth : _kIdleWidth;
    final height = _hovering ? _kHoverHeight : _kIdleHeight;

    // Idle: warm-beige surface variant with a thin border -> reads like a
    // recessed page tab against the F0EEEB background. Hover: saturated
    // brand teal. Press: deeper teal for tactile feedback.
    final Color bgColor;
    final Color fgColor;
    if (_pressed) {
      bgColor = kSupportTealDark;
      fgColor = Colors.white;
    } else if (_hovering) {
      bgColor = kSupportTeal;
      fgColor = Colors.white;
    } else {
      bgColor = AppColors.surfaceVariant;
      fgColor = kSupportTealDark;
    }

    // Half-rounded on the LEFT side only — the tab is flush against the
    // right viewport edge so the right corners stay square.
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Semantics(
        label: tooltip,
        button: true,
        child: ScaleTransition(
          scale: _pressScale,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadius,
                border: _hovering || _pressed
                    ? null
                    : Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: (_hovering || _pressed)
                        ? kSupportTealDark.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: (_hovering || _pressed) ? 12 : 4,
                    spreadRadius: 0,
                    offset: Offset(0, (_hovering || _pressed) ? 4 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _handleTap(context),
                  onTapDown: (_) {
                    _pressCtrl.forward();
                    setState(() => _pressed = true);
                  },
                  onTapCancel: () {
                    _pressCtrl.reverse();
                    setState(() => _pressed = false);
                  },
                  onTapUp: (_) {
                    _pressCtrl.reverse();
                    setState(() => _pressed = false);
                  },
                  borderRadius: borderRadius,
                  // Kill all Material default overlays — the colour shift
                  // is owned entirely by AnimatedContainer above. Without
                  // this, the InkWell paints a translucent white splash
                  // over our teal which is exactly the "still looks white"
                  // bug owner reported in v2.
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  child: Tooltip(
                    message: tooltip,
                    child: _buildContents(fgColor, tooltip),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Inner content swaps between icon-only (idle) and icon+label
  /// (hover/expanded). Uses AnimatedSwitcher so the label fades in
  /// smoothly without re-layout flicker.
  Widget _buildContents(Color fgColor, String label) {
    if (_hovering) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, size: 18, color: fgColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Icon(Icons.help_outline, size: 18, color: fgColor),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    unawaited(_pressCtrl.reverse());
    if (!context.mounted) return;
    _openSheet(context);
  }

  String _safeTooltip(BuildContext context) {
    // AppLocalizations.of can return null during the very first frames; in
    // that window the FAB falls back to English so we never crash a build.
    try {
      final loc = AppLocalizations.of(context);
      if (loc != null) return loc.supportTitle;
    } catch (_) {}
    return 'Need help?';
  }

  void _openSheet(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 600;
    if (isWide) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
            child: const SupportSheet(),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: const SupportSheet(),
        ),
      );
    }
  }
}

// CONTRACT — coexistence with screen-level FABs and CTAs
// -----------------------------------------------------------------------------
// Several screens (cases list, deadlines, document list) render their own
// FloatingActionButton via Scaffold.floatingActionButton at the bottom-right.
// The new edge-peek tab lives flush against the RIGHT viewport edge at the
// vertical centre of the bottom-third (computed via MediaQuery in
// `_buildEdgeTab`) so it physically cannot collide with screen-level FABs
// in the bottom-right corner anymore.
//
// Visibility gates (any one of these hides the FAB):
//   1. Current route starts with `/chat/` (hard-coded, see
//      `_kHideOnRoutePrefixes`). Owner asked for an absolute hide on the
//      AI assistant surface — the FAB used to cover the message composer.
//   2. Keyboard is open (MediaQuery viewInsets.bottom > 0).
//   3. The current subtree contains `SupportFabVisibility(visible: false)`.
//   4. Any code called `kSupportFabBus.hide()` — pair with `.show()` on
//      dispose.
//   5. The active scroll view reports `ScrollDirection.reverse` (scroll
//      down). Auto-restored on scroll up / idle, or by calling
//      `kSupportFabBus.resetScroll()` on route change.
//
// To hide the FAB from a single screen (preferred for static CTAs like
// "Book consultation"):
//
//     return SupportFabVisibility(
//       visible: false,
//       child: MyHireLawyerCta(),
//     );
//
// To wire scroll-aware hiding on a long list:
//
//     NotificationListener<UserScrollNotification>(
//       onNotification: (n) {
//         kSupportFabBus.notifyScroll(n.direction);
//         return false;
//       },
//       child: ListView(...),
//     );
// -----------------------------------------------------------------------------

/// Optional inherited widget that lets descendants hide the global support
/// FAB. Wrap any subtree (e.g. a CTA button) in
/// `SupportFabVisibility(visible: false, child: ...)` and the FAB will fade
/// out for that subtree.
class SupportFabVisibility extends InheritedWidget {
  const SupportFabVisibility({
    super.key,
    required this.visible,
    required super.child,
  });

  final bool visible;

  static bool of(BuildContext context) {
    final w = context
        .dependOnInheritedWidgetOfExactType<SupportFabVisibility>();
    return w?.visible ?? true;
  }

  @override
  bool updateShouldNotify(SupportFabVisibility oldWidget) =>
      oldWidget.visible != visible;
}
