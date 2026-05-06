// inbox_provider_test.dart — D6 Riverpod tests for the Inbox state.
// -----------------------------------------------------------------------------
// Refs:
//   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md §D6
//   lib/features/inbox/providers/inbox_provider.dart
//   lib/services/assistant_tools.dart  (list_inbox / snooze_thread bridges)
//
// Coverage (matches spec line "inbox_provider_test.dart — RPC stream maps,
// snooze filter"):
//   - refresh() reads list_inbox, maps the wire rows to InboxThread, populates
//     the state, clears loading, no error.
//   - refresh() handles tool failure: errorMessage set, threads stay empty.
//   - Defence-in-depth snooze filter: rows with user_action='snoozed' and
//     seen_by_user_at within last 24h are dropped even if list_inbox returns
//     them (the chat tool already filters; the notifier double-checks).
//   - setSeverityFilter() round-trips and refresh() re-reads.
//   - snooze() optimistically removes the matching row.
//   - hideAfterAction() drops the row from the visible list.
//
// All tests use a fake AssistantTools that records inputs and returns
// scripted ToolResult values, so we can assert behaviour without spinning
// up Supabase.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/inbox/models/inbox_severity.dart';
import 'package:advocat/features/inbox/models/inbox_thread.dart';
import 'package:advocat/features/inbox/providers/inbox_provider.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

// ── Fake tools harness ───────────────────────────────────────────────────

/// Scriptable AssistantTools for the inbox provider. We override only the
/// tools the provider actually invokes: `list_inbox` + `snooze_thread`.
class _FakeAssistantTools extends AssistantTools {
  _FakeAssistantTools({
    required this.listInboxResult,
    this.onSnooze,
  }) : super(supabaseService: SupabaseService());

  final ToolResult Function(Map<String, dynamic> params) listInboxResult;
  final void Function(Map<String, dynamic> params)? onSnooze;

  /// Recorded calls — assert order / arguments in tests.
  final List<MapEntry<String, Map<String, dynamic>>> calls = [];

  @override
  Future<ToolResult> execute(String name, Map<String, dynamic> params) async {
    calls.add(MapEntry(name, Map<String, dynamic>.from(params)));
    switch (name) {
      case 'list_inbox':
        return listInboxResult(params);
      case 'snooze_thread':
        onSnooze?.call(params);
        return const ToolResult(
          success: true,
          displayText: 'Snoozed.',
          cardType: 'thread_snoozed',
          data: {'user_action': 'snoozed'},
          requiresApproval: false,
        );
    }
    return ToolResult.error('Unhandled tool $name');
  }
}

// ── Wire-row factory (mirror of email_triage_results JOIN email_threads) ──

Map<String, dynamic> _row({
  required String id,
  required String severity,
  String? userAction,
  DateTime? seenAt,
}) =>
    <String, dynamic>{
      'thread_id': id,
      'triage_id': 'triage-$id',
      'subject': 'Subject $id',
      'sender_email': '$id@example.com',
      'severity': severity,
      'user_brief': 'Brief $id',
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'has_draft': true,
      'send_recommendation': 'hold_for_user_review',
      'user_action': userAction,
      'seen_by_user_at': seenAt?.toIso8601String(),
    };

// ── Container helper ────────────────────────────────────────────────────

