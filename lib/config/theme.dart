import 'package:flutter/material.dart';

/// Design tokens for the AI Legal Defense brand.
abstract final class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1A365D);
  static const Color primaryLight = Color(0xFF2A4A7F);
  static const Color primaryDark = Color(0xFF0F2240);

  // Accent / teal — shifted darker for WCAG AA (4.5:1 white text on teal)
  static const Color accent = Color(0xFF0B7A70);        // 4.6:1 white — AA normal
  static const Color accentLight = Color(0xFF0D9488);   // was "accent" — now AA-large only
  static const Color accentDark = Color(0xFF074F49);
  // Tint for non-text decoration only (do NOT place white text on this):
  static const Color accentTint = Color(0xFF14B8A6);    // bg tints, icons on dark bg

  // Neutrals — warm tones matching landing page (#F0EEEB)
  static const Color background = Color(0xFFF0EEEB);
  static const Color surface = Color(0xFFF7F6F4);
  static const Color surfaceVariant = Color(0xFFEAE8E5);
  static const Color border = Color(0xFFDCD9D5);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  // textTertiary raised to match textSecondary (6.54:1 AA). For decorative
  // labels that need a visually lighter variant, pair with a larger font.
  static const Color textTertiary = Color(0xFF475569);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic — all shifted for WCAG AA on light bg
  static const Color success = Color(0xFF14532D);       // 10.5:1
  static const Color warning = Color(0xFF92400E);       // 7.3:1
  static const Color error = Color(0xFFB91C1C);         // 5.8:1
  static const Color info = Color(0xFF1E3A8A);          // 9.1:1
  static const Color infoDark = Color(0xFF1D4ED8);

  // Semantic background tints (safe for colored surface + dark text on top)
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color infoBg = Color(0xFFDBEAFE);

  // Dark mode overrides
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Dark mode accent (Tailwind teal-500). 7.17:1 vs darkBackground and
  // 5.88:1 vs darkSurface — both pass WCAG AA for body text as FOREGROUND.
  // When used as a BACKGROUND fill (button, FAB, switch thumb), pair with
  // dark text (textPrimary #0F172A) — white on #14B8A6 is only 2.49:1.
  static const Color darkAccent = Color(0xFF14B8A6);

  // Dark mode error (Tailwind red-400). 6.45:1 on darkBackground — AA.
  // Brand error #B91C1C only achieves 2.76:1 on dark bg, so we lighten.
  static const Color darkError = Color(0xFFF87171);

  // Dark text-on-accent — use textPrimary (near-black) because accent is
  // bright enough that white text fails AA on it.
  static const Color darkTextOnAccent = Color(0xFF0F172A);
}

/// Shadow and glow design tokens.
abstract final class AppShadows {
  /// Subtle card shadow.
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x0D000000), // black 5%
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Elevated elements shadow.
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x14000000), // black 8%
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000), // black 4%
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Teal glow for accent buttons.
  static const List<BoxShadow> glowAccent = [
    BoxShadow(
      color: Color(0x4D0D9488), // accent with ~0.3 alpha
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Navy glow for primary elements.
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x4D1A365D), // primary with ~0.3 alpha
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Focus shadow decoration for text fields.
  static BoxDecoration inputFocusShadow({
    double borderRadius = AppRadius.sm,
    Color glowColor = const Color(0x261A365D), // primary ~0.15 alpha
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: glowColor,
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );
  }
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

/// Application theme definitions.
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

  // ── Light Theme ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: BorderSide.none,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────
  //
  // WCAG AA contrast verified (2026-05-27):
  //   darkAccent   #14B8A6 on darkBackground = 7.17:1 (AA body text)
  //   darkAccent   #14B8A6 on darkSurface    = 5.88:1 (AA body text)
  //   darkError    #F87171 on darkBackground = 6.45:1 (AA body text)
  //   darkTextPrim #F1F5F9 on darkBackground = 16.30:1
  //   darkTextPrim #F1F5F9 on darkSurface    = 13.35:1
  //
  // Button fills using darkAccent pair with darkTextOnAccent (#0F172A,
  // near-black) — white on #14B8A6 is only 2.49:1 and would fail AA.
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.darkAccent,
      onPrimary: AppColors.darkTextOnAccent,
      secondary: AppColors.accentTint,
      onSecondary: AppColors.darkTextOnAccent,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      error: AppColors.darkError,
      onError: AppColors.darkTextOnAccent,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      // ── Card ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      // ── ElevatedButton ──────────────────────────────────────────────
      // darkAccent fill + darkTextOnAccent label. Body-text contrast on
      // the button itself: 0F172A on 14B8A6 = 7.17:1 (AA-AAA).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkTextOnAccent,
          disabledBackgroundColor: AppColors.darkSurfaceVariant,
          disabledForegroundColor: AppColors.darkTextSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // ── OutlinedButton ──────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: const BorderSide(color: AppColors.darkAccent),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // ── TextButton ──────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // ── Input ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.darkAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      // ── Divider ─────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      // ── BottomNavigationBar ─────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkAccent,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // ── Chip ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.darkAccent,
        secondarySelectedColor: AppColors.darkAccent,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextOnAccent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      // ── FloatingActionButton ────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: AppColors.darkTextOnAccent,
        elevation: 4,
      ),
      // ── Switch ──────────────────────────────────────────────────────
      // Selected = accent fill, dark thumb (AA contrast on accent).
      // Unselected = surfaceVariant track, secondary-text thumb.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkTextOnAccent;
          }
          return AppColors.darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccent;
          }
          return AppColors.darkSurfaceVariant;
        }),
        trackOutlineColor:
            WidgetStateProperty.all<Color>(AppColors.darkBorder),
      ),
      // ── Slider ──────────────────────────────────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.darkAccent,
        inactiveTrackColor: AppColors.darkSurfaceVariant,
        thumbColor: AppColors.darkAccent,
        overlayColor: Color(0x3314B8A6), // darkAccent @ 20%
        valueIndicatorColor: AppColors.darkAccent,
        valueIndicatorTextStyle: TextStyle(
          color: AppColors.darkTextOnAccent,
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ── SnackBar ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontFamily: _fontFamily,
          fontSize: 14,
        ),
        actionTextColor: AppColors.darkAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 6,
      ),
      // ── Dialog ──────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontFamily: _fontFamily,
          fontSize: 14,
        ),
      ),
      // ── Drawer ──────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.md),
            bottomRight: Radius.circular(AppRadius.md),
          ),
        ),
      ),
      // ── ListTile ────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.darkSurfaceVariant,
        iconColor: AppColors.darkTextSecondary,
        selectedColor: AppColors.darkAccent,
        textColor: AppColors.darkTextPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontFamily: _fontFamily,
          fontSize: 13,
        ),
      ),
    );
  }
}
