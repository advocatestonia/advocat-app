// agent_intentions_test.dart — TDD coverage for set_followup_intention.
// -----------------------------------------------------------------------------
// Ref: lib/services/tool_definitions.dart
//      lib/services/assistant_tools.dart#_setFollowupIntention
//      supabase/migrations/20260505110000_agent_intentions.sql
//
// Scope:
//   - Tool schema: shape, name, required fields, enum on intent_type
//   - Handler: input validation (missing fields, bad enum, bad ISO date)
//   - Handler: 500-char cap on context_summary (GDPR guard)
//   - Handler: returns success card with intention metadata in demo mode
//   - Tool registration: present in tools map and toolNames list
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:advocat/services/tool_definitions.dart';

void main() {
  late AssistantTools tools;

  // Dynamic future date — hardcoded dates rotted once they fell into the
  // past (5 tests started failing after 2026-06-05).
  final futureCheckAtIso = DateTime.now()
      .toUtc()
      .add(const Duration(days: 30))
      .toIso8601String();
  final futureCheckAtDate = futureCheckAtIso.substring(0, 10);

  setUp(() {
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  group('set_followup_intention — schema', () {
    test('is registered in tool definitions', () {
      final def = ToolDefinitions.getDefinition('set_followup_intention');
      expect(def, isNotNull,
          reason: 'set_followup_intention must be in toolDefinitions');
    });

    test('appears in toolNames', () {
      expect(
        ToolDefinitions.toolNames,
        contains('set_followup_intention'),
      );
    });

    test('schema declares the four enum values for intent_type', () {
      final def = ToolDefinitions.getDefinition('set_followup_intention')!;
      final schema = def['input_schema'] as Map<String, dynamic>;
      final props = schema['properties'] as Map<String, dynamic>;
      final intentType = props['intent_type'] as Map<String, dynamic>;
      final enumVals = (intentType['enum'] as List).cast<String>();
      expect(enumVals, containsAll(<String>[
        'remind_deadline',
        'check_court_status',
        'follow_up_question',
        'check_company_status',
      ]));
    });

    test('schema requires intent_type, check_at, context_summary', () {
      final def = ToolDefinitions.getDefinition('set_followup_intention')!;
      final schema = def['input_schema'] as Map<String, dynamic>;
      final required = (schema['required'] as List).cast<String>();
      expect(required, containsAll(<String>[
        'intent_type',
        'check_at',
        'context_summary',
      ]));
    });

    test('description hints at follow-up promises', () {
      final def = ToolDefinitions.getDefinition('set_followup_intention')!;
      final desc = (def['description'] as String).toLowerCase();
      expect(desc, contains('follow'));
    });
  });

  group('set_followup_intention — handler input hardening', () {
    test('missing intent_type returns structured error', () async {
      final r = await tools.execute('set_followup_intention', {
        'check_at': futureCheckAtIso,
        'context_summary': 'Check appeal',
      });
      expect(r.success, isFalse);
      expect(r.displayText, isNotEmpty);
    });

    test('missing check_at returns structured error', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'context_summary': 'Check appeal',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('check_at'));
    });

    test('missing context_summary returns structured error', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': futureCheckAtIso,
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('context_summary'));
    });

    test('invalid intent_type is rejected', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'do_something_evil',
        'check_at': futureCheckAtIso,
        'context_summary': 'x',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('intent_type'));
    });

    test('malformed check_at ISO is rejected', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': 'not-a-date',
        'context_summary': 'Check appeal',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('check_at'));
    });

    test('past check_at is rejected (must be in future)', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': '2020-01-01T00:00:00Z',
        'context_summary': 'Stale reminder',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('future'));
    });

    test('context_summary >500 chars is rejected (GDPR cap)', () async {
      final long = 'x' * 501;
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': futureCheckAtIso,
        'context_summary': long,
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('500'));
    });

    test('exactly 500 chars is accepted', () async {
      final boundary = 'x' * 500;
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': futureCheckAtIso,
        'context_summary': boundary,
      });
      expect(r.success, isTrue,
          reason: 'exactly 500 chars must pass — bug 22.04.2026 lesson');
    });
  });

  group('set_followup_intention — happy path (demo mode)', () {
    test('returns success card with cardType=intention_set', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': futureCheckAtIso,
        'context_summary': '30-day appeal deadline for PPA decision',
      });
      expect(r.success, isTrue);
      expect(r.cardType, equals('intention_set'));
      expect(r.data, isNotNull);
    });

    test('returned data carries intent_type and check_at', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'check_court_status',
        'target_id': 'R-2025/123',
        'check_at': futureCheckAtIso,
        'context_summary': 'Check Sulga case status',
      });
      expect(r.success, isTrue);
      expect(r.data!['intent_type'], 'check_court_status');
      expect(r.data!['target_id'], 'R-2025/123');
      // check_at must serialise as ISO 8601 in UTC.
      final iso = r.data!['check_at'] as String;
      expect(iso, contains(futureCheckAtDate));
    });

    test('does NOT require user approval (passive scheduling)', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'follow_up_question',
        'check_at': futureCheckAtIso,
        'context_summary': 'Check on appeal preparation progress',
      });
      // The handler itself must NOT mark requiresApproval — set_followup_intention
      // is a passive action; nothing is sent until the cron fires later.
      // (The static `requiresApproval` set in AssistantTools must not include it.)
      expect(r.requiresApproval, isFalse,
          reason: 'set_followup_intention is passive — no approval needed');
    });

    test('displayText mentions when the user will be reminded', () async {
      final r = await tools.execute('set_followup_intention', {
        'intent_type': 'remind_deadline',
        'check_at': futureCheckAtIso,
        'context_summary': 'Appeal deadline',
      });
      expect(r.success, isTrue);
      // Must reference the date so the user knows when to expect contact.
      expect(r.displayText, contains(futureCheckAtDate));
    });
  });
}
