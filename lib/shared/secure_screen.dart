// =====================================================================
// secure_screen.dart — FLAG_SECURE / App-Switcher blur platform channel.
//
// Security context — F3 (WAVE 2, 2026-05-28).
// =====================================================================
//
// Why this exists
// ---------------
// The 2026-05-28 client-security audit (`docs/security_audit_2026-05-28/
// findings/03_client_security.md`) flagged finding F3: 13 confidentially-
// classed Flutter screens (Vault, Drafting Studio, Contract Review, Chat,
// Inbox, Case Workspace, Intake Wizard, Email, Case File, Firm/B2B,
// Login/Register, AI Memory, Legal-Aid Calculator, Admin Gold Review)
// had ZERO screenshot or App-Switcher protection.
//
// The audit recommended the "FLAG_SECURE matrix" approach: a single
// MethodChannel that toggles `WindowManager.LayoutParams.FLAG_SECURE` on
// Android and an App-Switcher blur overlay on iOS (FLAG_SECURE has no
// direct iOS equivalent). Per-screen control rather than a global flag
// is required because the marketing surfaces (Onboarding, Landmarks,
// Rights, Referral Landing) deliberately stay screenshot-friendly so
// users can share legal-info screenshots / referral codes.
//
// Architecture
// ------------
//   * Platform channel `advocat/secure_screen` exposes two methods:
//     `setSecure` and `clearSecure`.
//   * Android `MainActivity.kt` translates these to
//     `window.addFlags(FLAG_SECURE)` / `window.clearFlags(FLAG_SECURE)`.
//   * iOS `AppDelegate.swift` flips a global `SecureScreenState.shared.
//     isSecure` flag; `SceneDelegate.swift` reads that flag on
//     `sceneWillResignActive` and attaches an opaque blur overlay before
//     iOS snapshots the App Switcher.
//   * Web is a no-op — there is no comparable mechanism in the browser
//     and the audit (F2/F4) addresses web hardening via CSP separately.
//
// Reference counting
// ------------------
// Multiple SecureScreenScope widgets can be mounted at the same time —
// for example, the Case Workspace screen wraps its build in a scope and
// then opens a Chat screen as a modal which ALSO wraps in a scope. We
// MUST NOT clear FLAG_SECURE when the inner scope disposes while the
// outer scope is still active. Hence the process-global SecureMode
// counter: setSecure() bumps the counter from 0 → 1 and tells the
// platform to enable secure mode; subsequent enables just bump the
// counter; disables decrement; only the 1 → 0 transition tells the
// platform to clear.

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Name of the platform channel implemented by the host platforms.
///
/// Exposed (rather than kept private) so the regression test in
/// `test/shared/secure_screen_test.dart` can intercept calls via
/// `TestDefaultBinaryMessengerBinding.defaultBinaryMessenger
/// .setMockMethodCallHandler` without having to know the constant by
/// hand.
const String kSecureScreenChannelName = 'advocat/secure_screen';

/// Method names exposed by the platform channel.
const String kSecureScreenMethodSetSecure = 'setSecure';
const String kSecureScreenMethodClearSecure = 'clearSecure';

/// Reference-counting controller for the secure-screen mode.
///
/// The implementation is intentionally static (no Riverpod) because the
/// state lives at the process level — it mirrors a flag held by the
/// Android Window and the iOS `SecureScreenState.shared` singleton.
/// Wrapping it in a provider would invite "what if the provider is in
/// a different scope" bugs we cannot reason about.
///
/// All public methods are safe to call:
///   * before the binding is initialised (no-op until binding ready),
///   * on web (always a no-op — no comparable browser API),
///   * concurrently from multiple call sites (Dart is single-threaded so
///     ref-counting under main isolate is atomic),
///   * from `initState` AND from imperative call sites like a deep-link
///     handler.
class SecureMode {
  SecureMode._();

  /// Internal ref count. Visible-for-testing so the regression test can
  /// assert the counter resets between tests.
  @visibleForTesting
  static int debugRefCount = 0;

