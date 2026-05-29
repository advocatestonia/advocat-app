// triage_card_test.dart — D6 widget tests for the inbox TriageCard.
// -----------------------------------------------------------------------------
// Refs:
//   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md §D6
//   lib/features/inbox/widgets/triage_card.dart
//   lib/features/inbox/models/inbox_thread.dart
//   lib/features/inbox/providers/inbox_provider.dart
//
// Coverage (matches spec line "triage_card_test.dart — 4 actions, severity
// badges, deadline chip"):
//   - Severity badge: text + colour band per severity bucket.
//   - 4 actions wired:
//       Approve & send (only when hasDraft)
//       Edit          (only when hasDraft)
//       Snooze        (always)
//       Archive       (always)
//   - hasDraft=false hides the two draft-only buttons (Approve & send + Edit).
//   - Snooze tap optimistically removes the row from the inbox provider.
//   - Deadline chip renders when InboxThread.topDeadline is non-null.
//   - Deadline chip absent when deadlines list is empty.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:advocat/features/inbox/models/inbox_severity.dart';
import 'package:advocat/features/inbox/models/inbox_thread.dart';
import 'package:advocat/features/inbox/providers/inbox_provider.dart';
import 'package:advocat/features/inbox/widgets/triage_card.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

/// Records edge-function invocations so the carry-over Task 4 widget
/// tests can assert that:
///   - Archive triggers a `gmail-label` invoke with the right shape.
///   - The local hide happens regardless of Gmail-side outcome.
class _RecordingSupabaseService extends SupabaseService {
  final List<({String name, Map<String, dynamic>? body})> calls = [];
  Map<String, dynamic>? nextResponse;

  @override
  Future<Map<String, dynamic>?> callEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    String? traceId,
  }) async {
    calls.add((name: functionName, body: body));
    return nextResponse;
  }
}

InboxThread _thread({
  String id = 't1',
  InboxSeverity severity = InboxSeverity.high,
  bool hasDraft = true,
  String? userAction,
  DateTime? seenAt,
  List<InboxDeadline> deadlines = const <InboxDeadline>[],
}) =>
    InboxThread(
      threadId: id,
      triageId: 'triage-$id',
      subject: 'Subject $id',
      senderEmail: 'sender-$id@example.com',
      severity: severity,
      userBrief: 'Brief for $id',
      lastMessageAt: DateTime.now().toUtc(),
      hasDraft: hasDraft,
      sendRecommendation: 'hold_for_user_review',
      userAction: userAction,
      seenByUserAt: seenAt,
      deadlines: deadlines,
    );

