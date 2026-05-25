// =============================================================================
// b2b_detection_provider.dart
// =============================================================================
//
// Owns the client-side state machine for the B2B silent-signal lead modal:
//
//   1. After login, the home screen calls
//      `ref.read(b2bDetectionControllerProvider.notifier).maybeTrigger(ctx)`.
//   2. The controller asks the [B2BService] whether
//      `profiles.b2b_modal_pending` is true for the current user.
//   3. If true (and no modal is already on screen), it pumps the
//      [B2BLeadModal] via [showB2BLeadModal].
//   4. On user action it marks the modal shown via the RPC (fire-and-forget)
//      and, for "Learn more", navigates to `/for-firms`.
//
// The controller carries no real "state" worth subscribing to — we use a
// StateNotifier mostly so we get a single canonical instance per provider
// scope (and to anchor the "currently visible" guard).
//
// Important: this provider is FULLY fire-and-forget. Any failure inside
// the chain — missing column, RLS deny, network blip, RPC 500 — is
// swallowed. The worst that happens is the modal doesn't appear, which
// is the same outcome as the backend signal returning false. This keeps
// home-screen render robust against any backend churn the parallel agent
// might ship while their detector is being wired up.
// =============================================================================

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/b2b_service.dart';
import '../widgets/b2b_lead_modal.dart';

/// Internal state of the controller. We only need to know:
///  * whether we've already triggered this session (so login → home →
///    pop-to-home doesn't re-trigger), and
///  * whether the modal is currently on screen (so double-taps on the
///    trigger don't stack dialogs).
@immutable
class B2BDetectionState {
  const B2BDetectionState({
    this.triggeredThisSession = false,
    this.modalVisible = false,
  });

  final bool triggeredThisSession;
  final bool modalVisible;

  B2BDetectionState copyWith({
    bool? triggeredThisSession,
    bool? modalVisible,
  }) {
    return B2BDetectionState(
      triggeredThisSession:
          triggeredThisSession ?? this.triggeredThisSession,
      modalVisible: modalVisible ?? this.modalVisible,
    );
  }
}

/// The route the "Learn more" CTA pushes to. Centralised so both the
/// provider and the router agree on the path.
const String kForFirmsRoute = '/for-firms';

/// Hook for tests: replace the real navigator-driven modal pump and
/// navigation with a stub that just records calls. Production code does
/// not touch this.
@visibleForTesting
typedef B2BModalRunner = Future<B2BAction> Function(
  BuildContext context,
  String locale,
);

@visibleForTesting
typedef B2BNavigator = void Function(BuildContext context, String route);

class B2BDetectionController extends StateNotifier<B2BDetectionState> {
  B2BDetectionController(
    this._service, {
    B2BModalRunner? modalRunner,
    B2BNavigator? navigator,
  })  : _modalRunner = modalRunner ?? _defaultRunner,
        _navigator = navigator ?? _defaultNavigator,
        super(const B2BDetectionState());

  final B2BService _service;
  final B2BModalRunner _modalRunner;
  final B2BNavigator _navigator;

  /// Production: delegate to [showB2BLeadModal] which manages its own
  /// barrier + transition.
  static Future<B2BAction> _defaultRunner(
    BuildContext context,
    String locale,
  ) =>
      showB2BLeadModal(context, locale: locale);

  /// Production: push the named route via go_router. Wrapping it lets
  /// tests assert "the user went to /for-firms" without spinning up a
  /// router stack.
  static void _defaultNavigator(BuildContext context, String route) {
    if (!context.mounted) return;
    context.push(route);
  }

  /// Main entry point — call once per home-screen mount (or post-login
  /// arrival). Idempotent: subsequent calls inside the same session
  /// no-op until [resetForTest] is invoked.
  ///
  /// Returns the action the user picked, or null if the modal didn't fire
  /// (pending=false, already triggered, etc.). Callers can ignore the
  /// return value; it's exposed mainly for the widget tests.
  Future<B2BAction?> maybeTrigger(
    BuildContext context, {
    required String locale,
  }) async {
    // De-dupe — once per app session is enough. The backend's
    // `b2b_modal_pending` flag is the persistent guard across sessions.
    if (state.triggeredThisSession) return null;
    if (state.modalVisible) return null;

    final pending = await _service.fetchB2BModalPending();
    if (!pending) {
      // Mark as triggered anyway so we don't burn a second round-trip in
      // the same session. The flag itself will be re-fetched on next
      // cold-start.
      state = state.copyWith(triggeredThisSession: true);
      return null;
    }

    // Has the host widget been disposed between fetch + show? Bail.
    if (!context.mounted) {
      state = state.copyWith(triggeredThisSession: true);
      return null;
    }

    state = state.copyWith(
      triggeredThisSession: true,
      modalVisible: true,
    );

    B2BAction action;
    try {
      action = await _modalRunner(context, locale);
    } finally {
      state = state.copyWith(modalVisible: false);
    }

    // Mark shown for BOTH branches — per spec "don't pester again".
    // Fire-and-forget: errors are already swallowed by the service.
    unawaited(_service.markB2BModalShown());

    if (action == B2BAction.learnMore && context.mounted) {
      _navigator(context, kForFirmsRoute);
    }

    return action;
  }

  /// Test-only: reset both gates so a single ProviderContainer can drive
  /// multiple trigger scenarios.
  @visibleForTesting
  void resetForTest() {
    state = const B2BDetectionState();
  }
}

/// Provider — single instance per ProviderScope. The home-screen controller
/// reads `b2bDetectionControllerProvider.notifier` and calls
/// `maybeTrigger(ctx, locale)` once on mount.
final b2bDetectionControllerProvider =
    StateNotifierProvider<B2BDetectionController, B2BDetectionState>((ref) {
  return B2BDetectionController(ref.read(b2bServiceProvider));
});
