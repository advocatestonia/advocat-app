// widgets/support/support_fab.dart
//
// Stripe-style help button: a small 48x48 round white pill in the bottom-
// right corner that opens a help drawer. Replaces the v3 edge-tab which
// owner rejected as "уродский, юзер не понимает что это help".
//
// Redesign rationale (2026-05-19, v4):
//   1. "USER CAN'T TELL IT'S HELP" — v4 uses a question-mark icon
//      (`help_outline`) on a CLEAN WHITE pill that reads as a help affordance
//      the moment the user looks at it. Tooltip says "Abi" / "Help" in the
//      current locale. No more abstract edge-tab.
//   2. "BLANK WHITE SHEET" — the actual sheet is rewritten in
//      `support_sheet.dart` to open with content already on screen (status
//      pill, search field, 5 FAQs, contact channels, footer). This FAB just
//      opens it.
//   3. "UGLY HOVER STATE" — hover ONLY brightens the background to #F8FAFC
//      and darkens the icon. We disable every Material default overlay
//      (splash/highlight/hover/focus) so the AnimatedContainer is the only
//      thing painting colour. No more translucent white splash on teal.
//
// Public API preserved so main.dart needs no changes:
//   * SupportFab            — the widget itself
//   * SupportFabBus         — singleton ChangeNotifier (hide/show/scroll)
//   * SupportFabVisibility  — InheritedWidget escape hatch
//   * kSupportTeal / kSupportTealDark — still exported for sheet & callers

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../l10n/app_localizations.dart';
import 'support_sheet.dart';

/// Brand-locked teal — reserved for primary product actions (Send button,
/// status accents, focus ring). The FAB itself is INTENTIONALLY neutral so
/// users don't confuse it with a primary CTA.
const Color kSupportTeal = Color(0xFF0D9488);
const Color kSupportTealDark = Color(0xFF0F766E);

/// Idle pill palette (Stripe-style: clean white, dark icon, soft border).
const Color _kIdleBg = Color(0xFFFFFFFF);
const Color _kHoverBg = Color(0xFFF8FAFC);
const Color _kPressBg = Color(0xFFE2E8F0);
const Color _kIdleIcon = Color(0xFF475569);
const Color _kHoverIcon = Color(0xFF0F172A);
const Color _kBorder = Color(0x140F172A); // rgba(15,23,42,0.08)

/// Routes on which the FAB must be completely hidden. The chat surface
/// owns its own bottom area (composer, attach, voice) and the FAB used to
/// steal taps there.
const List<String> _kHideOnRoutePrefixes = <String>['/chat/'];

/// Fixed 48dp round button — matches the spec exactly.
const double _kFabSize = 48.0;

/// Bottom/right offsets. Desktop = 24dp inset; mobile uses 16dp + safe-area
/// padding which is applied separately via SafeArea in main.dart.
const double _kDesktopInset = 24.0;
const double _kMobileInset = 16.0;
const double _kDesktopBreakpoint = 600.0;

/// Global visibility bus. Screens can call `kSupportFabBus.hide()` /
/// `.show()` from anywhere (e.g. when entering a checkout step or opening
/// the help sheet itself). They can also report scroll direction via
/// `notifyScroll(direction)` and the FAB will auto-hide on scroll-down,
/// auto-show on scroll-up / idle.
///
/// This is a singleton ChangeNotifier (not a Riverpod provider) because
/// legacy call-sites already hold the singleton ref — `main.dart`'s
/// NotificationListener wrapper pumps scroll events into it.
final SupportFabBus kSupportFabBus = SupportFabBus._();

class SupportFabBus extends ChangeNotifier {
  SupportFabBus._();

  /// External hide requests (screens calling .hide()/.show()).
  bool _externallyVisible = true;

  /// Scroll-driven visibility. True (visible) unless the user is currently
  /// scrolling downward beyond the 40px threshold.
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
  ///
  /// Per spec the FAB hides only when scrolling down > 40px; restore on any
  /// scroll-up. We approximate that with the direction (UserScrollNotification
  /// fires only after the threshold is crossed in practice).
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

/// Round help button. Mount in a Stack overlay above the
/// [MaterialApp.router] so it persists across every route.
///
/// The widget reads the current route via Riverpod's `routerProvider` and
/// hides itself when the active location starts with any entry in
/// [_kHideOnRoutePrefixes].
class SupportFab extends ConsumerStatefulWidget {
  const SupportFab({super.key, this.bottomOffset = 16.0});

  /// Kept for backward compatibility with main.dart. v4 computes the offset
  /// from MediaQuery (desktop vs mobile) so this value is now ignored, but
  /// the constructor signature stays so call-sites don't break.
  final double bottomOffset;