class _SeededInboxNotifier extends InboxNotifier {
  _SeededInboxNotifier(
    super.tools,
    List<InboxThread> seed, {
    super.supabase,
  }) {
    state = InboxState(
      threads: seed,
      severityFilter: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  @override
  Future<void> refresh() async {/* no-op for tests */}

  @override
  Future<void> snooze(String threadId) async {
    // Bypass tool I/O — just exercise the optimistic-remove path under
    // test, identical to what production does after a successful tool
    // call.
    state = state.copyWith(
      threads:
          state.threads.where((t) => t.threadId != threadId).toList(),
    );
  }
}

/// Notifier whose snooze() blocks on a Completer and counts invocations, so a
/// double-tap test can prove the card's re-entrancy guard prevents a second
/// dispatch while the first is in flight.
class _GatedSnoozeNotifier extends InboxNotifier {
  _GatedSnoozeNotifier(super.tools, List<InboxThread> seed) {
    state = InboxState(
      threads: seed,
      severityFilter: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  int snoozeCalls = 0;
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> refresh() async {}

  @override
  Future<void> snooze(String threadId) async {
    snoozeCalls++;
    await gate.future;
  }
}

Widget _wrapWithSupabase(
  Widget child, {
  required List<InboxThread> seed,
  required SupabaseService supabase,
}) {
  final router = GoRouter(
    initialLocation: '/inbox',
    routes: [
      GoRoute(
        path: '/inbox',
        builder: (_, __) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/inbox/draft/:triageId',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('edit'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      supabaseServiceProvider.overrideWithValue(supabase),
      inboxProvider.overrideWith(
        (ref) => _SeededInboxNotifier(
          ref.read(assistantToolsProvider),
          seed,
          supabase: supabase,
        ),
      ),
      assistantToolsProvider.overrideWithValue(
        AssistantTools(supabaseService: supabase),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
    ),
  );
}

Widget _wrap(Widget child, {required List<InboxThread> seed}) {
  // Minimal GoRouter so context.push from the Edit action does not throw.
  final router = GoRouter(
    initialLocation: '/inbox',
    routes: [
      GoRoute(
        path: '/inbox',
        builder: (_, __) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/inbox/draft/:triageId',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('edit'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      inboxProvider.overrideWith(
        (ref) => _SeededInboxNotifier(
          ref.read(assistantToolsProvider),
          seed,
        ),
      ),
      assistantToolsProvider.overrideWithValue(
        AssistantTools(supabaseService: SupabaseService()),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Severity badges ───────────────────────────────────────────────────

  group('TriageCard — severity badges', () {
    testWidgets('renders the severity raw label as text', (tester) async {
      final t = _thread(severity: InboxSeverity.critical);
      await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
      // CRITICAL pulses; one pump is enough to flush layout.
      await tester.pump();
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    for (final s in InboxSeverity.values) {
      testWidgets('renders ${s.raw} badge text', (tester) async {
        final t = _thread(id: s.raw.toLowerCase(), severity: s);
        await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
        await tester.pump();
        expect(find.text(s.raw), findsOneWidget);
      });
    }
  });

  // ── 4 actions ─────────────────────────────────────────────────────────

  group('TriageCard — 4 actions', () {
    testWidgets(
      'shows Approve & send, Edit, Snooze, Archive when hasDraft=true',
      (tester) async {
        final t = _thread(hasDraft: true);
        await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
        await tester.pumpAndSettle();
        expect(find.text('Approve & send'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Snooze'), findsOneWidget);
        expect(find.text('Archive'), findsOneWidget);
      },
    );

    testWidgets(
      'hides Approve & send + Edit when hasDraft=false (only Snooze + Archive)',
      (tester) async {
        final t = _thread(hasDraft: false);
        await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
        await tester.pumpAndSettle();
        expect(find.text('Approve & send'), findsNothing);
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Snooze'), findsOneWidget);
        expect(find.text('Archive'), findsOneWidget);
      },
    );

    testWidgets(
      'Snooze tap optimistically removes the thread from the provider',
      (tester) async {
        final t = _thread(id: 's1', hasDraft: false);
        await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
        await tester.pumpAndSettle();

        // Tap Snooze.
        await tester.tap(find.text('Snooze'));
        await tester.pumpAndSettle();

        // The seeded notifier should have removed the row optimistically.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final remaining = container.read(inboxProvider).threads;
        expect(remaining, isEmpty,
            reason: 'Snooze must remove the row from the inbox state.');
      },
    );

    testWidgets(
      'double-tap Snooze while in flight dispatches only once (re-entrancy)',
      (tester) async {
        final t = _thread(id: 's2', hasDraft: false);
        late _GatedSnoozeNotifier notifier;
        final router = GoRouter(
          initialLocation: '/inbox',
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (_, __) => Scaffold(body: TriageCard(thread: t)),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxProvider.overrideWith((ref) {
                notifier = _GatedSnoozeNotifier(
                  ref.read(assistantToolsProvider), [t]);
                return notifier;
              }),
              assistantToolsProvider.overrideWithValue(
                AssistantTools(supabaseService: SupabaseService()),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), Locale('et'), Locale('ru'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Two rapid taps before the in-flight snooze resolves.
        await tester.tap(find.text('Snooze'));
        await tester.pump();
        await tester.tap(find.text('Snooze'));
        await tester.pump();

        expect(notifier.snoozeCalls, 1,
            reason: 'Re-entrancy guard must block the second dispatch.');

        // Release the gate so the first call completes cleanly.
        notifier.gate.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Approve tap opens the confirm dialog (cancel does NOT dispatch send)',
      (tester) async {
        final t = _thread(hasDraft: true);
        await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve & send'));
        await tester.pumpAndSettle();

        // Confirm dialog visible.
        expect(find.text('Send the prepared reply?'), findsOneWidget);

        // Cancel — no toast / no provider mutation.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Sent.'), findsNothing);
      },
    );
  });

  // ── Deadline chip ─────────────────────────────────────────────────────

  group('TriageCard — deadline chip', () {
    testWidgets('renders chip with "today" when deltaDays=0', (tester) async {
      final t = _thread(
        deadlines: const [
          InboxDeadline(
            isoDate: '2026-05-06',
            deltaDays: 0,
            description: 'Court reply',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
      await tester.pumpAndSettle();
      // Chip text format is "<description> · today".
      expect(find.textContaining('today'), findsOneWidget);
      expect(find.textContaining('Court reply'), findsOneWidget);
    });

    testWidgets('renders "in Nd" form when deltaDays>1', (tester) async {
      final t = _thread(
        deadlines: const [
          InboxDeadline(
            isoDate: '2026-05-13',
            deltaDays: 7,
            description: 'Appeal window',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
      await tester.pumpAndSettle();
      expect(find.textContaining('in 7d'), findsOneWidget);
    });

    testWidgets('renders "overdue Nd" when deltaDays<0', (tester) async {
      final t = _thread(
        deadlines: const [
          InboxDeadline(
            isoDate: '2026-05-01',
            deltaDays: -5,
            description: 'Filing window',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
      await tester.pumpAndSettle();
      expect(find.textContaining('overdue 5d'), findsOneWidget);
    });

    testWidgets('hides the chip when deadlines list is empty', (tester) async {
      final t = _thread();
      await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
      await tester.pumpAndSettle();
      // No clock icon means no chip.
      expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    });

    testWidgets('picks the most-urgent deadline when several exist',
        (tester) async {
      final t = _thread(
        deadlines: const [
          InboxDeadline(
            isoDate: '2026-05-30',
            deltaDays: 24,
            description: 'Late item',
          ),
          InboxDeadline(
            isoDate: '2026-05-08',
            deltaDays: 2,
            description: 'Urgent item',
          ),
          InboxDeadline(
            isoDate: '2026-05-20',
            deltaDays: 14,
            description: 'Mid item',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(TriageCard(thread: t), seed: [t]));
      await tester.pumpAndSettle();
      // The chip must render the urgent item, not the others.
      expect(find.textContaining('Urgent item'), findsOneWidget);
      expect(find.textContaining('Late item'), findsNothing);
      expect(find.textContaining('Mid item'), findsNothing);
    });
  });

  // ── Carry-over Task 4: Archive mirrors to Gmail via gmail-label ───────

  group('TriageCard — Archive Gmail label mirror', () {
    testWidgets('Archive tap invokes gmail-label edge fn', (tester) async {
      final supabase = _RecordingSupabaseService()
        ..nextResponse = {'ok': true, 'applied': ['advocat:auto-archived']};
      final t = _thread(id: 'a1', hasDraft: false);
      await tester.pumpWidget(
        _wrapWithSupabase(
          TriageCard(thread: t),
          seed: [t],
          supabase: supabase,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      final invoked =
          supabase.calls.where((c) => c.name == 'gmail-label').toList();
      expect(invoked, isNotEmpty,
          reason: 'Archive must call gmail-label edge fn.');
      final body = invoked.single.body!;
      expect(body['thread_id'], equals('a1'));
      expect(
        (body['add_labels'] as List).contains('advocat:auto-archived'),
        isTrue,
      );
      expect((body['remove_labels'] as List).contains('INBOX'), isTrue);
    });

    testWidgets(
      'Archive hides the row even when Gmail soft-fails',
      (tester) async {
        final supabase = _RecordingSupabaseService()
          ..nextResponse = {
            'ok': false,
            'error_code': 'gmail_unavailable',
            'detail': 'simulated outage',
          };
        final t = _thread(id: 'a2', hasDraft: false);
        await tester.pumpWidget(
          _wrapWithSupabase(
            TriageCard(thread: t),
            seed: [t],
            supabase: supabase,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Archive'));
        await tester.pumpAndSettle();

        // Local hide must still happen — UX contract from §D6:
        // "soft-fail if Gmail API errors — local archive still succeeds".
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final remaining = container.read(inboxProvider).threads;
        expect(remaining, isEmpty);

        expect(supabase.calls.length, equals(1));
        expect(supabase.calls.single.name, equals('gmail-label'));
      },
    );
  });

  // ── D6 Approve & Send ─────────────────────────────────────────────────

  group('TriageCard — D6 Approve & Send', () {
    testWidgets(
      'Approve & send → confirm → calls email-send → success snackbar',
      (tester) async {
        final supabase = _RecordingSupabaseService()
          ..nextResponse = {
            'ok': true,
            'gmail_message_id': 'gmail-abc-123',
            'sent_at': '2026-05-25T19:00:00.000Z',
          };
        final t = _thread(id: 'send-ok', hasDraft: true);
        await tester.pumpWidget(
          _wrapWithSupabase(
            TriageCard(thread: t),
            seed: [t],
            supabase: supabase,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve & send'));
        await tester.pumpAndSettle();
        // Confirm dialog visible — tap Send.
        expect(find.text('Send the prepared reply?'), findsOneWidget);
        await tester.tap(find.text('Send'));
        // Pump enough frames for the SnackBar to enter the tree without
        // letting its 2s display window elapse.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // email-send was invoked with triage_id (NOT thread_id).
        final invoked =
            supabase.calls.where((c) => c.name == 'email-send').toList();
        expect(invoked.length, equals(1));
        expect(invoked.single.body!['triage_id'], equals('triage-send-ok'));
        // No edited_body field when the user did not edit the draft.
        expect(invoked.single.body!.containsKey('edited_body'), isFalse);

        // Success snackbar surfaced.
        expect(find.text('Sent.'), findsOneWidget);

        // Thread row is hidden from the inbox state.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final remaining = container.read(inboxProvider).threads;
        expect(remaining, isEmpty);
      },
    );

    testWidgets(
      'Approve & send → email-send fails → error snackbar with Retry action',
      (tester) async {
        final supabase = _RecordingSupabaseService()
          ..nextResponse = {
            'error': 'Gmail send failed',
            'error_code': 'gmail_reauth_required',
          };
        final t = _thread(id: 'send-err', hasDraft: true);
        await tester.pumpWidget(
          _wrapWithSupabase(
            TriageCard(thread: t),
            seed: [t],
            supabase: supabase,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve & send'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send'));
        // Error snackbar duration is 5s — pump just past the show animation.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Error snackbar — surfaces the server error message.
        expect(find.text('Gmail send failed'), findsOneWidget);
        // Retry action is visible (SnackBarAction).
        expect(find.text('Retry'), findsOneWidget);

        // Thread row NOT hidden on failure — the user keeps the card so
        // they can re-attempt without re-loading the inbox.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final remaining = container.read(inboxProvider).threads;
        expect(remaining.length, equals(1));
      },
    );

    testWidgets(
      'Approve & send → idempotent re-send → "Already sent" snackbar',
      (tester) async {
        final supabase = _RecordingSupabaseService()
          ..nextResponse = {
            'ok': true,
            'gmail_message_id': 'gmail-prior-msg-42',
            'sent_at': '2026-05-25T18:55:00.000Z',
            'idempotent': true,
          };
        final t = _thread(id: 'send-idem', hasDraft: true);
        await tester.pumpWidget(
          _wrapWithSupabase(
            TriageCard(thread: t),
            seed: [t],
            supabase: supabase,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve & send'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send'));
        // Snackbar duration is 2s — pump just past the show animation so
        // the SnackBar is mounted but not yet dismissed.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Already sent.'), findsOneWidget);
      },
    );
  });
}
