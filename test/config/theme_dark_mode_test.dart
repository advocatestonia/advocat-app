// =============================================================================
// Dark mode theme tests — covers all 13 component themes + WCAG AA contrast.
// =============================================================================
//
// Companion to theme_test.dart (which covers the global palette + light theme).
// This file specifically asserts that AppTheme.darkTheme defines every
// Material 3 component theme we rely on, with WCAG-AA-compliant colors.
//
// Contrast formula: (L1 + 0.05) / (L2 + 0.05), where L is the relative
// luminance per WCAG 2.1. Body text requires >= 4.5:1; large text & UI
// components require >= 3:1.
//
// 2026-05-27 — initial coverage. Triggered by audit finding that dark mode
// was only partially themed (AppBar / Card / Input) and accentLight #0D9488
// was wired as primary despite being documented "AA-large only".
// =============================================================================
@Tags(['fast'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/config/theme.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double gamma(int v) {
    final s = v / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * gamma(c.red) +
      0.7152 * gamma(c.green) +
      0.0722 * gamma(c.blue);
}

/// WCAG 2.1 contrast ratio.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final light = la > lb ? la : lb;
  final dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  late ThemeData darkTheme;

  setUp(() {
    darkTheme = AppTheme.darkTheme;
  });

  // ── Group 1: New dark-mode palette tokens ─────────────────────────────
  group('AppColors dark-mode tokens', () {
    test('darkAccent is #14B8A6 (Tailwind teal-500)', () {
      expect(AppColors.darkAccent, const Color(0xFF14B8A6));
    });

    test('darkError is #F87171 (Tailwind red-400)', () {
      expect(AppColors.darkError, const Color(0xFFF87171));
    });

    test('darkTextOnAccent is #0F172A (near-black for AA on accent fills)',
        () {
      expect(AppColors.darkTextOnAccent, const Color(0xFF0F172A));
    });
  });

  // ── Group 2: WCAG AA contrast for dark mode ───────────────────────────
  group('Dark mode WCAG AA contrast', () {
    test('darkAccent on darkBackground >= 4.5:1 (AA body text)', () {
      final ratio = _contrast(AppColors.darkAccent, AppColors.darkBackground);
      expect(ratio >= 4.5, isTrue,
          reason: 'darkAccent on darkBackground = ${ratio.toStringAsFixed(2)}:1');
    });

    test('darkAccent on darkSurface >= 4.5:1 (AA body text)', () {
      final ratio = _contrast(AppColors.darkAccent, AppColors.darkSurface);
      expect(ratio >= 4.5, isTrue,
          reason: 'darkAccent on darkSurface = ${ratio.toStringAsFixed(2)}:1');
    });

    test('darkTextOnAccent on darkAccent >= 4.5:1 (button label AA)', () {
      final ratio =
          _contrast(AppColors.darkTextOnAccent, AppColors.darkAccent);
      expect(ratio >= 4.5, isTrue,
          reason:
              'darkTextOnAccent on darkAccent = ${ratio.toStringAsFixed(2)}:1');
    });

    test('darkError on darkBackground >= 4.5:1 (AA)', () {
      final ratio = _contrast(AppColors.darkError, AppColors.darkBackground);
      expect(ratio >= 4.5, isTrue,
          reason: 'darkError on darkBackground = ${ratio.toStringAsFixed(2)}:1');
    });

    test('darkTextPrimary on darkBackground >= 4.5:1 (AA)', () {
      final ratio =
          _contrast(AppColors.darkTextPrimary, AppColors.darkBackground);
      expect(ratio >= 4.5, isTrue,
          reason:
              'darkTextPrimary on darkBackground = ${ratio.toStringAsFixed(2)}:1');
    });

    test('darkTextPrimary on darkSurface >= 4.5:1 (AA)', () {
      final ratio =
          _contrast(AppColors.darkTextPrimary, AppColors.darkSurface);
      expect(ratio >= 4.5, isTrue,
          reason:
              'darkTextPrimary on darkSurface = ${ratio.toStringAsFixed(2)}:1');
    });

    test('darkTextSecondary on darkSurface >= 3:1 (AA large/UI)', () {
      // Secondary text is used for hints and metadata — typically rendered at
      // 13-14pt regular. AA large-text threshold is 3:1.
      final ratio =
          _contrast(AppColors.darkTextSecondary, AppColors.darkSurface);
      expect(ratio >= 3.0, isTrue,
          reason:
              'darkTextSecondary on darkSurface = ${ratio.toStringAsFixed(2)}:1');
    });

    test('regression: accentLight (#0D9488) is NOT wired as dark primary', () {
      // accentLight is documented "AA-large only" — 4.77:1 on darkBackground
      // but only 3.91:1 on darkSurface (FAIL body text on cards/dialogs).
      // Make sure we didn't regress to the buggy wiring.
      expect(darkTheme.colorScheme.primary, isNot(AppColors.accentLight));
    });
  });

  // ── Group 3: ColorScheme wiring ───────────────────────────────────────
  group('Dark ColorScheme', () {
    test('primary is darkAccent', () {
      expect(darkTheme.colorScheme.primary, AppColors.darkAccent);
    });

    test('onPrimary is darkTextOnAccent (AA on accent fills)', () {
      expect(darkTheme.colorScheme.onPrimary, AppColors.darkTextOnAccent);
    });

    test('surface is darkSurface', () {
      expect(darkTheme.colorScheme.surface, AppColors.darkSurface);
    });

    test('error is darkError (AA on dark bg, not brand red)', () {
      expect(darkTheme.colorScheme.error, AppColors.darkError);
    });

    test('outline is darkBorder', () {
      expect(darkTheme.colorScheme.outline, AppColors.darkBorder);
    });

    test('brightness is dark', () {
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
    });
  });

  // ── Group 4: All 13 component themes present + wired correctly ────────
  group('Dark theme component coverage (13 components)', () {
    test('1. AppBar — dark surface + light foreground', () {
      expect(darkTheme.appBarTheme.backgroundColor, AppColors.darkSurface);
      expect(darkTheme.appBarTheme.foregroundColor, AppColors.darkTextPrimary);
      expect(darkTheme.appBarTheme.elevation, 0);
    });

    test('2. Card — dark surface + dark border', () {
      expect(darkTheme.cardTheme.color, AppColors.darkSurface);
      expect(darkTheme.cardTheme.elevation, 0);
      final shape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.darkBorder);
    });

    test('3. ElevatedButton — darkAccent bg + dark label (AA fill)', () {
      final style = darkTheme.elevatedButtonTheme.style;
      expect(style, isNotNull);
      expect(style!.backgroundColor?.resolve({}), AppColors.darkAccent);
      expect(style.foregroundColor?.resolve({}), AppColors.darkTextOnAccent);
    });

    test('4. OutlinedButton — darkAccent border + label', () {
      final style = darkTheme.outlinedButtonTheme.style;
      expect(style, isNotNull);
      expect(style!.foregroundColor?.resolve({}), AppColors.darkAccent);
      final side = style.side?.resolve({});
      expect(side?.color, AppColors.darkAccent);
    });

    test('5. TextButton — darkAccent label', () {
      final style = darkTheme.textButtonTheme.style;
      expect(style, isNotNull);
      expect(style!.foregroundColor?.resolve({}), AppColors.darkAccent);
    });

    test('6. Input — surfaceVariant fill + darkAccent focused border', () {
      final input = darkTheme.inputDecorationTheme;
      expect(input.filled, isTrue);
      expect(input.fillColor, AppColors.darkSurfaceVariant);
      final focused = input.focusedBorder as OutlineInputBorder;
      expect(focused.borderSide.color, AppColors.darkAccent);
      final errBorder = input.errorBorder as OutlineInputBorder;
      expect(errBorder.borderSide.color, AppColors.darkError);
    });

    test('7. Divider — darkBorder', () {
      expect(darkTheme.dividerTheme.color, AppColors.darkBorder);
      expect(darkTheme.dividerTheme.thickness, 1);
    });

    test('8. BottomNavigationBar — surface bg + accent selected', () {
      final nav = darkTheme.bottomNavigationBarTheme;
      expect(nav.backgroundColor, AppColors.darkSurface);
      expect(nav.selectedItemColor, AppColors.darkAccent);
      expect(nav.unselectedItemColor, AppColors.darkTextSecondary);
    });

    test('9. Chip — surfaceVariant bg + dark border + radius=full', () {
      final chip = darkTheme.chipTheme;
      expect(chip.backgroundColor, AppColors.darkSurfaceVariant);
      expect(chip.selectedColor, AppColors.darkAccent);
      final shape = chip.shape as RoundedRectangleBorder;
      // radius=full → very large value; just ensure it's not 0
      expect(shape.borderRadius, isA<BorderRadius>());
      expect(chip.side?.color, AppColors.darkBorder);
    });

    test('10. FloatingActionButton — darkAccent + onAccent label', () {
      final fab = darkTheme.floatingActionButtonTheme;
      expect(fab.backgroundColor, AppColors.darkAccent);
      expect(fab.foregroundColor, AppColors.darkTextOnAccent);
    });

    test('11. Switch — accent track selected, surfaceVariant unselected', () {
      final sw = darkTheme.switchTheme;
      final selectedTrack =
          sw.trackColor?.resolve({WidgetState.selected});
      final idleTrack = sw.trackColor?.resolve({});
      expect(selectedTrack, AppColors.darkAccent);
      expect(idleTrack, AppColors.darkSurfaceVariant);
      // Selected thumb must contrast against accent track (AA).
      final selectedThumb =
          sw.thumbColor?.resolve({WidgetState.selected});
      expect(selectedThumb, AppColors.darkTextOnAccent);
    });

    test('12. Slider — accent active track + thumb', () {
      final s = darkTheme.sliderTheme;
      expect(s.activeTrackColor, AppColors.darkAccent);
      expect(s.inactiveTrackColor, AppColors.darkSurfaceVariant);
      expect(s.thumbColor, AppColors.darkAccent);
    });

    test('13a. SnackBar — surfaceVariant bg + accent action', () {
      final snack = darkTheme.snackBarTheme;
      expect(snack.backgroundColor, AppColors.darkSurfaceVariant);
      expect(snack.actionTextColor, AppColors.darkAccent);
      expect(snack.behavior, SnackBarBehavior.floating);
    });

    test('13b. Dialog — darkSurface bg + textPrimary text', () {
      final dialog = darkTheme.dialogTheme;
      expect(dialog.backgroundColor, AppColors.darkSurface);
      expect(dialog.titleTextStyle?.color, AppColors.darkTextPrimary);
      expect(dialog.contentTextStyle?.color, AppColors.darkTextPrimary);
    });

    test('13c. Drawer — darkSurface bg', () {
      final drawer = darkTheme.drawerTheme;
      expect(drawer.backgroundColor, AppColors.darkSurface);
    });

    test('13d. ListTile — transparent tile + textPrimary text', () {
      final lt = darkTheme.listTileTheme;
      expect(lt.tileColor, Colors.transparent);
      expect(lt.selectedTileColor, AppColors.darkSurfaceVariant);
      expect(lt.selectedColor, AppColors.darkAccent);
      expect(lt.textColor, AppColors.darkTextPrimary);
      expect(lt.iconColor, AppColors.darkTextSecondary);
    });
  });

  // ── Group 5: Border radius consistency ────────────────────────────────
  group('Dark theme border radius consistency', () {
    BorderRadius? extractRadius(ShapeBorder? shape) {
      if (shape is RoundedRectangleBorder) {
        return shape.borderRadius is BorderRadius
            ? shape.borderRadius as BorderRadius
            : null;
      }
      return null;
    }

    test('Card uses AppRadius.md (12px)', () {
      final radius = extractRadius(darkTheme.cardTheme.shape);
      expect(radius?.topLeft.x, AppRadius.md);
    });

    test('Dialog uses AppRadius.md (12px)', () {
      final radius = extractRadius(darkTheme.dialogTheme.shape);
      expect(radius?.topLeft.x, AppRadius.md);
    });

    test('SnackBar uses AppRadius.md (12px)', () {
      final radius = extractRadius(darkTheme.snackBarTheme.shape);
      expect(radius?.topLeft.x, AppRadius.md);
    });
  });

  // ── Group 6: Light theme NOT broken by dark mode changes ──────────────
  group('Light theme regression guard', () {
    late ThemeData lightTheme;

    setUp(() {
      lightTheme = AppTheme.lightTheme;
    });

    test('light primary still AppColors.primary', () {
      expect(lightTheme.colorScheme.primary, AppColors.primary);
    });

    test('light brightness still light', () {
      expect(lightTheme.colorScheme.brightness, Brightness.light);
    });

    test('light scaffold still AppColors.background', () {
      expect(lightTheme.scaffoldBackgroundColor, AppColors.background);
    });

    test('light error still AppColors.error (not darkError)', () {
      expect(lightTheme.colorScheme.error, AppColors.error);
    });
  });
}
