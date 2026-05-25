// parallel_actions_card_test.dart
// -----------------------------------------------------------------------------
// Widget tests for the Parallel Actions Panel (2026-05-25).
//
// Pattern source: Sulga case manual consilium recommended TWO emails in
// parallel (Jokela reply + asiakirjapyyntö to poliisi kirjaamo). The card
// must let the user approve both with one tap, OR deselect any one
// individually before approving the rest.
//
// Coverage:
//   (a) Renders N action mini-cards when the thread carries N>=2
//       proposed_actions. Each row shows recipient, subject, rationale,
//       kind chip, language chip, citation count chip.
//   (b) Checkbox toggle updates the per-row selection and the primary
//       button label switches between "Approve All & Send" and
//       "Approve k of N". The button is disabled when zero actions
//       are selected.
//   (c) Tapping the primary "Approve All & Send" button, then "Send"
//       on the confirmation modal, calls
//       `approveSelectedActions(triageId, [0,1])` exactly once on the
//       provider with all indexes.
//
// We override the inbox provider with a recording stub so the test
// doesn't depend on Supabase. The stub also captures `hideAfterAction`
// so we can assert the post-success hide path runs.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/inbox/models/inbox_severity.dart';
import 'package:advocat/features/inbox/models/inbox_thread.dart';
import 'package:advocat/features/inbox/providers/inbox_provider.dart';
import 'package:advocat/features/inbox/widgets/parallel_actions_card.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

// ─── Recording stub provider ────────────────────────────────────────────────

