import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/config/theme.dart';

void main() {
  group('AppColors', () {
    group('Primary palette', () {
      test('primary is #1A365D', () {
        expect(AppColors.primary, const Color(0xFF1A365D));
      });

      test('primaryLight is #2A4A7F', () {
        expect(AppColors.primaryLight, const Color(0xFF2A4A7F));
      });

      test('primaryDark is #0F2240', () {
        expect(AppColors.primaryDark, const Color(0xFF0F2240));
      });
    });

    group('Accent palette (WCAG AA shifted, v24.2)', () {
      test('accent is #0B7A70 (AA 4.6:1 white text)', () {
        expect(AppColors.accent, const Color(0xFF0B7A70));
      });

      test('accentLight is #0D9488 (former accent, AA-large only)', () {
        expect(AppColors.accentLight, const Color(0xFF0D9488));
      });

      test('accentDark is #074F49', () {
        expect(AppColors.accentDark, const Color(0xFF074F49));
      });

      test('accentTint is #14B8A6 (decorative only, not for text)', () {
        expect(AppColors.accentTint, const Color(0xFF14B8A6));
      });
    });

    group('Neutral colors', () {
      test('background is #F0EEEB', () {
        expect(AppColors.background, const Color(0xFFF0EEEB));
      });

      test('surface is #F7F6F4', () {
        expect(AppColors.surface, const Color(0xFFF7F6F4));
      });

      test('surfaceVariant is #EAE8E5', () {
        expect(AppColors.surfaceVariant, const Color(0xFFEAE8E5));
      });

      test('border is #DCD9D5', () {
        expect(AppColors.border, const Color(0xFFDCD9D5));
      });
    });

    group('Text colors (WCAG AA, v24.2)', () {
      test('textPrimary is #0F172A', () {
        expect(AppColors.textPrimary, const Color(0xFF0F172A));
      });

      test('textSecondary is #475569', () {
        expect(AppColors.textSecondary, const Color(0xFF475569));
      });

      test('textTertiary is #475569 (raised from #64748B for AA)', () {
        expect(AppColors.textTertiary, const Color(0xFF475569));
      });

      test('textOnPrimary is white', () {
        expect(AppColors.textOnPrimary, const Color(0xFFFFFFFF));
      });
    });

    group('Semantic colors (WCAG AA shifted, v24.2)', () {
      test('success is #14532D (10.5:1 on light bg)', () {
        expect(AppColors.success, const Color(0xFF14532D));
      });

      test('warning is #92400E (7.3:1 on light bg)', () {
        expect(AppColors.warning, const Color(0xFF92400E));
      });

      test('error is #B91C1C (5.8:1 on light bg)', () {
        expect(AppColors.error, const Color(0xFFB91C1C));
      });

      test('info is #1E3A8A (9.1:1 on light bg)', () {
        expect(AppColors.info, const Color(0xFF1E3A8A));
      });

      test('successBg is #D1FAE5 (pale tint for bg + dark text)', () {
        expect(AppColors.successBg, const Color(0xFFD1FAE5));
      });

      test('warningBg is #FFFBEB', () {
        expect(AppColors.warningBg, const Color(0xFFFFFBEB));
      });

      test('errorBg is #FEE2E2', () {
        expect(AppColors.errorBg, const Color(0xFFFEE2E2));
      });

      test('infoBg is #DBEAFE', () {
        expect(AppColors.infoBg, const Color(0xFFDBEAFE));
      });
    });

    group('WCAG AA contrast (v24.2 guarantee)', () {
      // Flutter 3.40+ exposes .r/.g/.b as 0..1 doubles. Older builds still
      // expose 0..255 ints via .red/.green/.blue. Use the 0..255 API since
      // it is stable across the 3.41 stable channel we're on.
      double luminance(Color c) {
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

      double contrast(Color a, Color b) {
        final la = luminance(a);
        final lb = luminance(b);
        final light = la > lb ? la : lb;
        final dark = la > lb ? lb : la;
        return (light + 0.05) / (dark + 0.05);
      }

      test('success on background meets AA (>=4.5:1)', () {
        expect(contrast(AppColors.success, AppColors.background) >= 4.5,
            isTrue);
      });

      test('warning on background meets AA', () {
        expect(contrast(AppColors.warning, AppColors.background) >= 4.5,
            isTrue);
      });

      test('error on background meets AA', () {
        expect(
            contrast(AppColors.error, AppColors.background) >= 4.5, isTrue);
      });

      test('info on background meets AA', () {
        expect(contrast(AppColors.info, AppColors.background) >= 4.5, isTrue);
      });

      test('textTertiary on background meets AA', () {
        expect(
            contrast(AppColors.textTertiary, AppColors.background) >= 4.5,
            isTrue);
      });

      test('white on accent meets AA', () {
        expect(
            contrast(AppColors.textOnPrimary, AppColors.accent) >= 4.5,
            isTrue);
      });
    });

    group('Dark mode colors', () {
      test('darkBackground is #0F172A', () {
        expect(AppColors.darkBackground, const Color(0xFF0F172A));
      });

      test('darkSurface is #1E293B', () {
        expect(AppColors.darkSurface, const Color(0xFF1E293B));
      });

      test('darkTextPrimary is #F1F5F9', () {
        expect(AppColors.darkTextPrimary, const Color(0xFFF1F5F9));
      });
    });
  });

  group('AppSpacing', () {
    test('xs is 4', () {
      expect(AppSpacing.xs, 4.0);
    });

    test('sm is 8', () {
      expect(AppSpacing.sm, 8.0);
    });

    test('md is 16', () {
      expect(AppSpacing.md, 16.0);
    });

    test('lg is 24', () {
      expect(AppSpacing.lg, 24.0);
    });

    test('xl is 32', () {
      expect(AppSpacing.xl, 32.0);
    });

    test('xxl is 48', () {
      expect(AppSpacing.xxl, 48.0);
    });

    test('spacing values are in ascending order', () {
      final spacings = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];
      for (var i = 0; i < spacings.length - 1; i++) {
        expect(spacings[i] < spacings[i + 1], isTrue,
            reason:
                'Spacing at index $i (${spacings[i]}) should be less than ${spacings[i + 1]}');
      }
    });
  });

  group('AppRadius', () {
    test('sm is 8', () {
      expect(AppRadius.sm, 8.0);
    });

    test('md is 12', () {
      expect(AppRadius.md, 12.0);
    });

    test('lg is 16', () {
      expect(AppRadius.lg, 16.0);
    });

    test('xl is 24', () {
      expect(AppRadius.xl, 24.0);
    });

    test('full is 999', () {
      expect(AppRadius.full, 999.0);
    });

    test('radius values are in ascending order', () {
      final radii = [
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
        AppRadius.full,
      ];
      for (var i = 0; i < radii.length - 1; i++) {
        expect(radii[i] < radii[i + 1], isTrue);
      }
    });
  });

  group('AppTheme', () {
    group('Light theme', () {
      late ThemeData lightTheme;

      setUp(() {
        lightTheme = AppTheme.lightTheme;
      });

      test('uses Material 3', () {
        expect(lightTheme.useMaterial3, isTrue);
      });

      test('font family is Inter', () {
        expect(lightTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      });

      test('scaffold background is AppColors.background', () {
        expect(
          lightTheme.scaffoldBackgroundColor,
          AppColors.background,
        );
      });

      test('brightness is light', () {
        expect(lightTheme.colorScheme.brightness, Brightness.light);
      });

      test('primary color matches AppColors.primary', () {
        expect(lightTheme.colorScheme.primary, AppColors.primary);
      });

      test('error color matches AppColors.error', () {
        expect(lightTheme.colorScheme.error, AppColors.error);
      });

      test('appBar has zero elevation', () {
        expect(lightTheme.appBarTheme.elevation, 0);
      });

      test('appBar title is centered', () {
        expect(lightTheme.appBarTheme.centerTitle, isTrue);
      });

      test('card elevation is zero', () {
        expect(lightTheme.cardTheme.elevation, 0);
      });

      test('elevated button background is primary', () {
        final style = lightTheme.elevatedButtonTheme.style;
        final bgColor = style?.backgroundColor?.resolve({});
        expect(bgColor, AppColors.primary);
      });

      test('bottom nav bar selected color is primary', () {
        expect(
          lightTheme.bottomNavigationBarTheme.selectedItemColor,
          AppColors.primary,
        );
      });
    });

    group('Dark theme', () {
      late ThemeData darkTheme;

      setUp(() {
        darkTheme = AppTheme.darkTheme;
      });

      test('uses Material 3', () {
        expect(darkTheme.useMaterial3, isTrue);
      });

      test('font family is Inter', () {
        expect(darkTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      });

      test('scaffold background is dark', () {
        expect(
          darkTheme.scaffoldBackgroundColor,
          AppColors.darkBackground,
        );
      });

      test('brightness is dark', () {
        expect(darkTheme.colorScheme.brightness, Brightness.dark);
      });

      test('appBar has zero elevation', () {
        expect(darkTheme.appBarTheme.elevation, 0);
      });

      test('card elevation is zero', () {
        expect(darkTheme.cardTheme.elevation, 0);
      });
    });
  });

  group('AppShadows', () {
    test('shadowSmall has exactly 1 shadow', () {
      expect(AppShadows.shadowSmall, hasLength(1));
    });

    test('shadowMedium has exactly 2 shadows', () {
      expect(AppShadows.shadowMedium, hasLength(2));
    });

    test('glowAccent has exactly 1 shadow', () {
      expect(AppShadows.glowAccent, hasLength(1));
    });

    test('glowPrimary has exactly 1 shadow', () {
      expect(AppShadows.glowPrimary, hasLength(1));
    });

    test('inputFocusShadow returns BoxDecoration', () {
      final decoration = AppShadows.inputFocusShadow();
      expect(decoration, isA<BoxDecoration>());
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, hasLength(1));
    });

    test('inputFocusShadow uses provided borderRadius', () {
      final decoration = AppShadows.inputFocusShadow(borderRadius: 20.0);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(20.0),
      );
    });
  });
}
