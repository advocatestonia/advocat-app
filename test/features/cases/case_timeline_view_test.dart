@Tags(['fast'])
library;

// =============================================================================
// case_timeline_view_test.dart — widget tests for CaseTimelineView.
//
// Covers four user-visible states + the filter contract:
//   1. Empty list (initial fetch returns 0 rows)  → empty state shown.
//   2. Non-empty list                              → tiles render with type label.
//   3. Filter chip switch                          → only matching tiles remain.
//   4. Tile tap                                    → payload pane expands.
//
// We override [supabaseServiceProvider] with a FakeSupabaseService that
// scripts the page sequence — no real DB required.
// =============================================================================

import 'package:advocat/features/cases/models/case_timeline_event.dart';
import 'package:advocat/features/cases/widgets/case_timeline_view.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _caseId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

class _FakeService extends SupabaseService {
  List<CaseTimelineEvent> page = const [];

  @override
  Future<List<CaseTimelineEvent>> getCaseTimelineEvents({
    required String caseId,
    int pageSize = 50,
    DateTime? beforeOccurredAt,
  }) async => page;
}

CaseTimelineEvent _evt({
  required String id,
  required CaseTimelineEventType type,
  String title = 'Event',
  String? summary,
  Map<String, dynamic> payload = const {},
  DateTime? when,
}) {
  final t = when ?? DateTime.now().subtract(const Duration(hours: 2));
  return CaseTimelineEvent(
    id: id,
    caseId: _caseId,
    userId: 'user-001',
    type: type,
    title: title,
    summary: summary,
    payload: payload,
    occurredAt: t,
    createdAt: t,
  );
}

Widget _pumpView(_FakeService fake) {
  return ProviderScope(
    overrides: [supabaseServiceProvider.overrideWithValue(fake)],
    // MaterialApp captures non-const localizationsDelegates getter, so
    // it cannot be `const` at this call site.
    child: MaterialApp( // ignore: prefer_const_constructors
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CaseTimelineView(caseId: _caseId),
      ),
    ),
  );
}

void main() {
  group('CaseTimelineView', () {
    testWidgets('empty list shows empty state', (tester) async {
      final fake = _FakeService()..page = const [];
      await tester.pumpWidget(_pumpView(fake));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('case-timeline-empty')), findsOneWidget);
      expect(find.byKey(const Key('case-timeline-list')), findsNothing);
    });

    testWidgets('renders one tile per event', (tester) async {
      final fake = _FakeService()
        ..page = [
          _evt(
            id: 'e1',
            type: CaseTimelineEventType.emailIn,
            title: 'Migri: hakemus vastaanotettu',
          ),
          _evt(
            id: 'e2',
            type: CaseTimelineEventType.consiliumDecision,
            title: 'AI triage: HIGH',
          ),
          _evt(
            id: 'e3',
            type: CaseTimelineEventType.deadlineSet,
            title: 'Valitusaika päättyy',
          ),
        ];
      await tester.pumpWidget(_pumpView(fake));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('case-timeline-list')), findsOneWidget);
      expect(find.byKey(const Key('case-timeline-tile-e1')), findsOneWidget);
      expect(find.byKey(const Key('case-timeline-tile-e2')), findsOneWidget);
      expect(find.byKey(const Key('case-timeline-tile-e3')), findsOneWidget);
      expect(find.text('Migri: hakemus vastaanotettu'), findsOneWidget);
      expect(find.text('AI triage: HIGH'), findsOneWidget);
      // Type pill labels (en locale).
      expect(find.text('Email received'), findsOneWidget);
      expect(find.text('AI decision'), findsOneWidget);
      expect(find.text('Deadline'), findsOneWidget);
    });

    testWidgets('filter chip narrows visible tiles', (tester) async {
      final fake = _FakeService()
        ..page = [
          _evt(id: 'em', type: CaseTimelineEventType.emailIn, title: 'EmailX'),
          _evt(
            id: 'co',
            type: CaseTimelineEventType.consiliumDecision,
            title: 'ConsilX',
          ),
        ];
      await tester.pumpWidget(_pumpView(fake));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('case-timeline-tile-em')), findsOneWidget);
      expect(find.byKey(const Key('case-timeline-tile-co')), findsOneWidget);

      // Tap the Consilium chip — only consilium tile remains.
      await tester.tap(
          find.byKey(const Key('case-timeline-filter-consilium')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('case-timeline-tile-em')), findsNothing);
      expect(find.byKey(const Key('case-timeline-tile-co')), findsOneWidget);

      // Switch back to All — both visible again.
      await tester.tap(find.byKey(const Key('case-timeline-filter-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('case-timeline-tile-em')), findsOneWidget);
      expect(find.byKey(const Key('case-timeline-tile-co')), findsOneWidget);
    });

    testWidgets('tile tap expands payload', (tester) async {
      final fake = _FakeService()
        ..page = [
          _evt(
            id: 'p1',
            type: CaseTimelineEventType.consiliumDecision,
            title: 'Triage',
            summary: 'Reply now',
            payload: {'triage_id': 't1', 'severity': 'HIGH'},
          ),
        ];
      await tester.pumpWidget(_pumpView(fake));
      await tester.pumpAndSettle();

      // Payload not visible until tap.
      expect(find.byKey(const Key('case-timeline-payload')), findsNothing);

      await tester.tap(find.byKey(const Key('case-timeline-tile-p1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('case-timeline-payload')), findsOneWidget);
      expect(find.text('Reply now'), findsOneWidget);
    });

    testWidgets('empty + filter shows "no events for filter" string',
        (tester) async {
      final fake = _FakeService()
        ..page = [
          _evt(id: 'em', type: CaseTimelineEventType.emailIn),
        ];
      await tester.pumpWidget(_pumpView(fake));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('case-timeline-filter-notes')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('case-timeline-empty')), findsOneWidget);
      expect(find.text('No events match this filter'), findsOneWidget);
    });
  });
}
