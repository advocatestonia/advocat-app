@Tags(['fast'])
library;

// Widget tests for [SupportFab].
//
// We verify:
//   * The FAB renders an icon + Material when placed inside a Scaffold.
//   * Tapping the FAB opens the modal sheet (the sheet itself is exercised
//     in support_sheet_test.dart).
//   * The widget is keyboard/screen-reader reachable via Semantics.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/widgets/support/support_fab.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Stack(children: [child])),
    ),
  );
}

void main() {
  group('SupportFab — rendering', () {
    testWidgets('shows the support agent icon', (tester) async {
      await tester.pumpWidget(_wrap(const SupportFab()));
      await tester.pumpAndSettle();
      // v4 redesign (2026-05-19): switched from Icons.support_agent to
      // Icons.help_outline (Stripe-style help pill). See support_fab.dart §
      // "v4 redesign rationale".
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('exposes Semantics with button label', (tester) async {
      await tester.pumpWidget(_wrap(const SupportFab()));
      await tester.pumpAndSettle();
      final semanticsHandle = tester.ensureSemantics();
      // Semantics label is the support title from l10n — now 'Help' since
      // the supportTitle ARB string was shortened from 'Need help?' to 'Help'.
      expect(
        find.bySemanticsLabel('Help'),
        findsOneWidget,
      );
      semanticsHandle.dispose();
    });

    testWidgets('survives a bottomOffset override without throwing',
        (tester) async {
      await tester.pumpWidget(_wrap(const SupportFab(bottomOffset: 88)));
      await tester.pumpAndSettle();
      expect(find.byType(SupportFab), findsOneWidget);
    });
  });

  group('SupportFab — interactions', () {
    testWidgets('tap opens a modal sheet containing the title', (tester) async {
      await tester.pumpWidget(_wrap(const SupportFab()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      // Title appears as the support sheet header. Tooltip may also render.
      // (subtitle text was dropped from the v4 sheet redesign — see
      // support_sheet.dart which now uses supportFooterSla "We respond
      // within 24h" in the footer, not a subtitle at the top.)
      expect(find.text('Help'), findsWidgets);
    });
  });

  group('SupportFabVisibility', () {
    testWidgets('defaults to visible=true when not in tree', (tester) async {
      late bool seen;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) {
          seen = SupportFabVisibility.of(ctx);
          return const SizedBox.shrink();
        }),
      ));
      expect(seen, isTrue);
    });

    testWidgets('reads explicit visible=false', (tester) async {
      late bool seen;
      await tester.pumpWidget(MaterialApp(
        home: SupportFabVisibility(
          visible: false,
          child: Builder(builder: (ctx) {
            seen = SupportFabVisibility.of(ctx);
            return const SizedBox.shrink();
          }),
        ),
      ));
      expect(seen, isFalse);
    });
  });
}
