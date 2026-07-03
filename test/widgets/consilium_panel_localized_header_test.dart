@Tags(['fast'])
library;

// =============================================================================
// consilium_panel_localized_header_test.dart
// -----------------------------------------------------------------------------
// Regression guard for the P1 i18n bug: ConsiliumPanel used to render its
// header from a hardcoded Russian default ('Консилиум юристов') because the
// chat_screen.dart call site constructed it with only key + events.
//
// The fix passes localized labels down from _buildMessageBubble
// (headerLabel: l.consiliumHeader, …). This test locks the mechanism the fix
// relies on: when a localized headerLabel is supplied, the panel renders THAT
// string and never the Russian default.
//
// We drive the panel via the @visibleForTesting fromSnapshot constructor so we
// don't need the sealed ChatStreamEvent stream — the same path the sibling
// consilium_panel_test.dart uses.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/consilium_panel.dart';

const _kRussianDefaultHeader = 'Консилиум юристов';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

ConsiliumSnapshot _startedSnap() => ConsiliumSnapshot.fromMaps([
      {
        'kind': 'start',
        'roster': ['Иммиграционный юрист'],
      },
      {
        'kind': 'opinion',
        'role': 'Иммиграционный юрист',
        'position': 'push',
        'confidence': 0.7,
        'opinion': 'X',
      },
    ]);

void main() {
  testWidgets(
      'localized headerLabel is rendered instead of the Russian default',
      (tester) async {
    const localized = 'Lawyer Consilium';

    await tester.pumpWidget(_wrap(
      ConsiliumPanel.fromSnapshot(
        snapshot: _startedSnap(),
        headerLabel: localized,
      ),
    ));
    await tester.pumpAndSettle();

    // The panel is visible…
    expect(find.byKey(const Key('consilium_panel')), findsOneWidget);
    // …and shows the localized header, NOT the hardcoded RU fallback.
    expect(find.text(localized), findsOneWidget);
    expect(find.text(_kRussianDefaultHeader), findsNothing);
  });

  testWidgets(
      'without an override the panel falls back to the RU default header',
      (tester) async {
    // Documents the pre-fix behaviour the call-site fix guards against:
    // constructing the panel with no headerLabel yields the Russian string.
    await tester.pumpWidget(_wrap(
      ConsiliumPanel.fromSnapshot(snapshot: _startedSnap()),
    ));
    await tester.pumpAndSettle();

    expect(find.text(_kRussianDefaultHeader), findsOneWidget);
  });
}