class _RecordingInboxNotifier extends InboxNotifier {
  _RecordingInboxNotifier(super.tools, List<InboxThread> seed) {
    state = InboxState(
      threads: seed,
      severityFilter: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Each invocation of `approveSelectedActions` appended as
  /// (triageId, idxes).
  final List<({String triageId, List<int> idxes})> approvedCalls = [];

  /// Per-call return value. Defaults to "all succeeded"; tests can override
  /// to simulate partial failure.
  ParallelApproveResult Function(int n) responseFactory =
      (n) => ParallelApproveResult(sent: n, failed: 0);

  /// Each `hideAfterAction(threadId)` invocation appended in order.
  final List<String> hiddenThreadIds = [];

  @override
  Future<void> refresh() async {/* no-op */}

  @override
  Future<ParallelApproveResult> approveSelectedActions(
    String triageId,
    List<int> selectedIdxes,
  ) async {
    approvedCalls.add((triageId: triageId, idxes: List<int>.from(selectedIdxes)));
    return responseFactory(selectedIdxes.length);
  }

  @override
  void hideAfterAction(String threadId) {
    hiddenThreadIds.add(threadId);
    super.hideAfterAction(threadId);
  }
}

// ─── Fixture helpers ────────────────────────────────────────────────────────

InboxThread _twoActionThread() {
  return InboxThread(
    threadId: 'thread-sulga-1',
    triageId: 'triage-sulga-1',
    subject: 'Käännytyspäätös 5.12.2025 — vastaus + asiakirjapyyntö',
    senderEmail: 'jokela@migri.fi',
    severity: InboxSeverity.high,
    userBrief:
        'Consilium recommended a soft-return reply to Jokela AND a parallel '
        'asiakirjapyyntö to poliisi kirjaamo.',
    lastMessageAt: DateTime.utc(2026, 5, 25, 12, 0, 0),
    hasDraft: true,
    sendRecommendation: 'hold_for_user_review',
    userAction: null,
    seenByUserAt: null,
    proposedActions: const <ProposedAction>[
      ProposedAction(
        idx: 0,
        kind: 'email_reply',
        toAddr: 'jokela@migri.fi',
        cc: <String>[],
        subject: 'Vastaus 12.5.2026 viestiin',
        body: 'Hyvä Jokela, ...',
        language: 'fi',
        citations: <String>['[[ref:fi-hol:122]]', '[[ref:eu-echr:6.3]]'],
        rationale: 'Soft-return per HOL §122; declines käännytys.',
      ),
      ProposedAction(
        idx: 1,
        kind: 'email_new',
        toAddr: 'kirjaamo.helsinki@poliisi.fi',
        cc: <String>[],
        subject: 'Asiakirjapyyntö (JulkL 14§)',
        body: 'Pyydän julkisuuslain 14§:n nojalla seuraavat asiakirjat ...',
        language: 'fi',
        citations: <String>['[[ref:fi-julkl:14]]'],
        rationale: '2vk deadline; requests Eckerö Line + police records.',
      ),
    ],
  );
}

Widget _wrap({
  required InboxThread thread,
  required _RecordingInboxNotifier notifier,
}) {
  return ProviderScope(
    overrides: [
      inboxProvider.overrideWith((ref) => notifier),
      assistantToolsProvider.overrideWithValue(
        AssistantTools(supabaseService: SupabaseService()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
      home: Scaffold(body: ParallelActionsCard(thread: thread)),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParallelActionsCard — render', () {
    testWidgets('shows N=2 action rows with recipients + subjects',
        (tester) async {
      final t = _twoActionThread();
      final notifier = _RecordingInboxNotifier(
        AssistantTools(supabaseService: SupabaseService()),
        [t],
      );
      await tester.pumpWidget(_wrap(thread: t, notifier: notifier));
      await tester.pump();

      // Headline reflects the action count.
      expect(
        find.text('Consilium recommends 2 parallel actions'),
        findsOneWidget,
        reason: 'headline must surface the action count',
      );
      // Both recipients render.
      expect(find.text('jokela@migri.fi'), findsOneWidget);
      expect(find.text('kirjaamo.helsinki@poliisi.fi'), findsOneWidget);
      // Both subjects render.
      expect(find.text('Vastaus 12.5.2026 viestiin'), findsOneWidget);
      expect(find.text('Asiakirjapyyntö (JulkL 14§)'), findsOneWidget);
      // Both rationales render.
      expect(
        find.textContaining('Soft-return per HOL §122'),
        findsOneWidget,
      );
      expect(
        find.textContaining('2vk deadline'),
        findsOneWidget,
      );
      // Per-row checkboxes — one per action.
      expect(find.byType(Checkbox), findsNWidgets(2));
      // Approve All & Send button visible by default.
      expect(find.text('Approve All & Send'), findsOneWidget);
    });
  });

  group('ParallelActionsCard — checkbox toggle', () {
    testWidgets(
      'unchecking one action switches the primary button to "Approve 1 of 2"',
      (tester) async {
        final t = _twoActionThread();
        final notifier = _RecordingInboxNotifier(
          AssistantTools(supabaseService: SupabaseService()),
          [t],
        );
        await tester.pumpWidget(_wrap(thread: t, notifier: notifier));
        await tester.pump();

        // Sanity: both selected → "Approve All & Send".
        expect(find.text('Approve All & Send'), findsOneWidget);
        expect(find.text('Approve 1 of 2'), findsNothing);

        // Tap the first checkbox to deselect action idx=0.
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();

        // Button label switches.
        expect(find.text('Approve All & Send'), findsNothing);
        expect(find.text('Approve 1 of 2'), findsOneWidget);

        // Untap the second checkbox too — both deselected.
        await tester.tap(find.byType(Checkbox).last);
        await tester.pump();

        // Now the button reads "Approve 0 of 2" AND it is disabled. We
        // assert disabled by checking the FilledButton.onPressed via the
        // widget tree.
        expect(find.text('Approve 0 of 2'), findsOneWidget);
        final btn = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(btn.onPressed, isNull,
            reason: 'primary button must be disabled with zero selected');
      },
    );
  });

  group('ParallelActionsCard — approve flow', () {
    testWidgets(
      'tapping Approve All & Send → confirm → calls approveSelectedActions '
      'once with both idxes and hides the thread',
      (tester) async {
        final t = _twoActionThread();
        final notifier = _RecordingInboxNotifier(
          AssistantTools(supabaseService: SupabaseService()),
          [t],
        );
        await tester.pumpWidget(_wrap(thread: t, notifier: notifier));
        await tester.pump();

        // 1. Tap "Approve All & Send".
        await tester.tap(find.text('Approve All & Send'));
        await tester.pump(); // open dialog

        // 2. Confirmation modal — pump the route transition.
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Send 2 emails?'), findsOneWidget);

        // 3. Tap "Send" inside the modal.
        await tester.tap(find.text('Send'));
        // Pump dialog dismissal + async approve + post-await rebuild.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // 4. Provider was called exactly once with both idxes.
        expect(notifier.approvedCalls.length, equals(1));
        expect(notifier.approvedCalls.first.triageId, equals('triage-sulga-1'));
        expect(
          notifier.approvedCalls.first.idxes,
          equals(<int>[0, 1]),
          reason: 'both action indexes must be dispatched in one fan-out',
        );

        // 5. On success the card optimistically hides the thread.
        expect(
          notifier.hiddenThreadIds,
          contains('thread-sulga-1'),
          reason:
              'all-success approve must call hideAfterAction so the card '
              'leaves the inbox immediately',
        );
      },
    );
  });
}