  @override
  ConsumerState<SupportFab> createState() => _SupportFabState();
}

class _SupportFabState extends ConsumerState<SupportFab>
    with TickerProviderStateMixin {
  /// Press-down scale (1.0 -> 0.96, 100ms).
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  /// Entry animation — 600ms fade+rise, runs once per session.
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entryOffset;

  /// Whether the entry animation has been played this session. We use a
  /// static field (not SharedPreferences) so it persists across navigation
  /// within the same app launch but resets on cold start — matches owner's
  /// "once per session" intent.
  static bool _entryPlayed = false;

  /// Hover state — drives the background recolour transition.
  bool _hovering = false;

  /// Press state — drives the scale + darker background.
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

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOut,
    );
    _entryOffset = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    if (_entryPlayed) {
      _entryCtrl.value = 1.0;
    } else {
      // Defer one frame so the first navigation render has settled.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _entryPlayed = true;
        _entryCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _detachRouteListener();
    _pressCtrl.dispose();
    _entryCtrl.dispose();
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
  /// widget rebuilds whenever the user navigates.
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
    final router = ref.watch(routerProvider);
    _ensureRouteListener(router);

    if (_shouldHideForRoute(router)) {
      // Hard hide on /chat/* — zero-sized so it cannot intercept taps.
      return const SizedBox.shrink();
    }

    // Combined visibility gate:
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
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: visible ? Offset.zero : const Offset(0, 0.4),
              child: _buildButton(context),
            ),
          ),
        );
      },
    );
  }

  /// Builds the round 48x48 help button.
  Widget _buildButton(BuildContext context) {
    final tooltip = _safeTooltip(context);
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= _kDesktopBreakpoint;
    final inset = isDesktop ? _kDesktopInset : _kMobileInset;

    // Idle / hover / press colours.
    final Color bgColor;
    final Color iconColor;
    if (_pressed) {
      bgColor = _kPressBg;
      iconColor = _kHoverIcon;
    } else if (_hovering) {
      bgColor = _kHoverBg;
      iconColor = _kHoverIcon;
    } else {
      bgColor = _kIdleBg;
      iconColor = _kIdleIcon;
    }

    return Padding(
      padding: EdgeInsets.only(right: inset, bottom: inset),
      child: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entryOffset,
          child: Semantics(
            label: tooltip,
            button: true,
            child: ScaleTransition(
              scale: _pressScale,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovering = true),
                onExit: (_) => setState(() => _hovering = false),
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: tooltip,
                  waitDuration: const Duration(milliseconds: 400),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: _kFabSize,
                    height: _kFabSize,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kBorder, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A), // rgba(15,23,42,0.08)
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
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
                        customBorder: const CircleBorder(),
                        // Kill EVERY Material default overlay — the colour
                        // is owned entirely by AnimatedContainer above.
                        // Without this, the InkWell paints a translucent
                        // white splash that owner called "ugly hover state".
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        // Teal focus ring per spec (a11y).
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? kSupportTeal.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.help_outline,
                            size: 22,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
    return 'Help';
  }

  void _openSheet(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= _kDesktopBreakpoint;

    // While the help sheet is open hide the FAB itself so we don't double-
    // up the help affordance on top of its own panel. Restored on close.
    kSupportFabBus.hide();

    if (isWide) {
      // Desktop: right-anchored 380px drawer with 30% scrim.
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withValues(alpha: 0.30),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (ctx, anim1, anim2) {
          return const Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: SizedBox(
                  width: 380,
                  height: double.infinity,
                  child: SupportSheet(asDrawer: true),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (ctx, anim, secondary, child) {
          final offset = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
          return SlideTransition(position: offset, child: child);
        },
      ).whenComplete(kSupportFabBus.show);
    } else {
      // Mobile: 85vh draggable bottom sheet.
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) {
          final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: const SupportSheet(asDrawer: false),
            ),
          );
        },
      ).whenComplete(kSupportFabBus.show);
    }
  }
}

// CONTRACT — coexistence with screen-level FABs and CTAs
// -----------------------------------------------------------------------------
// Several screens (cases list, deadlines, document list) render their own
// FloatingActionButton via Scaffold.floatingActionButton at the bottom-right.
// The new 48x48 help pill sits at 24dp inset on desktop / 16dp + safe-area
// on mobile. On screens where it would overlap a primary screen-level FAB,
// wrap the subtree in `SupportFabVisibility(visible: false, child: ...)`.
//
// Visibility gates (any one of these hides the FAB):
//   1. Current route starts with `/chat/` (hard-coded, see
//      `_kHideOnRoutePrefixes`). Owner asked for an absolute hide on the
//      AI assistant surface.
//   2. Keyboard is open (MediaQuery viewInsets.bottom > 0).
//   3. The current subtree contains `SupportFabVisibility(visible: false)`.
//   4. Any code called `kSupportFabBus.hide()` — pair with `.show()` on
//      dispose. (This is also used internally while the help sheet itself
//      is open so the FAB doesn't sit on top of its own drawer.)
//   5. The active scroll view reports `ScrollDirection.reverse` (scroll
//      down past the 40px threshold UserScrollNotification crosses).
//      Auto-restored on scroll up / idle, or by calling
//      `kSupportFabBus.resetScroll()` on route change.
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
