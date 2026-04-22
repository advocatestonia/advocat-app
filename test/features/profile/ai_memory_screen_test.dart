// Widget tests for the AI memory settings screen (ADR-001 Tier 1).
// -----------------------------------------------------------------------------
// Ref: lib/features/profile/screens/ai_memory_screen.dart
//      lib/services/user_memory_service.dart
//
// The UserMemoryService is swapped out for a fake via the Riverpod
// provider override — this lets us drive the UI without a Supabase
// client. Covers:
//   * loading / empty / populated states
//   * group header labels
//   * "Forget" per-row confirmation flow
//   * "Forget everything" confirmation flow
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/profile/screens/ai_memory_screen.dart';
import 'package:advocat/models/user_memory.dart';
import 'package:advocat/services/user_memory_service.dart';

/// In-memory stand-in that records calls — we override only what the
/// screen touches (getMemories / forget / forgetAll).
class _FakeUserMemoryService implements UserMemoryService {
  _FakeUserMemoryService(this._memories);

  List<UserMemory> _memories;
  final List<String> forgetCalls = [];
  int forgetAllCalls = 0;

  @override
  Future<List<UserMemory>> getMemories({int limit = 20}) async {
    return List.unmodifiable(_memories);
  }

  @override
  Future<void> forget(String memoryId) async {
    forgetCalls.add(memoryId);
    _memories = _memories.where((m) => m.id != memoryId).toList();
  }

  @override
  Future<void> forgetAll() async {
    forgetAllCalls++;
    _memories = const [];
  }

  @override
  Future<Map<String, int>?> extractFromSession({
    required List<({String role, String content})> messages,
    String? sessionId,
  }) async =>
      null;

  // Unused methods — noSuchMethod keeps the fake minimal.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

UserMemory _mem({
  required String id,
  required String key,
  required String text,
  double confidence = 0.9,
}) {
  final now = DateTime.utc(2026, 4, 23);
  return UserMemory(
    id: id,
    key: key,
    text: text,
    confidence: confidence,
    createdAt: now,
    lastReinforcedAt: now,
  );
}

ProviderScope _harness({
  required _FakeUserMemoryService fake,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      userMemoryServiceProvider.overrideWithValue(fake),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AiMemoryScreen', () {
    testWidgets(
      'empty memory shows the onboarding copy',
      (tester) async {
        final fake = _FakeUserMemoryService(const []);
        await tester.pumpWidget(
          _harness(fake: fake, child: const AiMemoryScreen()),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining("hasn't learned anything"),
          findsOneWidget,
        );
        // Forget-all CTA only makes sense when there's data — hidden here.
        expect(find.text('Forget everything'), findsNothing);
      },
    );

    testWidgets(
      'populated memory renders grouped facts + forget-all CTA',
      (tester) async {
        final fake = _FakeUserMemoryService([
          _mem(id: '1', key: 'tone', text: 'You prefer short replies'),
          _mem(id: '2', key: 'known_party', text: 'Your wife is Sofia'),
          _mem(id: '3', key: 'deadline', text: 'Hearing on 18.05.2026'),
        ]);
        await tester.pumpWidget(
          _harness(fake: fake, child: const AiMemoryScreen()),
        );
        await tester.pumpAndSettle();
        // Group headers — rendered uppercase, so match case-insensitively.
        expect(find.text('TONE'), findsOneWidget);
        expect(find.text('PEOPLE YOU MENTIONED'), findsOneWidget);
        expect(find.text('DEADLINES'), findsOneWidget);
        // Fact bodies.
        expect(find.text('You prefer short replies'), findsOneWidget);
        expect(find.text('Your wife is Sofia'), findsOneWidget);
        expect(find.text('Hearing on 18.05.2026'), findsOneWidget);
        // Forget-all button exists (may be below the fold on a small
        // test viewport — skipOffstage:false matches regardless).
        expect(
          find.text('Forget everything', skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Forget opens confirm dialog and removes the row on confirm',
      (tester) async {
        final fake = _FakeUserMemoryService([
          _mem(id: '1', key: 'tone', text: 'Short replies please'),
        ]);
        await tester.pumpWidget(
          _harness(fake: fake, child: const AiMemoryScreen()),
        );
        await tester.pumpAndSettle();

        // Tap the delete icon on the tile.
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Dialog is open.
        expect(find.text('Forget this?'), findsOneWidget);
        expect(find.textContaining('Short replies please'), findsWidgets);

        // Confirm.
        await tester.tap(find.widgetWithText(TextButton, 'Forget'));
        await tester.pumpAndSettle();

        expect(fake.forgetCalls, ['1']);
        expect(
          find.text('Short replies please'),
          findsNothing,
          reason: 'The row should disappear after the list refreshes.',
        );
      },
    );

    testWidgets(
      'tapping Forget but cancelling does NOT delete',
      (tester) async {
        final fake = _FakeUserMemoryService([
          _mem(id: '1', key: 'tone', text: 'Short replies please'),
        ]);
        await tester.pumpWidget(
          _harness(fake: fake, child: const AiMemoryScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(fake.forgetCalls, isEmpty);
        expect(find.text('Short replies please'), findsOneWidget);
      },
    );

    testWidgets(
      'Forget everything requires confirmation and wipes the list',
      (tester) async {
        final fake = _FakeUserMemoryService([
          _mem(id: '1', key: 'tone', text: 'A'),
          _mem(id: '2', key: 'background', text: 'B'),
        ]);
        await tester.pumpWidget(
          _harness(fake: fake, child: const AiMemoryScreen()),
        );
        await tester.pumpAndSettle();

        // Scroll to the bottom so the forget-all button is hit-testable.
        await tester.scrollUntilVisible(
          find.text('Forget everything'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Forget everything'));
        await tester.pumpAndSettle();

        expect(find.text('Forget everything?'), findsOneWidget);

        // Confirm — button label is also "Forget everything".
        // The dialog action button is a TextButton; the page button is an
        // OutlinedButton inside an OutlinedButton.icon — target the dialog
        // one by restricting to TextButton.
        await tester
            .tap(find.widgetWithText(TextButton, 'Forget everything'));
        await tester.pumpAndSettle();

        expect(fake.forgetAllCalls, 1);
        expect(find.text('A'), findsNothing);
        expect(find.text('B'), findsNothing);
      },
    );

    testWidgets(
      'route constants expose /profile/ai-memory',
      (tester) async {
        // Pin the route so the router registration cannot drift silently.
        expect(AiMemoryScreen.routePath, '/profile/ai-memory');
        expect(AiMemoryScreen.routeName, 'aiMemory');
      },
    );
  });
}
