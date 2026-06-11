@Tags(['fast'])
library;

// =============================================================================
// Regression guard — AI Act disclaimer modal must fire from HomeScreen.
// =============================================================================
//
// Audit 2026-06-11: `register()` routes brand-new users straight to /home
// and the router blocks authenticated users from /onboarding — so the
// EU AI Act Art. 50(1) "you are talking to AI, not a lawyer" modal (which
// only fired from the onboarding screen) was NEVER shown to users who
// signed up in-app.
//
// Fix: `HomeScreen._checkFirstTimeOnboarding` now mirrors the onboarding
// trigger — `AiDisclaimerBanner.shouldShowModal()` gate + one-shot
// `AiDisclaimerBanner.modal` dialog — before the welcome modal, sharing
// the `ai_disclaimer_modal_seen_v1` prefs key so the modal shows at most
// once per device regardless of which surface fired first.
//
// Test shape follows `home_screen_modal_priority_test.dart`: source-string
// assertions for the HomeScreen integration site (the full screen needs
// Supabase + Riverpod + GoRouter scaffolding), behavioural widget tests
// for the trigger flow itself.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/shared/widgets/ai_disclaimer_banner.dart';

/// Minimal harness that replicates the HomeScreen trigger verbatim:
/// post-frame, check [AiDisclaimerBanner.shouldShowModal], then show the
/// one-shot modal dialog.
class _HomeDisclaimerHarness extends StatefulWidget {
  const _HomeDisclaimerHarness();

  @override
  State<_HomeDisclaimerHarness> createState() => _HomeDisclaimerHarnessState();
}

class _HomeDisclaimerHarnessState extends State<_HomeDisclaimerHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final showDisclaimer = await AiDisclaimerBanner.shouldShowModal();
      if (showDisclaimer && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AiDisclaimerBanner.modal(
            key: Key('home_ai_disclaimer_modal'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen source — AI disclaimer modal wired into bootstrap', () {
    late String source;

    setUpAll(() {
      source =
          File('lib/features/home/screens/home_screen.dart').readAsStringSync();
    });

    test('_checkFirstTimeOnboarding gates on AiDisclaimerBanner.shouldShowModal',
        () {
      final onboardingIdx = source.indexOf('_checkFirstTimeOnboarding() async');
      expect(onboardingIdx, greaterThan(0),
          reason: 'first-time onboarding hook must exist');
      final body = source.substring(onboardingIdx);
      final disclaimerIdx =
          body.indexOf('AiDisclaimerBanner.shouldShowModal()');
      expect(disclaimerIdx, greaterThan(0),
          reason: 'AI Act Art. 50(1) — home bootstrap must check the '
              'disclaimer-modal gate (register() bypasses /onboarding)');

      // The disclaimer must run BEFORE the welcome-modal seen short-circuit,
      // so existing users who never passed /onboarding still get it once.
      final welcomeIdx = body.indexOf('_welcomeModalSeenKey');
      expect(disclaimerIdx, lessThan(welcomeIdx),
          reason: 'disclaimer gate must precede the welcome-modal seen check');
    });

    test('home shows the one-shot AiDisclaimerBanner.modal dialog', () {
      expect(source.contains("Key('home_ai_disclaimer_modal')"), isTrue,
          reason: 'modal dialog must carry a stable key for QA/tests');
      expect(source.contains('AiDisclaimerBanner.modal('), isTrue,
          reason: 'home must reuse the shared modal variant (same prefs key '
              'as the onboarding screen — no double-show)');
    });
  });

  group('disclaimer modal trigger — behavioural flow', () {
    testWidgets('first home visit shows the modal once', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(_wrap(const _HomeDisclaimerHarness()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_ai_disclaimer_modal')), findsOneWidget);
      expect(find.text('Important: how Advocat works'), findsOneWidget);
    });

    testWidgets('dismissing the modal persists seen flag — no re-show',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(_wrap(const _HomeDisclaimerHarness()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai_disclaimer_modal_dismiss')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_ai_disclaimer_modal')), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kAiDisclaimerModalSeenKey), isTrue,
          reason: 'dismissal must persist under ai_disclaimer_modal_seen_v1');

      // Second cold start — the gate must hold.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_wrap(const _HomeDisclaimerHarness()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_ai_disclaimer_modal')), findsNothing);
    });

    testWidgets('modal already seen via /onboarding → home does not re-show',
        (tester) async {
      // Shared key: a user who DID pass through the onboarding screen has
      // the flag set; home must not show the modal a second time.
      SharedPreferences.setMockInitialValues(<String, Object>{
        kAiDisclaimerModalSeenKey: true,
      });

      await tester.pumpWidget(_wrap(const _HomeDisclaimerHarness()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_ai_disclaimer_modal')), findsNothing);
    });
  });
}