ProviderContainer _container(_FakeAssistantTools tools) {
  return ProviderContainer(
    overrides: [
      assistantToolsProvider.overrideWithValue(tools),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── refresh() — happy path ─────────────────────────────────────────────

  group('InboxNotifier.refresh', () {
    test('maps list_inbox wire rows into InboxThread and clears loading',
        () async {
      final tools = _FakeAssistantTools(
        listInboxResult: (_) => ToolResult(
          success: true,
          displayText: 'ok',
          cardType: 'inbox_list',
          data: <String, dynamic>{
            'threads': <Map<String, dynamic>>[
              _row(id: 'a', severity: 'CRITICAL'),
              _row(id: 'b', severity: 'HIGH'),
            ],
            'count': 2,
          },
          requiresApproval: false,
        ),
      );
      final c = _container(tools);
      addTearDown(c.dispose);

      // Provider construction kicks off an initial refresh; await one
      // microtask cycle to let it complete.
      c.read(inboxProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(inboxProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.threads, hasLength(2));
      expect(state.threads.first.threadId, 'a');
      expect(state.threads.first.severity, InboxSeverity.critical);
      expect(state.threads[1].severity, InboxSeverity.high);
      expect(tools.calls.first.key, 'list_inbox');
    });

    test('records the error message and leaves threads empty on failure',
        () async {
      final tools = _FakeAssistantTools(
        listInboxResult: (_) => ToolResult.error('boom'),
      );
      final c = _container(tools);
      addTearDown(c.dispose);
      c.read(inboxProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final state = c.read(inboxProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('boom'));
      expect(state.threads, isEmpty);
    });
  });

  // ── Defence-in-depth snooze filter ────────────────────────────────────

  group('InboxNotifier — snooze filter (defence in depth)', () {
    test(
        'drops rows snoozed within last 24h even if list_inbox returns them',
        () async {
      final now = DateTime.now().toUtc();
      final tools = _FakeAssistantTools(
        listInboxResult: (_) => ToolResult(
          success: true,
          displayText: 'ok',
          cardType: 'inbox_list',
          data: <String, dynamic>{
            'threads': <Map<String, dynamic>>[
              _row(id: 'visible', severity: 'CRITICAL'),
              _row(
                id: 'fresh-snoozed',
                severity: 'LOW',
                userAction: 'snoozed',
                seenAt: now.subtract(const Duration(hours: 1)),
              ),
              _row(
                id: 'old-snoozed',
                severity: 'LOW',
                userAction: 'snoozed',
                seenAt: now.subtract(const Duration(hours: 30)),
              ),
            ],
          },
          requiresApproval: false,
        ),
      );
      final c = _container(tools);
      addTearDown(c.dispose);
      c.read(inboxProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final ids = c.read(inboxProvider).threads.map((t) => t.threadId).toList();
      expect(ids, contains('visible'));
      expect(ids, contains('old-snoozed'),
          reason: 'snooze older than 24h must reappear');
      expect(ids, isNot(contains('fresh-snoozed')),
          reason: 'snooze within 24h must be hidden');
    });
  });

  // ── setSeverityFilter ────────────────────────────────────────────────

  group('InboxNotifier.setSeverityFilter', () {
    test('round-trips the filter and re-reads list_inbox with severity',
        () async {
      final tools = _FakeAssistantTools(
        listInboxResult: (params) {
          // Echo the severity param so we can assert it was passed through.
          final s = params['severity'] as String?;
          return ToolResult(
            success: true,
            displayText: 'ok',
            cardType: 'inbox_list',
            data: <String, dynamic>{
              'threads': <Map<String, dynamic>>[
                if (s == null || s == 'HIGH') _row(id: 'h1', severity: 'HIGH'),
              ],
              if (s != null) 'filter_severity': s,
            },
            requiresApproval: false,
          );
        },
      );
      final c = _container(tools);
      addTearDown(c.dispose);
      final notifier = c.read(inboxProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await notifier.setSeverityFilter(InboxSeverity.high);
      final state = c.read(inboxProvider);
      expect(state.severityFilter, InboxSeverity.high);
      // Last call to list_inbox should carry severity=HIGH.
      final last = tools.calls.lastWhere((e) => e.key == 'list_inbox');
      expect(last.value['severity'], 'HIGH');

      await notifier.setSeverityFilter(null);
      expect(c.read(inboxProvider).severityFilter, isNull);
    });
  });

  // ── snooze() — optimistic remove ─────────────────────────────────────

  group('InboxNotifier.snooze', () {
    test('removes the matching thread immediately from state', () async {
      var snoozeCalled = false;
      final tools = _FakeAssistantTools(
        listInboxResult: (_) => ToolResult(
          success: true,
          displayText: 'ok',
          cardType: 'inbox_list',
          data: <String, dynamic>{
            'threads': <Map<String, dynamic>>[
              _row(id: 'keep', severity: 'CRITICAL'),
              _row(id: 'snooze-me', severity: 'HIGH'),
            ],
          },
          requiresApproval: false,
        ),
        onSnooze: (_) => snoozeCalled = true,
      );
      final c = _container(tools);
      addTearDown(c.dispose);
      final notifier = c.read(inboxProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(inboxProvider).threads, hasLength(2));

      await notifier.snooze('snooze-me');
      final ids = c.read(inboxProvider).threads.map((t) => t.threadId).toList();
      expect(ids, equals(['keep']));
      expect(snoozeCalled, isTrue,
          reason: 'snooze must call snooze_thread on the tool layer.');
      // Argument shape contract.
      final last = tools.calls.last;
      expect(last.key, 'snooze_thread');
      expect(last.value['thread_id'], 'snooze-me');
    });
  });

  // ── hideAfterAction() ────────────────────────────────────────────────

  group('InboxNotifier.hideAfterAction', () {
    test('removes the matching thread from the visible list', () async {
      final tools = _FakeAssistantTools(
        listInboxResult: (_) => ToolResult(
          success: true,
          displayText: 'ok',
          cardType: 'inbox_list',
          data: <String, dynamic>{
            'threads': <Map<String, dynamic>>[
              _row(id: 'a', severity: 'HIGH'),
              _row(id: 'b', severity: 'LOW'),
            ],
          },
          requiresApproval: false,
        ),
      );
      final c = _container(tools);
      addTearDown(c.dispose);
      final notifier = c.read(inboxProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.hideAfterAction('a');
      final ids = c.read(inboxProvider).threads.map((t) => t.threadId).toList();
      expect(ids, equals(['b']));
    });
  });

  // ── InboxState.copyWith semantics (snooze-filter clear path) ─────────

  group('InboxState.copyWith', () {
    test('clearSeverityFilter overrides severityFilter param', () {
      const a = InboxState(
        threads: <InboxThread>[],
        severityFilter: InboxSeverity.high,
        isLoading: false,
        errorMessage: null,
      );
      final b = a.copyWith(clearSeverityFilter: true);
      expect(b.severityFilter, isNull);
    });

    test('clearError wipes the error message', () {
      const a = InboxState(
        threads: <InboxThread>[],
        severityFilter: null,
        isLoading: false,
        errorMessage: 'oops',
      );
      final b = a.copyWith(clearError: true);
      expect(b.errorMessage, isNull);
    });
  });
}
