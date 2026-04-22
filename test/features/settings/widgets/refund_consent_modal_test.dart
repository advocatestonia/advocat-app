// Widget tests for the refund consent modal.
//
// Pins the UX contract that protects EU CRD Art. 16(m) waiver integrity:
//
//   1. The modal renders title + body + checkbox + button on first frame.
//   2. The primary action is DISABLED until the checkbox is ticked —
//      otherwise a stray tap could record a waiver without explicit intent.
//   3. Ticking the checkbox enables the button.
//   4. Pressing the button invokes the onLogConsent hook exactly once,
//      then pops with result `true`.
//   5. When onLogConsent fails, the modal still proceeds with `true` —
//      the caller must not lose the user's intent on a network blip; the
//      server can reconcile via first_message_at.
//   6. Repeated taps during submit do not trigger the hook a second time.
//
// These tests use the exposed `onLogConsent` override so nothing hits
// Supabase. No localizations are installed — the modal's null-safe
// fallbacks are exercised instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/settings/widgets/refund_consent_modal.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('RefundConsentModal — render', () {
    testWidgets('renders title + body + checkbox + button', (tester) async {
      await _pump(tester, const RefundConsentModal());

      // Null-safe defaults kick in when no localizations are installed.
      expect(find.text('Before you begin'), findsOneWidget);
      expect(find.textContaining('14 days'), findsOneWidget);
      expect(
        find.text('I understand and agree to begin using the service'),
        findsOneWidget,
      );
      expect(find.text('Begin'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  group('RefundConsentModal — checkbox gating', () {
    testWidgets('Begin button is disabled until checkbox ticked',
        (tester) async {
      var called = 0;
      await _pump(
        tester,
        RefundConsentModal(
          onLogConsent: () async {
            called++;
            return true;
          },
        ),
      );

      // Button exists but is disabled (onPressed == null).
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);

      // Pressing it does nothing.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(called, 0);
    });

    testWidgets('ticking checkbox enables Begin', (tester) async {
      await _pump(tester, const RefundConsentModal());

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('RefundConsentModal — submit', () {
    testWidgets('invokes onLogConsent exactly once when Begin pressed',
        (tester) async {
      var called = 0;
      bool? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  poppedResult = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => RefundConsentModal(
                      onLogConsent: () async {
                        called++;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Begin'));
      await tester.pumpAndSettle();

      expect(called, 1);
      expect(poppedResult, isTrue);
    });

    testWidgets('still returns true when onLogConsent fails', (tester) async {
      bool? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  poppedResult = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => RefundConsentModal(
                      onLogConsent: () async => false,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Begin'));
      await tester.pumpAndSettle();

      // Server reconciliation handles missing audit row — user proceeds.
      expect(poppedResult, isTrue);
    });

    testWidgets('re-tapping Begin during an in-flight submit does not '
        're-invoke onLogConsent', (tester) async {
      var called = 0;
      // Slow hook so we can observe the in-flight state.
      Future<bool> slowHook() async {
        called++;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return true;
      }

      await _pump(
        tester,
        RefundConsentModal(onLogConsent: slowHook),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // First tap: starts the submit.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Begin'));
      await tester.pump();

      // While the hook is in flight the button is disabled + shows spinner.
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );
      final inFlightBtn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(inFlightBtn.onPressed, isNull,
          reason: 'Must be disabled during submit');

      // Try to tap the spinner/button again — should be a no-op because
      // onPressed is null.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // Let the hook finish.
      await tester.pump(const Duration(milliseconds: 250));

      expect(called, 1);
    });
  });
}
