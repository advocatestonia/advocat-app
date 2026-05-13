// widgets/support/support_fab.dart
//
// Floating "Need help?" button anchored to the bottom-right corner of the
// app and visible on every route (landing, auth, chat, settings).
//
// Visual: a 56x56 circular FAB with the standard support_agent icon. Teal
// (#0D9488) per the brand. Tapping it opens [SupportSheet] as a modal
// bottom sheet on phones / centred dialog on wide layouts.
//
// We deliberately keep this widget tiny and dependency-light. It's mounted
// in main.dart inside a Stack overlay so it survives every navigation in
// the router. Screen-level FABs (chat send button, "New case", etc.) are
// kept untouched — see CONTRACT comment at the bottom of this file.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'support_sheet.dart';

/// Brand-locked teal used for the support FAB and the in-app submit button.
const Color kSupportTeal = Color(0xFF0D9488);
const Color kSupportTealDark = Color(0xFF0F766E);

/// Bottom-right floating help button. Mount in a Stack overlay above the
/// [MaterialApp.router] so it persists across every route.
class SupportFab extends StatelessWidget {
  const SupportFab({super.key, this.bottomOffset = 16.0});

  /// Distance from the bottom edge in dp. Default 16 sits above the system
  /// home-indicator on iOS web/PWA. Screens that own a bottom nav bar
  /// should pass `bottomOffset: 88` (or wrap the fab in their own Padding).
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    // Fall back to a static English label when AppLocalizations isn't yet
    // available (e.g. during early router redirects on cold start). This
    // keeps the FAB rendering even before the locale is ready.
    final tooltip = _safeTooltip(context);

    return Padding(
      padding: EdgeInsets.only(right: 16.0, bottom: bottomOffset),
      child: Semantics(
        label: tooltip,
        button: true,
        child: Material(
          elevation: 6.0,
          color: kSupportTeal,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openSheet(context),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Tooltip(
                message: tooltip,
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

// CONTRACT — coexistence with screen-level FABs
// -----------------------------------------------------------------------------
// Several screens (cases list, deadlines, document list) already render their
// own FloatingActionButton via Scaffold.floatingActionButton at the bottom-
// right. The support FAB lives in a global Stack overlay mounted in main.dart;
// it draws ON TOP of any screen FAB at the same position.
//
// To prevent visual collision the chat screen — the only place where the
// bottom-right region is used for *interaction* (the message send button) —
// hides the support FAB while the keyboard is open OR while a stream is in
// flight. That hide is handled by the chat screen itself via the
// [SupportFabVisibility] inherited widget below.
//
// On screens with extended FABs in the bottom-LEFT or bottom-CENTER (none
// today, but allowed) the two coexist cleanly because the support FAB is
// always anchored to bottom-right.
// -----------------------------------------------------------------------------

/// Optional inherited widget that lets descendants hide the global support
/// FAB temporarily (e.g. chat screen during streaming). Currently unused
/// at launch — included so chat can opt in later without a layout change.
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
