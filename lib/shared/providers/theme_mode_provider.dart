// =============================================================================
// Theme mode provider — user-controlled light/dark/system preference.
// =============================================================================
//
// The dark palette + ThemeData live in `lib/config/theme.dart` (AppColors +
// AppTheme.darkTheme, owner-approved). This file just wires user choice into
// MaterialApp.themeMode.
//
// Default is ThemeMode.system so the OS preference wins on first launch.
// Once the user explicitly picks Light or Dark in Settings, the choice is
// persisted in SharedPreferences under key `theme_mode_v1` and survives
// across app restarts.
//
// 2026-05-27 — initial wiring (theme infrastructure existed but main.dart
// hard-coded ThemeMode.light, blocking dark mode entirely).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key. Versioned (`_v1`) so we can migrate the format
/// later without colliding with existing values.
const String themeModePrefKey = 'theme_mode_v1';

/// Stored string values. We deliberately use strings (not int indices) so the
/// stored prefs file remains human-readable and stable across enum reorders.
const String _themePrefSystem = 'system';
const String _themePrefLight = 'light';
const String _themePrefDark = 'dark';

ThemeMode _decode(String? raw) {
  switch (raw) {
    case _themePrefLight:
      return ThemeMode.light;
    case _themePrefDark:
      return ThemeMode.dark;
    case _themePrefSystem:
    default:
      return ThemeMode.system;
  }
}

String _encode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return _themePrefLight;
    case ThemeMode.dark:
      return _themePrefDark;
    case ThemeMode.system:
      return _themePrefSystem;
  }
}

/// Notifier holding the current [ThemeMode] and persisting changes to
/// SharedPreferences. Reads are synchronous (loaded once in the constructor
/// via the cached singleton — `SharedPreferences.getInstance()` returns the
/// already-resolved instance after the initial `main()` await).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_decode(_prefs.getString(themeModePrefKey)));

  final SharedPreferences _prefs;

  /// Set the active theme mode and persist the choice. Fire-and-forget on
  /// the disk write — UI updates immediately, persistence catches up.
  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(themeModePrefKey, _encode(mode));
  }
}

/// Provider for the active [ThemeMode]. Default = [ThemeMode.system] so the
/// OS preference wins for new installs and for users who never visit
/// Settings → Appearance.
///
/// Watched by [AdvocatApp] in `main.dart` to drive `MaterialApp.themeMode`.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) {
    // SharedPreferences is initialised in main() before runApp(), so the
    // instance is already cached — getInstance() resolves synchronously
    // on the second call. We block on the future here only to satisfy the
    // type system; in practice this never awaits.
    final prefs = ref.watch(_sharedPrefsProvider);
    return ThemeModeNotifier(prefs);
  },
);

/// Internal provider that surfaces the already-initialised SharedPreferences
/// instance to dependents. Overridden in `main()` with the concrete value.
final _sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'See main.dart — overrides include sharedPreferencesProvider.',
  );
});

/// Public alias for the override target. Wired in `main.dart`.
final sharedPreferencesProvider = _sharedPrefsProvider;
