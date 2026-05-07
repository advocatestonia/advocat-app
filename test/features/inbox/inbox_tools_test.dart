// inbox_tools_test.dart — TDD coverage for D5 chat assistant tools.
// -----------------------------------------------------------------------------
// Refs:
//   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md §D5
//   lib/services/assistant_tools.dart — _listInbox / _getThreadTriage /
//                                       _approveSendDraft / _snoozeThread
//   lib/services/tool_definitions.dart — JSON schemas for the 4 tools
//   supabase/migrations/20260507130000_email_inbox.sql — table contracts
//
// Scope (per spec hard rules):
//   - Tool registration: list_inbox / get_thread_triage / approve_send_draft /
//                        snooze_thread present on _tools and toolNames.
//   - Schemas: required fields and severity enum present.
//   - Approval semantics: approve_send_draft MUST be in requiresApproval; the
//     other three MUST NOT be (read-only / passive).
//   - Handler input hardening: missing thread_id rejected; bad enum rejected.
//   - Severity sort: list_inbox card data emits severity_rank used by UI.
//   - Snooze contract: returns user_action='snoozed' so UI can hide for 24h.
//   - approve_send_draft happy path returns data with send_via='send-email'
//     so the post-approval handler routes correctly.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:advocat/services/tool_definitions.dart';

