// Web implementation of [SessionStorage] backed by window.sessionStorage.
//
// We deliberately use sessionStorage (not localStorage) because the
// PendingCheckout is a single-redirect-flow value: it should survive the
// Stripe OAuth bounce but be discarded when the user closes the tab. A
// stale PendingCheckout in localStorage would silently re-trigger
// Checkout the next time the user opened /home, which is exactly the
// double-billing failure mode we are guarding against.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

class SessionStorage {
  static JSObject? get _storage {
    try {
      final s = _window.getProperty<JSObject?>('sessionStorage'.toJS);
      return s;
    } catch (_) {
      // Some embedded WebViews (Safari private mode prior to iOS 18, a
      // handful of corporate proxies) throw on sessionStorage access.
      // Treat as unavailable; in-memory state still works.
      return null;
    }
  }

  static String? read(String key) {
    final s = _storage;
    if (s == null) return null;
    try {
      final v = s.callMethod<JSAny?>('getItem'.toJS, key.toJS);
      if (v == null) return null;
      return (v as JSString).toDart;
    } catch (_) {
      return null;
    }
  }

  static void write(String key, String value) {
    final s = _storage;
    if (s == null) return;
    try {
      s.callMethod<JSAny?>('setItem'.toJS, key.toJS, value.toJS);
    } catch (_) {
      // QuotaExceededError or SecurityError — silently drop. The
      // in-memory state still drives the same flow.
    }
  }

  static void remove(String key) {
    final s = _storage;
    if (s == null) return;
    try {
      s.callMethod<JSAny?>('removeItem'.toJS, key.toJS);
    } catch (_) {}
  }
}
