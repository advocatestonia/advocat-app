// widgets/support/support_fab.dart
//
// Floating "Need help?" button anchored to the bottom-right corner of the
// app and visible on every route (landing, auth, chat, settings).
//
// Redesign (2026-05-19) — three problems fixed:
//   1. UGLY HOVER. The default Material InkWell painted a translucent WHITE
//      splash/highlight on top of our teal disc, producing a "white-on-white"
//      flash. We now pass brand-tinted overlay colours (darker teal) so the
//      hover/press states deepen the teal rather than wash it out.
//   2. CTA OVERLAP. The FAB used to sit on top of primary CTA buttons on
//      narrow screens (hire-a-lawyer, book-consultation). It now hides:
//        - whenever the keyboard is open (MediaQuery viewInsets),
//        - whenever a screen wraps its CTA in `SupportFabVisibility(visible: false)`,
//        - whenever a screen pushes a hide on the global [kSupportFabBus]
//          (used by long scrollable views — see `notifyScroll` below),
//        - whenever the user is scrolling DOWN (reading) — auto-revealed on
//          scroll UP or idle.
//   3. GENERIC / LOUD. Smaller footprint (48x48, icon 24), softer brand
//      shadow that lifts on hover, subtle scale-on-press, optional one-time
//      pulse on the very first launch.
//
// We deliberately keep this widget dependency-light. It's mounted in
// main.dart inside a Stack overlay so it survives every navigation in the
// router. Screen-level FABs (chat send, "New case", etc.) stay untouched.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'support_sheet.dart';

/// Brand-locked teal used for the support FAB and the in-app submit button.
const Color kSupportTeal = Color(0xFF0D9488);
const Color kSupportTealDark = Color(0xFF0F766E);

/// Global visibility bus. Screens can call `kSupportFabBus.hide()` /
/// `.show()` from anywhere (e.g. when entering a checkout step). They can
/// also report scroll direction via `notifyScroll(direction)` and the FAB
/// will auto-hide on scroll-down, auto-show on scroll-up / idle.
///
/// This is intentionally a singleton ChangeNotifier (not a Riverpod
/// provider) because the FAB lives outside the ProviderScope subtree in
/// main.dart's MaterialApp.builder — it would not be able to read a
/// provider from there without extra plumbing.
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

/// SharedPreferences key — set to `true` the first time the user taps the
/// FAB. While unset, the FAB plays a one-time gentle pulse to signal "I'm
/// here". Skipped entirely if SharedPreferences is unavailable.
const String _kFabSeenPrefKey = 'support_fab_seen';

/// Bottom-right floating help button. Mount in a Stack overlay above the
/// [MaterialApp.router] so it persists across every route.
class SupportFab extends StatefulWidget {
  const SupportFab({super.key, this.bottomOffset = 16.0});

  /// Distance from the bottom edge in dp. Default 16 sits above the system
  /// home-indicator on iOS web/PWA. Screens that own a bottom nav bar
  /// should pass `bottomOffset: 88` (or wrap the fab in their own Padding).
  final double bottomOffset;

  @override
  State<SupportFab> createState() => _SupportFabState();
}

class _SupportFabState extends State<SupportFab>
    with TickerProviderStateMixin {
  /// Drives the press-down scale (1.0 → 0.92, 100ms).
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  /// Drives the gentle one-time "I'm here" pulse on first launch
  /// (1.0 → 1.06 → 1.0, period 1.2s, capped at 15s of total runtime).
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  /// Hover state — drives elevation 6 → 10 and the soft white tint.
  bool _hovering = false;

  /// Resolved once after `initState`. While null, the pulse is disabled.
  bool _shouldPulse = false;
  Timer? _pulseStopTimer;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseCtrl);

    _maybeStartPulse();
  }

  Future<void> _maybeStartPulse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kFabSeenPrefKey) ?? false) return;
      if (!mounted) return;
      setState(() => _shouldPulse = true);
      unawaited(_pulseCtrl.repeat());
      // Stop pulsing after 15s regardless of whether the user taps.
      _pulseStopTimer = Timer(const Duration(seconds: 15), _stopPulse);
    } catch (_) {
      // SharedPreferences unavailable (e.g. headless test) — skip pulse.
    }
  }

  void _stopPulse() {
    _pulseStopTimer?.cancel();
    _pulseStopTimer = null;
    if (!_pulseCtrl.isAnimating) return;
    _pulseCtrl.stop();
    _pulseCtrl.value = 0.0;
    if (mounted) setState(() => _shouldPulse = false);
  }

  Future<void> _markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kFabSeenPrefKey, true);
    } catch (_) {
      // Swallow — non-critical.
    }
  }

  @override
  void dispose() {
    _pulseStopTimer?.cancel();
    _pressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combined visibility gate:
    //   1. Keyboard open  → hide (don't fight the IME).
    //   2. Inherited SupportFabVisibility(visible: false) → hide.
    //   3. Global bus says hidden (scroll-down OR explicit .hide()) → hide.
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

  Widget _buildButton(BuildContext context) {
    final tooltip = _safeTooltip(context);

    return Padding(
      padding: EdgeInsets.only(right: 16.0, bottom: widget.bottomOffset),
      child: Semantics(
        label: tooltip,
        button: true,
        // Combine press-scale and (optional) pulse-scale by multiplication.
        child: AnimatedBuilder(
          animation: Listenable.merge([_pressScale, _pulseScale]),
          builder: (context, child) {
            final scale = _pressScale.value * (_shouldPulse ? _pulseScale.value : 1.0);
            return Transform.scale(scale: scale, child: child);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSupportTeal,
                boxShadow: [
                  BoxShadow(
                    color: kSupportTealDark.withValues(
                      alpha: _hovering ? 0.45 : 0.30,
                    ),
                    blurRadius: _hovering ? 18 : 12,
                    spreadRadius: _hovering ? 1 : 0,
                    offset: Offset(0, _hovering ? 6 : 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _handleTap(context),
                  onTapDown: (_) => _pressCtrl.forward(),
                  onTapCancel: () => _pressCtrl.reverse(),
                  customBorder: const CircleBorder(),
                  // Brand-tinted overlays — replaces the broken white splash.
                  splashColor: kSupportTealDark.withValues(alpha: 0.30),
                  highlightColor: kSupportTealDark.withValues(alpha: 0.15),
                  hoverColor: Colors.white.withValues(alpha: 0.12),
                  focusColor: Colors.white.withValues(alpha: 0.16),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Tooltip(
                      message: tooltip,
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 24,
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
    if (_shouldPulse) _stopPulse();
    await _markSeen();
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
// The support FAB lives in a global Stack overlay mounted in main.dart; it
// draws ON TOP of any screen FAB at the same position.
//
// To prevent visual collision the FAB now hides automatically in four cases:
//   1. Keyboard is open (MediaQuery viewInsets.bottom > 0) — chat & forms.
//   2. The current subtree contains `SupportFabVisibility(visible: false)`.
//   3. Any code called `kSupportFabBus.hide()` — pair with `.show()` on
//      dispose.
//   4. The active scroll view reports `ScrollDirection.reverse` (scroll
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
