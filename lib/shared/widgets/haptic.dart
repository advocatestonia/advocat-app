import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Haptic — v24.1 WOW polish
// ---------------------------------------------------------------------------
//
// Cross-platform haptic feedback with intent-based API.  Silent no-op on
// platforms that don't support it (web, desktop) so callers don't have
// to guard.  On iOS/Android this maps to HapticFeedback system calls.
//
// Usage:
//   Haptic.lightTap();   // small confirmation (button press)
//   Haptic.mediumImpact(); // bigger action (send, delete)
//   Haptic.heavyImpact();  // destructive (confirm delete, error)
//   Haptic.success();      // after a successful operation
//   Haptic.selection();    // scroll / picker tick

abstract final class Haptic {
  static bool _enabled = true;

  static bool get enabled => _enabled;

  /// Disable all haptic feedback (e.g. user preference).
  static void setEnabled(bool value) {
    _enabled = value;
  }

  /// Is the current platform capable of hardware haptics?
  static bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  /// Light tap — button press, toggle.
  static Future<void> lightTap() async {
    if (!_enabled || !isSupported) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact — action completed, send, save.
  static Future<void> mediumImpact() async {
    if (!_enabled || !isSupported) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact — destructive confirmation, error alert.
  static Future<void> heavyImpact() async {
    if (!_enabled || !isSupported) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Short tick — picker scroll, list selection.
  static Future<void> selection() async {
    if (!_enabled || !isSupported) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Success chord — two quick taps.
  static Future<void> success() async {
    if (!_enabled || !isSupported) return;
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Error pattern — heavy then light.
  static Future<void> error() async {
    if (!_enabled || !isSupported) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
