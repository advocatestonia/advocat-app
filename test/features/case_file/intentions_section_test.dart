// intentions_section_test.dart
// -----------------------------------------------------------------------------
// Widget tests for the "Pending follow-ups" section. We override the
// StateNotifierProvider with a fake holding deterministic items, then
// verify rendering, the cancel button hookup, and the empty-state hide
// behaviour.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/case_file/agent_intentions_providers.dart';
import 'package:advocat/features/case_file/widgets/pending_intentions_section.dart';
import 'package:advocat/services/supabase_service.dart';

class _FakeIntentionsNotifier extends AgentIntentionsNotifier {
  _FakeIntentionsNotifier(super.supabase, AgentIntentionsState initial) {
    state = initial;
  }

  final List<String> cancelled = [];

  @override
  Future<void> refresh() async {/* no-op */}

  @override
  Future<void> bind({String? caseId}) async {/* no-op */}

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
    );
  }
}

Widget _wrap(Widget child, {required AgentIntentionsState seed}) {
  late _FakeIntentionsNotifier notifier;
  return ProviderScope(
    overrides: [
      agentIntentionsProvider.overrideWith((ref) {
        notifier = _FakeIntentionsNotifier(SupabaseService(), seed);
        return notifier;
      }),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

AgentIntentionEntry _entry({
  String id = 'i1',
  String type = 'remind_deadline',
  DateTime? when,
  String summary = 'appeal deadline',
  String? targetId,
}) =>
    AgentIntentionEntry(
      id: id,
      caseId: null,
      intentType: type,
      targetId: targetId,
      nextCheckAt: when ?? DateTime.utc(2026, 6, 5, 10),
      summary: summary,
      locale: 'en',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PendingIntentionsSection — rendering', () {
    testWidgets('hides itself when no intentions are pending', (tester) async {
      await tester.pumpWidget(_wrap(
        const PendingIntentionsSection(),
        seed: const AgentIntentionsState(items: [], loading: false),
      ));
      // Section heading must be absent.
      expect(find.text('Pending follow-ups'), findsNothing);
      expect(find.byKey(const Key('pending_intentions_section')), findsNothing);
    });

    testWidgets('hides while loading (screen-level spinner covers it)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const PendingIntentionsSection(),
        seed: const AgentIntentionsState(items: [], loading: true),
      ));
      expect(find.text('Pending follow-ups'), findsNothing);
    });

    testWidgets('renders header + one row per intention', (tester) async {
      await tester.pumpWidget(_wrap(
        const PendingIntentionsSection(),
        seed: AgentIntentionsState(items: [
          _entry(id: 'i1', summary: 'Appeal deadline 30 days'),
          _entry(
            id: 'i2',
            type: 'check_court_status',
            targetId: 'R-2025/123',
            summary: 'Sulga',
          ),
        ]),
      ));
      await tester.pump();

      expect(find.text('Pending follow-ups'), findsOneWidget);
      expect(find.byKey(const Key('intention_row_i1')), findsOneWidget);
      expect(find.byKey(const Key('intention_row_i2')), findsOneWidget);
      // Date (YYYY-MM-DD) appears in the row.
      expect(find.text('2026-06-05'), findsWidgets);
      // Type labels are humanised.
      expect(find.text('Deadline reminder'), findsOneWidget);
      expect(find.text('Court status check'), findsOneWidget);
      // Summary text shows.
      expect(find.text('Appeal deadline 30 days'), findsOneWidget);
    });

    testWidgets('every row has its own cancel button', (tester) async {
      await tester.pumpWidget(_wrap(
        const PendingIntentionsSection(),
        seed: AgentIntentionsState(items: [
          _entry(id: 'i1'),
          _entry(id: 'i2'),
        ]),
      ));
      expect(find.byKey(const Key('intention_cancel_i1')), findsOneWidget);
      expect(find.byKey(const Key('intention_cancel_i2')), findsOneWidget);
    });
  });

  group('PendingIntentionsSection — cancel action', () {
    testWidgets('tapping Cancel removes the row from the list',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const PendingIntentionsSection(),
        seed: AgentIntentionsState(items: [
          _entry(id: 'i1', summary: 'will be cancelled'),
          _entry(id: 'i2', summary: 'remains'),
        ]),
      ));
      await tester.pump();

      expect(find.byKey(const Key('intention_row_i1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('intention_cancel_i1')));
      await tester.pump();

      expect(find.byKey(const Key('intention_row_i1')), findsNothing);
      expect(find.byKey(const Key('intention_row_i2')), findsOneWidget);
    });
  });

  group('AgentIntentionEntry.fromRow', () {
    test('parses a typical intention row', () {
      final entry = AgentIntentionEntry.fromRow({
        'id': 'abc',
        'case_id': 'case-1',
        'intent_type': 'remind_deadline',
        'target_id': 'R-2025/123',
        'next_check_at': '2026-06-05T10:00:00Z',
        'conversation_context': {'summary': 'appeal', 'locale': 'ru'},
      });
      expect(entry.id, 'abc');
      expect(entry.caseId, 'case-1');
      expect(entry.intentType, 'remind_deadline');
      expect(entry.targetId, 'R-2025/123');
      expect(entry.nextCheckAt.toUtc().year, 2026);
      expect(entry.summary, 'appeal');
      expect(entry.locale, 'ru');
    });

    test('falls back gracefully when conversation_context is missing', () {
      final entry = AgentIntentionEntry.fromRow({
        'id': 'abc',
        'intent_type': 'follow_up_question',
        'next_check_at': '2026-06-05T10:00:00Z',
      });
      expect(entry.summary, isEmpty);
      expect(entry.locale, 'en');
    });
  });
}
