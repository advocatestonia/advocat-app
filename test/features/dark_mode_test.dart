// =============================================================================
// Dark mode wiring regression test (2026-05-27).
// =============================================================================
//
// Theme infrastructure (AppTheme.darkTheme + the dark palette in AppColors)
// existed for months but main.dart hard-coded `themeMode: ThemeMode.light`,
// blocking the entire dark surface from ever rendering. This test guards
// against four regressions:
//
//   1. main.dart wires `ref.watch(themeModeProvider)` into MaterialApp,
//      not ThemeMode.light.
//   2. themeModeProvider exists in lib/shared/providers/.
//   3. ARB keys for the Appearance picker (appearance / appearanceSystem /
//      Light / Dark / Description) exist in app_en.arb.
//   4. The dark ThemeData renders with darkBackground (#0F172A) as the
//      scaffold background — not the light surface (#F0EEEB).
//
// The first three are source-text checks (cheap, deterministic, same style
// as launch_wave1_ux_test.dart / home_quick_actions_layout_test.dart). The
// fourth is a real widget pump.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/config/theme.dart';

void main() {
  group('Dark mode wiring', () {
    test('main.dart watches themeModeProvider (not hardcoded ThemeMode.light)',
        () {
      final source = File('lib/main.dart').readAsStringSync();

      expect(
        source.contains('ref.watch(themeModeProvider)'),
        isTrue,
        reason:
            'main.dart must drive MaterialApp.themeMode from themeModeProvider. '
            'See lib/shared/providers/theme_mode_provider.dart.',
      );

      // Defence-in-depth: ensure the old hardcoded light mode is gone.
      final hardcodedLight = RegExp(r'themeMode:\s*ThemeMode\.light\b');
      expect(
        hardcodedLight.hasMatch(source),
        isFalse,
        reason:
            'main.dart still hardcodes themeMode: ThemeMode.light — this blocks '
            'dark mode entirely. It should read ref.watch(themeModeProvider).',
      );
    });

    test('themeModeProvider file exists with required public API', () {
      const path = 'lib/shared/providers/theme_mode_provider.dart';
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: '$path missing');

      final src = f.readAsStringSync();
      expect(src.contains('themeModeProvider'), isTrue,
          reason: 'themeModeProvider must be exported');
      expect(src.contains('sharedPreferencesProvider'), isTrue,
          reason: 'sharedPreferencesProvider override target must exist');
      expect(src.contains('theme_mode_v1'), isTrue,
          reason: 'pref key must be theme_mode_v1 (versioned)');
      expect(src.contains('ThemeMode.system'), isTrue,
          reason: 'default must be ThemeMode.system');
    });

    test('Appearance ARB keys present in app_en.arb (source of truth)', () {
      final raw = File('lib/l10n/app_en.arb').readAsStringSync();
      final arb = jsonDecode(raw) as Map<String, dynamic>;

      const required = [
        'appearance',
        'appearanceSystem',
        'appearanceLight',
        'appearanceDark',
        'appearanceDescription',
      ];
      for (final key in required) {
        expect(arb.containsKey(key), isTrue,
            reason: 'app_en.arb missing key: $key');
        expect((arb[key] as String).isNotEmpty, isTrue,
            reason: 'app_en.arb key "$key" is empty');
      }
    });

    test('Native locales (et/fi/ru) have native Appearance translations', () {
      // Verifies the 3 native locales got translated strings, not the English
      // fallback. We don't assert exact wording (translators may adjust), only
      // that the value differs from the English template.
      const nativeLocales = ['et', 'fi', 'ru'];
      final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;

      for (final loc in nativeLocales) {
        final path = 'lib/l10n/app_$loc.arb';
        final arb = jsonDecode(File(path).readAsStringSync())
            as Map<String, dynamic>;
        expect(arb.containsKey('appearance'), isTrue,
            reason: '$path missing "appearance"');
        expect(arb['appearance'], isNot(equals(en['appearance'])),
            reason: '$path has English fallback for "appearance" — should be native');
      }
    });

    testWidgets('darkTheme renders with darkBackground, not light surface',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Container(
                key: const Key('test-surface'),
                color: Theme.of(ctx).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('test-surface')),
      );
      final bg = container.color;
      expect(bg, equals(AppColors.darkBackground),
          reason: 'Scaffold bg in dark mode must be darkBackground (#0F172A), '
              'got: $bg');
      expect(bg, isNot(equals(const Color(0xFFF0EEEB))),
          reason: 'Scaffold bg in dark mode must NOT be the light #F0EEEB.');
    });

    test('AppTheme.darkTheme has Brightness.dark colorScheme', () {
      // Direct API check on the ThemeData — no widget pump needed.
      // This catches the regression where AppTheme.darkTheme is silently
      // overridden by a light brightness (e.g. ColorScheme.fromSeed losing
      // the brightness override).
      expect(AppTheme.darkTheme.brightness, equals(Brightness.dark));
      expect(AppTheme.darkTheme.colorScheme.brightness, equals(Brightness.dark));
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          equals(AppColors.darkBackground));
      expect(AppTheme.lightTheme.brightness, equals(Brightness.light));
    });

    test('Settings screen exposes the Appearance tile', () {
      final src =
          File('lib/features/settings/screens/settings_screen.dart')
              .readAsStringSync();
      expect(src.contains('l.appearance'), isTrue,
          reason: 'Settings screen must reference l.appearance');
      expect(src.contains('_showAppearancePicker'), isTrue,
          reason: 'Settings screen must call _showAppearancePicker');
      expect(src.contains('themeModeProvider'), isTrue,
          reason: 'Settings screen must read themeModeProvider');
      expect(src.contains('CupertinoActionSheet'), isTrue,
          reason: 'Appearance picker should use CupertinoActionSheet (iOS-first).');
    });
  });
}