  /// The method channel used to talk to native. Overridable by tests
  /// that wish to inject a mock binary messenger via the platform
  /// channel name (preferred). Kept as a field so we can re-create it
  /// against a swapped binary messenger if a test needs that.
  @visibleForTesting
  static MethodChannel channel = const MethodChannel(kSecureScreenChannelName);

  /// True iff at least one scope has called [enable] without a matching
  /// [disable].
  static bool get isActive => debugRefCount > 0;

  /// Increment the ref count. If the count transitions from 0 → 1, ask
  /// the platform to enable secure mode. Returns a `Future` that
  /// completes once the platform call has been acknowledged (or
  /// immediately on web).
  ///
  /// Never throws — platform-channel exceptions are swallowed because
  /// failing to enable secure mode must not crash the screen.
  static Future<void> enable() async {
    debugRefCount += 1;
    if (debugRefCount != 1) {
      // Already active — nothing to do platform-side.
      return;
    }
    if (kIsWeb) return;
    try {
      await channel.invokeMethod<void>(kSecureScreenMethodSetSecure);
    } on PlatformException {
      // Channel not wired (running on unsupported platform). Silently
      // succeed — the audit P0 is "secure screens on iOS/Android".
    } on MissingPluginException {
      // Method handler not registered (e.g. integration test on a host
      // that doesn't install MainActivity). Silently succeed.
    }
  }

  /// Decrement the ref count. If the count transitions from 1 → 0, ask
  /// the platform to clear secure mode. Idempotent at zero — extra
  /// calls do nothing (and log in debug builds).
  ///
  /// Never throws.
  static Future<void> disable() async {
    if (debugRefCount == 0) {
      // Defensive: a misuse where someone calls disable() without a
      // matching enable(). Do not let the counter go negative — the
      // refcount-with-negative-floor is the right "fail open to secure".
      assert(() {
        debugPrint(
          '[SecureMode] disable() called with refCount=0 — likely a bug. '
          'Ignoring to keep the platform state consistent.',
        );
        return true;
      }());
      return;
    }
    debugRefCount -= 1;
    if (debugRefCount != 0) {
      // Still other scopes mounted — keep secure mode on.
      return;
    }
    if (kIsWeb) return;
    try {
      await channel.invokeMethod<void>(kSecureScreenMethodClearSecure);
    } on PlatformException {
      // see enable() comment
    } on MissingPluginException {
      // see enable() comment
    }
  }

  /// Test-only reset to clear the ref count and platform state between
  /// tests. NEVER call this in production.
  @visibleForTesting
  static Future<void> debugReset() async {
    debugRefCount = 0;
    if (kIsWeb) return;
    try {
      await channel.invokeMethod<void>(kSecureScreenMethodClearSecure);
    } catch (_) {
      // ignore — tests may run before the channel is mocked
    }
  }
}

/// Widget scope that enables secure mode for the lifetime of its
/// subtree.
///
/// Wrap the body of any confidential screen's `build()` in a
/// SecureScreenScope. The widget calls [SecureMode.enable] on
/// `initState` and [SecureMode.disable] on `dispose`. Ref counting in
/// [SecureMode] guarantees that nested scopes do not prematurely clear
/// the flag when the inner scope is disposed before the outer.
///
/// Usage
/// -----
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return SecureScreenScope(
///     child: Scaffold(
///       appBar: AppBar(title: Text('Vault')),
///       body: ...
///     ),
///   );
/// }
/// ```
class SecureScreenScope extends StatefulWidget {
  const SecureScreenScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SecureScreenScope> createState() => _SecureScreenScopeState();
}

class _SecureScreenScopeState extends State<SecureScreenScope> {
  /// Tracks whether _this particular_ instance has incremented the ref
  /// count. We hold it locally so a dispose that races with a hot-
  /// reload doesn't double-decrement.
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = true;
    // Fire-and-forget — Dart's microtask scheduler executes this on the
    // main isolate so the platform call happens on the next frame.
    // initState cannot be async; awaiting here would block the build.
    SecureMode.enable();
  }

  @override
  void dispose() {
    if (_enabled) {
      _enabled = false;
      // Fire-and-forget. dispose() must not await.
      SecureMode.disable();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
