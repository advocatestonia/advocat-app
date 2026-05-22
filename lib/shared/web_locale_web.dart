// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web implementation of the landing/browser locale bridge.
///
/// `readLandingLang` returns the language code written by the marketing
/// landing into `window.localStorage['advocat-landing-lang']` (see
/// `web/landing.html` ~line 2301). If the landing has not yet run, or if
/// localStorage is blocked (Safari private mode, strict cookie policies),
/// the helper swallows the error and returns `null`.
///
/// `readNavigatorLang` returns the first two characters of
/// `window.navigator.language` (e.g. `"fi-FI"` -> `"fi"`), lowercased.
String? readLandingLang() {
  try {
    final raw = html.window.localStorage['advocat-landing-lang'];
    if (raw == null || raw.isEmpty) return null;
    return raw.toLowerCase();
  } catch (_) {
    return null;
  }
}

String? readNavigatorLang() {
  try {
    final raw = html.window.navigator.language;
    if (raw.isEmpty) return null;
    final code = raw.length >= 2 ? raw.substring(0, 2) : raw;
    return code.toLowerCase();
  } catch (_) {
    return null;
  }
}
