@Tags(['fast'])
library;

// Widget tests for [ForFirmsScreen].
//
// What's covered (per brief 2026-05-25):
//   * Renders the heading + 3 "what's included" cards.
//   * Empty submit shows validation errors.
//   * Valid submit calls B2BService.submitInquiry exactly once and shows
//     the confirmation panel.
//   * On submit failure the user sees a SnackBar with a Retry action.
//
// We override [b2bServiceProvider] with a fake service so the test never
// hits Supabase. Riverpod's override mechanism replaces the provider
// graph for the duration of the test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/b2b/screens/for_firms_screen.dart';
import 'package:advocat/features/b2b/services/b2b_service.dart';
import 'package:advocat/l10n/app_localizations.dart';

/// Records every submitInquiry call so the test can assert exactly what
/// the screen sent.
class _FakeB2BService implements B2BService {
  _FakeB2BService({this.shouldSucceed = true});

  bool shouldSucceed;
  int callCount = 0;
  Map<String, dynamic>? lastArgs;

  @override
  Future<B2BInquiryResult> submitInquiry({
    required String name,
    required String email,
    required String firmName,
    required String teamSize,
    required List<String> practices,
    required String biggestPainToday,
    String? language,
    String? appVersion,
  }) async {
    callCount++;
    lastArgs = {
      'name': name,
      'email': email,
      'firm_name': firmName,
      'team_size': teamSize,
      'practices': practices,
      'biggest_pain_today': biggestPainToday,
      'language': language,
    };
    if (shouldSucceed) {
      return const B2BInquiryResult.ok('fake-ticket-id');
    }
    return const B2BInquiryResult.error('server_500');
  }

  @override
  Future<bool> fetchB2BModalPending() async => false;

  @override
  Future<void> markB2BModalShown() async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _wrap(B2BService service, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      b2bServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ForFirmsScreen(),
    ),
  );
}

void main() {
  group('ForFirmsScreen — rendering', () {
    testWidgets('renders heading, included cards, and all form fields',
        (tester) async {
      await tester.pumpWidget(_wrap(_FakeB2BService()));
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('Advocat for Law Firms'), findsOneWidget);

      // All form fields are present
      expect(find.byKey(ForFirmsScreenKeys.nameField), findsOneWidget);
      expect(find.byKey(ForFirmsScreenKeys.emailField), findsOneWidget);
      expect(find.byKey(ForFirmsScreenKeys.firmField), findsOneWidget);
      expect(find.byKey(ForFirmsScreenKeys.teamSizeField), findsOneWidget);
      expect(find.byKey(ForFirmsScreenKeys.practicesField), findsOneWidget);
      expect(find.byKey(ForFirmsScreenKeys.painField), findsOneWidget);
      expect(find.byKey(ForFirmsScreenKeys.submit), findsOneWidget);

      // 3 "what's included" cards — check by title.
      expect(find.text('Multi-seat workspace'), findsOneWidget);
      expect(find.text('Shared cases & dossiers'), findsOneWidget);
      expect(find.text('Audit log & SSO'), findsOneWidget);
    });

    testWidgets('renders Estonian heading for locale et', (tester) async {
      await tester.pumpWidget(_wrap(_FakeB2BService(),
          locale: const Locale('et')));
      await tester.pumpAndSettle();
      expect(
        find.text('Advocat advokaadibüroodele'),
        findsOneWidget,
      );
    });
  });

  group('ForFirmsScreen — validation + submit', () {
    testWidgets('empty submit shows validation errors and does NOT call submit',
        (tester) async {
      final svc = _FakeB2BService();
      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      // Scroll the submit button into view (form has many fields).
      await tester.ensureVisible(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pumpAndSettle();

      // 'Required' should appear at least once (name + firm + pain).
      expect(find.text('Required'), findsWidgets);
      expect(svc.callCount, 0,
          reason: 'invalid form must not round-trip to the service');
    });

    testWidgets('valid submit calls submitInquiry once and shows confirmation',
        (tester) async {
      final svc = _FakeB2BService();
      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      // Fill required fields. Email is pre-validated by a regex so we
      // need a syntactically valid address.
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.nameField),
        'Anna Lawyer',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.emailField),
        'anna@kovacic-legal.ee',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.firmField),
        'Kovacic Legal OÜ',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.painField),
        'Multiple lawyers want to share AI history on the same matter.',
      );

      await tester.ensureVisible(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ForFirmsScreenKeys.submit));
      // Two pumps: one for the async, one for the confirmation render.
      await tester.pumpAndSettle();

      expect(svc.callCount, 1);
      expect(svc.lastArgs?['name'], 'Anna Lawyer');
      expect(svc.lastArgs?['email'], 'anna@kovacic-legal.ee');
      expect(svc.lastArgs?['firm_name'], 'Kovacic Legal OÜ');
      expect(svc.lastArgs?['team_size'], '1'); // default bucket

      // Confirmation panel is now showing.
      expect(find.byKey(ForFirmsScreenKeys.confirmation), findsOneWidget);
      expect(find.text('Thank you!'), findsOneWidget);
    });

    testWidgets('submit failure shows SnackBar with Retry action',
        (tester) async {
      final svc = _FakeB2BService(shouldSucceed: false);
      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.nameField),
        'Anna',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.emailField),
        'anna@firm.test',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.firmField),
        'A&A',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.painField),
        'Lots of pain.',
      );

      await tester.ensureVisible(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pump(); // surface SnackBar
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // We should NOT have rendered the confirmation panel.
      expect(find.byKey(ForFirmsScreenKeys.confirmation), findsNothing);
    });

    testWidgets('invalid email shows validation error', (tester) async {
      final svc = _FakeB2BService();
      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.nameField),
        'Anna',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.emailField),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.firmField),
        'A&A',
      );
      await tester.enterText(
        find.byKey(ForFirmsScreenKeys.painField),
        'A long enough pain description for validation purposes.',
      );

      await tester.ensureVisible(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ForFirmsScreenKeys.submit));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(svc.callCount, 0);
    });
  });
}
