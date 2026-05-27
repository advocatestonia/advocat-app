@Tags(['fast'])
library;

// =============================================================================
// AiDisclaimerBanner — widget + persistence tests.
//
// Covers:
//   * Compact variant renders the localized 1-line copy (EN + ET)
//   * Tapping the compact banner opens a bottom sheet with the full body
//   * Compact dismissal writes an ISO timestamp under
//     `ai_disclaimer_dismissed_v1` and the banner hides; after 7 days it
//     re-shows.
//   * Modal variant has a dismiss button that writes `ai_disclaimer_modal_seen_v1`
//   * Compact and modal dismissals are independent (separate keys)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/shared/widgets/ai_disclaimer_banner.dart';

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('et'),
      Locale('fi'),
      Locale('ru'),
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // ── Compact: renders localized copy ──────────────────────────────────

  group('AiDisclaimerBanner.compact — renders localized copy', () {
    testWidgets('English locale shows English compact text', (tester) async {
      await tester.pumpWidget(_wrap(const AiDisclaimerBanner.compact()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('AI legal information'),
        findsOneWidget,
        reason: 'EN compact copy must mention "AI legal information".',
      );
      expect(find.text('Learn more'), findsOneWidget);
    });

    testWidgets('Estonian locale shows Estonian compact text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AiDisclaimerBanner.compact(),
          locale: const Locale('et'),
        ),
      );
      await tester.pumpAndSettle();

      // Estonian-only word that uniquely identifies the ET translation —
      // English copy never contains 'õigusinfot'.
      expect(
        find.textContaining('õigusinfot'),
        findsOneWidget,
        reason: 'ET compact copy must use the Estonian translation, '
            'verifying ARB wiring for the et locale.',
      );
      expect(find.text('Loe rohkem'), findsOneWidget);
    });
  });

  // ── Compact: tap to expand opens sheet with full body ────────────────

  group('AiDisclaimerBanner.compact — tap to expand', () {
    testWidgets('tapping the banner opens a sheet containing the full body',
        (tester) async {
      await tester.pumpWidget(_wrap(const AiDisclaimerBanner.compact()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_disclaimer_compact_root')));
      await tester.pumpAndSettle();

      // Title from the full sheet.
      expect(
        find.text('Important: how Advocat works'),
        findsOneWidget,
        reason: 'Tap should open a sheet with the full title.',
      );
      // A phrase unique to the long-form body, not present in the compact text.
      expect(
        find.textContaining('attorney-client privilege'),
        findsOneWidget,
        reason: 'Sheet body must contain the privilege-disclaimer paragraph.',
      );
    });
  });

  // ── Compact: dismissal persists with 7-day expiry ────────────────────

  group('AiDisclaimerBanner.compact — dismissal persistence (7-day)', () {
    testWidgets('shouldShowCompact() returns true when no preference is set',
        (tester) async {
      expect(await AiDisclaimerBanner.shouldShowCompact(), isTrue);
    });

    testWidgets('markCompactDismissed() writes ISO timestamp and hides banner',
        (tester) async {
      await AiDisclaimerBanner.markCompactDismissed();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(kAiDisclaimerCompactDismissedAtKey);
      expect(stored, isNotNull);
      expect(
        DateTime.tryParse(stored!),
        isNotNull,
        reason: 'Dismissal value must be a valid ISO-8601 timestamp.',
      );

      expect(
        await AiDisclaimerBanner.shouldShowCompact(),
        isFalse,
        reason: 'Fresh dismissal (now) is well inside the 7-day window.',
      );
    });

    testWidgets('banner re-shows after the 7-day window elapses',
        (tester) async {
      // Simulate a dismissal 8 days ago.
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      SharedPreferences.setMockInitialValues(<String, Object>{
        kAiDisclaimerCompactDismissedAtKey: eightDaysAgo.toIso8601String(),
      });

      expect(
        await AiDisclaimerBanner.shouldShowCompact(),
        isTrue,
        reason:
            'After ${kAiDisclaimerCompactReshowAfter.inDays} days the banner '
            'must re-show automatically.',
      );
    });

    testWidgets('banner stays hidden during the 7-day window', (tester) async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      SharedPreferences.setMockInitialValues(<String, Object>{
        kAiDisclaimerCompactDismissedAtKey: threeDaysAgo.toIso8601String(),
      });

      expect(await AiDisclaimerBanner.shouldShowCompact(), isFalse);
    });
  });

  // ── Modal: dismiss button + separate persistence key ─────────────────

  group('AiDisclaimerBanner.modal — dismiss + separate persistence', () {
    testWidgets('renders dismiss button and full title in EN', (tester) async {
      await tester.pumpWidget(_wrap(const AiDisclaimerBanner.modal()));
      await tester.pumpAndSettle();

      expect(find.text('Important: how Advocat works'), findsOneWidget);
      expect(find.text('OK, I understand'), findsOneWidget);
      expect(
        find.byKey(const Key('ai_disclaimer_modal_dismiss')),
        findsOneWidget,
      );
    });

    testWidgets('shouldShowModal() returns true when unseen', (tester) async {
      expect(await AiDisclaimerBanner.shouldShowModal(), isTrue);
    });

    testWidgets(
        'markModalSeen() writes `ai_disclaimer_modal_seen_v1` and hides modal',
        (tester) async {
      await AiDisclaimerBanner.markModalSeen();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kAiDisclaimerModalSeenKey), isTrue);

      expect(await AiDisclaimerBanner.shouldShowModal(), isFalse);
    });

    testWidgets('modal and compact dismissals use independent keys',
        (tester) async {
      // Dismiss the compact banner only.
      await AiDisclaimerBanner.markCompactDismissed();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(kAiDisclaimerCompactDismissedAtKey),
        isNotNull,
        reason: 'Compact dismissal must write its own key.',
      );
      expect(
        prefs.getBool(kAiDisclaimerModalSeenKey),
        isNull,
        reason:
            'Compact dismissal must NOT touch the modal key (independent '
            'persistence — modal still appears on next onboarding).',
      );

      // Now mark modal seen — compact key must remain.
      await AiDisclaimerBanner.markModalSeen();
      expect(
        prefs.getString(kAiDisclaimerCompactDismissedAtKey),
        isNotNull,
        reason: 'Modal-seen must NOT clear the compact dismissal timestamp.',
      );
      expect(prefs.getBool(kAiDisclaimerModalSeenKey), isTrue);
    });
  });
}
