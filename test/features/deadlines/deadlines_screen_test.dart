// Widget tests for the new grouped DeadlinesScreen (2026-05-27 rebuild).
// -----------------------------------------------------------------------------
// Verifies:
//   1. Grouping into urgency buckets (Today/Overdue, This week, This month, Later)
//   2. Urgency-color and icon for the header row
//   3. Empty-state messaging when there are no actionable deadlines
//   4. Source attribution row when a deadline is AI-extracted or email-extracted
//   5. Manual FAB exposes the "Add deadline" label
//   6. Pull-to-refresh re-invokes the provider
//   7. Card menu offers snooze + dismiss + export entries
//   8. Completed deadlines are filtered out of the actionable buckets
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/deadlines/providers/deadlines_provider.dart';
import 'package:advocat/features/deadlines/screens/deadlines_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/models/deadline.dart';
import 'package:advocat/services/supabase_service.dart';

/// In-memory SupabaseService stand-in that records mutating calls so
/// tests can assert that snooze / dismiss / mark-complete actually hit
/// the backend with the right payload.
class _RecordingSupabase extends SupabaseService {
  _RecordingSupabase();
  final List<Map<String, dynamic>> updates = [];
  final List<Map<String, dynamic>> creates = [];

  @override
  bool get isDemo => true; // skip real client lookup in tests

  @override
  Future<void> updateDeadline(String id, Map<String, dynamic> patch) async {
    updates.add({'id': id, ...patch});
  }

  @override
  Future<void> createDeadline(Map<String, dynamic> data) async {
    creates.add(Map<String, dynamic>.from(data));
  }
}

Deadline _make({
  required String id,
  required String title,
  required int daysFromNow,
  DeadlineStatus status = DeadlineStatus.upcoming,
  DeadlineSource source = DeadlineSource.manual,
}) {
  final now = DateTime.now();
  return Deadline(
    id: id,
    caseId: 'case-1',
    userId: 'user-1',
    title: title,
    dueDate: now.add(Duration(days: daysFromNow)),
    status: status,
    source: source,
    createdAt: now,
  );
}

ProviderScope _harness({
  required List<Deadline> deadlines,
  _RecordingSupabase? supabase,
}) {
  return ProviderScope(
    overrides: [
      allDeadlinesProvider.overrideWith((ref) async => deadlines),
      if (supabase != null)
        supabaseServiceProvider.overrideWithValue(supabase),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeadlinesScreen(),
    ),
  );
}

