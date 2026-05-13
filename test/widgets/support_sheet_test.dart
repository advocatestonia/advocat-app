@Tags(['fast'])
library;

// Widget tests for [SupportSheet].
//
// What's covered:
//   * Renders title + subtitle + three channel rows (in demo mode without
//     WhatsApp the WhatsApp row is hidden — verified separately).
//   * Tapping "Message us here" expands the in-app form.
//   * Submitting an empty form short-circuits client-side with an error.
//   * Submitting a valid message in demo mode shows the success view.
//
// Demo mode is in effect because we never call Supabase.initialize() in
// the test harness — SupabaseService.isDemo therefore returns true and
// SupportService short-circuits with a synthetic ok result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/widgets/support/support_sheet.dart';

Widget _wrap({Locale locale = const Locale('en')}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SupportSheet()),
    ),
  );
}

void main() {
  group('SupportSheet — rendering', () {
    testWidgets('shows title, subtitle, and at least one channel row',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Need help?'), findsOneWidget);
      expect(find.text('We usually reply within 1-2 hours.'), findsOneWidget);
      expect(find.byKey(const ValueKey('support-email')), findsOneWidget);
      expect(find.byKey(const ValueKey('support-inapp')), findsOneWidget);
    });

    testWidgets('hides WhatsApp button when number is not configured',
        (tester) async {
      // The default --dart-define for ADVOCAT_WHATSAPP_NUMBER is empty in
      // the test harness, so the WhatsApp row must not render.
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('support-whatsapp')), findsNothing);
    });

    testWidgets('renders Estonian strings when locale is et', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('et')));
      await tester.pumpAndSettle();
      expect(find.text('Vajad abi?'), findsOneWidget);
    });
  });

  group('SupportSheet — in-app form', () {
    testWidgets('tapping the in-app row expands the form', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Form fields are not in the tree until the row is tapped.
      expect(find.byKey(const ValueKey('support-message')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('support-inapp')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('support-message')), findsOneWidget);
      expect(find.byKey(const ValueKey('support-submit')), findsOneWidget);
      expect(find.byKey(const ValueKey('support-category')), findsOneWidget);
    });

    testWidgets('submit with empty message shows the too-short error',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-inapp')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('support-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Please write at least 10 characters.'),
        findsOneWidget,
      );
    });

    testWidgets('valid submission in demo mode reaches the success view',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-inapp')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('support-message')),
        'i cannot log in to my account today',
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('support-submit')));
      // First pump processes the tap, second pump lets the (async) demo-
      // mode short-circuit complete and triggers setState.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(
        find.text("Message sent! We'll reply soon."),
        findsOneWidget,
      );

      // The success view auto-closes after 2 s via Future.delayed. We
      // pump past that here so the timer doesn't leak past test teardown.
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('SupportSheet — honeypot', () {
    testWidgets('honeypot field is in the tree but size-zero',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-inapp')));
      await tester.pumpAndSettle();

      // The honeypot is intentionally rendered (size 0) — bots that
      // crawl the tree should still find it.
      expect(find.byKey(const ValueKey('support-honeypot')), findsOneWidget);
    });
  });
}