void main() {
  late AssistantTools tools;

  setUp(() {
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  // ── D5.1 — Schema registration ─────────────────────────────────────────

  group('Email Agent D5 — schema registration', () {
    test('list_inbox is registered in toolDefinitions', () {
      expect(ToolDefinitions.getDefinition('list_inbox'), isNotNull);
      expect(ToolDefinitions.toolNames, contains('list_inbox'));
    });

    test('get_thread_triage is registered in toolDefinitions', () {
      expect(ToolDefinitions.getDefinition('get_thread_triage'), isNotNull);
      expect(ToolDefinitions.toolNames, contains('get_thread_triage'));
    });

    test('approve_send_draft is registered in toolDefinitions', () {
      expect(ToolDefinitions.getDefinition('approve_send_draft'), isNotNull);
      expect(ToolDefinitions.toolNames, contains('approve_send_draft'));
    });

    test('snooze_thread is registered in toolDefinitions', () {
      expect(ToolDefinitions.getDefinition('snooze_thread'), isNotNull);
      expect(ToolDefinitions.toolNames, contains('snooze_thread'));
    });
  });

  // ── D5.2 — Schemas mirror existing pattern ─────────────────────────────

  group('Email Agent D5 — schema shape', () {
    test('list_inbox declares severity-filter enum', () {
      final def = ToolDefinitions.getDefinition('list_inbox')!;
      final props = (def['input_schema'] as Map<String, dynamic>)['properties']
          as Map<String, dynamic>;
      // severity is optional, but when given must be one of the 4 enums.
      final severity = props['severity'] as Map<String, dynamic>;
      final enumVals = (severity['enum'] as List).cast<String>();
      expect(
        enumVals,
        containsAll(<String>['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']),
      );
    });

    test('get_thread_triage requires thread_id', () {
      final def = ToolDefinitions.getDefinition('get_thread_triage')!;
      final required =
          ((def['input_schema'] as Map<String, dynamic>)['required'] as List)
              .cast<String>();
      expect(required, contains('thread_id'));
    });

    test('approve_send_draft requires triage_id', () {
      final def = ToolDefinitions.getDefinition('approve_send_draft')!;
      final required =
          ((def['input_schema'] as Map<String, dynamic>)['required'] as List)
              .cast<String>();
      expect(required, contains('triage_id'));
    });

    test('snooze_thread requires thread_id', () {
      final def = ToolDefinitions.getDefinition('snooze_thread')!;
      final required =
          ((def['input_schema'] as Map<String, dynamic>)['required'] as List)
              .cast<String>();
      expect(required, contains('thread_id'));
    });
  });

  // ── D5.3 — Approval semantics ──────────────────────────────────────────

  group('Email Agent D5 — approval semantics', () {
    test('approve_send_draft is in requiresApproval set', () {
      expect(
        AssistantTools.requiresApproval,
        contains('approve_send_draft'),
        reason:
            'approve_send_draft dispatches mail via send-email; spec §D5 '
            'mandates the same approval flow as the existing send_email tool.',
      );
    });

    test('list_inbox is NOT in requiresApproval (read-only)', () {
      expect(AssistantTools.requiresApproval, isNot(contains('list_inbox')));
    });

    test('get_thread_triage is NOT in requiresApproval (read-only)', () {
      expect(
        AssistantTools.requiresApproval,
        isNot(contains('get_thread_triage')),
      );
    });

    test('snooze_thread is NOT in requiresApproval (passive)', () {
      expect(
        AssistantTools.requiresApproval,
        isNot(contains('snooze_thread')),
      );
    });
  });

  // ── D5.4 — Handler input hardening ─────────────────────────────────────

  group('Email Agent D5 — handler input hardening', () {
    test('get_thread_triage rejects missing thread_id', () async {
      final r = await tools.execute('get_thread_triage', <String, dynamic>{});
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('thread_id'));
    });

    test('approve_send_draft rejects missing triage_id', () async {
      final r =
          await tools.execute('approve_send_draft', <String, dynamic>{});
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('triage_id'));
    });

    test('snooze_thread rejects missing thread_id', () async {
      final r = await tools.execute('snooze_thread', <String, dynamic>{});
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('thread_id'));
    });

    test('list_inbox rejects severity outside enum', () async {
      final r = await tools.execute('list_inbox', {
        'severity': 'CATASTROPHIC',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('severity'));
    });
  });

  // ── D5.5 — Demo / happy path returns expected card data ───────────────
  // SupabaseService is in demo mode (no creds at compile time per test
  // helpers). Handlers must produce a structured ToolResult so chat cards
  // render even before Supabase plumbing fires.

  group('Email Agent D5 — demo-mode handler shape', () {
    test('list_inbox returns inbox card with severity-sorted threads', () async {
      final r =
          await tools.execute('list_inbox', <String, dynamic>{});
      expect(r.success, isTrue);
      expect(r.cardType, equals('inbox_list'));
      expect(r.data, isNotNull);
      expect(r.data!['threads'], isA<List<dynamic>>());
      // Severity sort: every preceding thread must have severity_rank
      // ≤ the next one (CRITICAL=0, HIGH=1, MEDIUM=2, LOW=3).
      final threads = (r.data!['threads'] as List).cast<Map<String, dynamic>>();
      for (var i = 1; i < threads.length; i++) {
        expect(
          (threads[i - 1]['severity_rank'] as int) <=
              (threads[i]['severity_rank'] as int),
          isTrue,
          reason: 'list_inbox must return threads sorted by severity rank '
              '(CRITICAL→LOW).',
        );
      }
    });

    test('list_inbox excludes threads snoozed within 24h', () async {
      final r = await tools.execute('list_inbox', <String, dynamic>{});
      expect(r.success, isTrue);
      final threads = (r.data!['threads'] as List).cast<Map<String, dynamic>>();
      // Demo fixtures must not surface user_action='snoozed' rows whose
      // seen_by_user_at is within the last 24h.
      for (final t in threads) {
        expect(
          t['user_action'],
          isNot(equals('snoozed')),
          reason: 'list_inbox UI filter: snoozed threads hide for 24h.',
        );
      }
    });

    test('snooze_thread returns user_action=snoozed in card data', () async {
      final r = await tools.execute('snooze_thread', {
        'thread_id': '00000000-0000-0000-0000-000000000001',
      });
      expect(r.success, isTrue);
      expect(r.cardType, equals('thread_snoozed'));
      expect(r.data, isNotNull);
      expect(r.data!['user_action'], equals('snoozed'));
      expect(r.data!['thread_id'], isNotNull);
      // 24h hide window — UI uses seen_by_user_at to compute it.
      expect(r.data!['seen_by_user_at'], isNotNull);
    });

    test('approve_send_draft prepares email-draft card with send_via', () async {
      final r = await tools.execute('approve_send_draft', {
        'triage_id': '00000000-0000-0000-0000-000000000123',
      });
      expect(r.success, isTrue);
      expect(r.cardType, equals('email_draft'));
      expect(r.requiresApproval, isTrue,
          reason:
              'approve_send_draft is in requiresApproval; the handler itself '
              'must also flag it so the chat UI shows the confirm modal.');
      expect(r.data, isNotNull);
      // Routes through the existing send-email Edge Function — the post-
      // approval handler MUST call send-email, not a new path. This guard
      // proves the contract.
      expect(r.data!['send_via'], equals('send-email'));
      expect(r.data!['triage_id'], isNotNull);
    });

    test('get_thread_triage returns full triage card by thread_id', () async {
      final r = await tools.execute('get_thread_triage', {
        'thread_id': '00000000-0000-0000-0000-000000000001',
      });
      expect(r.success, isTrue);
      expect(r.cardType, equals('thread_triage'));
      expect(r.data, isNotNull);
      expect(r.data!['thread_id'], isNotNull);
    });
  });
}