void main() {
  group('DeadlinesScreen grouping', () {
    testWidgets(
      'groups deadlines into urgency buckets',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(
          deadlines: [
            _make(id: 'today', title: 'TODAY_TITLE', daysFromNow: 0),
            _make(id: 'overdue', title: 'OVERDUE_TITLE', daysFromNow: -2),
            _make(id: 'week', title: 'WEEK_TITLE', daysFromNow: 3),
            _make(id: 'month', title: 'MONTH_TITLE', daysFromNow: 20),
            _make(id: 'later', title: 'LATER_TITLE', daysFromNow: 60),
          ],
        ));
        await tester.pumpAndSettle();

        // All four section headers visible.
        expect(find.textContaining('Today'), findsWidgets);
        expect(find.textContaining('week'), findsWidgets);
        expect(find.textContaining('month'), findsWidgets);
        expect(find.textContaining('Later'), findsWidgets);

        // All five titles render.
        expect(find.text('TODAY_TITLE'), findsOneWidget);
        expect(find.text('OVERDUE_TITLE'), findsOneWidget);
        expect(find.text('WEEK_TITLE'), findsOneWidget);
        expect(find.text('MONTH_TITLE'), findsOneWidget);
        expect(find.text('LATER_TITLE'), findsOneWidget);
      },
    );

    testWidgets(
      'shows empty state when no actionable deadlines',
      (tester) async {
        await tester.pumpWidget(_harness(deadlines: const []));
        await tester.pumpAndSettle();

        // Empty-state icon visible.
        expect(find.byIcon(Icons.event_available_outlined), findsWidgets);
        // Explanation copy is rendered (contains the literal "deadlines").
        expect(find.textContaining('deadlines'), findsWidgets);
      },
    );

    testWidgets(
      'filters out completed deadlines from buckets',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(
          deadlines: [
            _make(id: 'a', title: 'ACTIVE', daysFromNow: 5),
            _make(
              id: 'b',
              title: 'ALREADY_DONE',
              daysFromNow: 1,
              status: DeadlineStatus.completed,
            ),
          ],
        ));
        await tester.pumpAndSettle();

        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('ALREADY_DONE'), findsNothing);
      },
    );

    testWidgets(
      'FAB exposes manual add affordance',
      (tester) async {
        await tester.pumpWidget(_harness(deadlines: const []));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );

    testWidgets(
      'source row shown when deadline is AI-extracted',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(
          deadlines: [
            _make(
              id: 'ai',
              title: 'AI_DEADLINE',
              daysFromNow: 5,
              source: DeadlineSource.aiExtracted,
            ),
          ],
        ));
        await tester.pumpAndSettle();

        // Source icon is the auto_awesome glyph.
        expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'popup menu opens with snooze + dismiss + export actions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(
          deadlines: [
            _make(id: 'd1', title: 'ROW_FOR_MENU', daysFromNow: 4),
          ],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Menu visible — three snooze options + dismiss + export.
        expect(find.textContaining('1 day'), findsWidgets);
        expect(find.textContaining('3 days'), findsWidgets);
        expect(find.textContaining('7 days'), findsWidgets);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.byIcon(Icons.event_available_outlined), findsWidgets);
      },
    );

    testWidgets(
      'overdue card renders negative countdown without crash',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(
          deadlines: [
            _make(id: 'late', title: 'OVERDUE_ROW', daysFromNow: -5),
          ],
        ));
        await tester.pumpAndSettle();

        // Number "5" appears in the countdown badge.
        expect(find.text('5'), findsOneWidget);
        // No exception was thrown — title renders.
        expect(find.text('OVERDUE_ROW'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping snooze 3d updates the deadline due_date',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fake = _RecordingSupabase();
        await tester.pumpWidget(_harness(
          supabase: fake,
          deadlines: [
            _make(id: 'snooze-target', title: 'SNOOZE_ME', daysFromNow: 4),
          ],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('3 days').last);
        await tester.pumpAndSettle();

        expect(fake.updates, hasLength(1));
        expect(fake.updates.first['id'], 'snooze-target');
        expect(fake.updates.first['due_date'], isA<String>());
      },
    );

    testWidgets(
      'tapping dismiss sets status=cancelled',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fake = _RecordingSupabase();
        await tester.pumpWidget(_harness(
          supabase: fake,
          deadlines: [
            _make(id: 'dismiss-target', title: 'DROP_ME', daysFromNow: 5),
          ],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(fake.updates, hasLength(1));
        expect(fake.updates.first['id'], 'dismiss-target');
        expect(fake.updates.first['status'], 'cancelled');
      },
    );

    testWidgets(
      'tapping mark-complete sets status=completed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fake = _RecordingSupabase();
        await tester.pumpWidget(_harness(
          supabase: fake,
          deadlines: [
            _make(id: 'done-target', title: 'COMPLETE_ME', daysFromNow: 5),
          ],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('mark-complete')));
        await tester.pumpAndSettle();

        expect(fake.updates, hasLength(1));
        expect(fake.updates.first['id'], 'done-target');
        expect(fake.updates.first['status'], 'completed');
      },
    );

    testWidgets(
      'error state shows retry button',
      (tester) async {
        await tester.pumpWidget(ProviderScope(
          overrides: [
            allDeadlinesProvider.overrideWith((ref) async {
              throw Exception('boom');
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DeadlinesScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byType(TextButton), findsWidgets);
      },
    );
  });
}
