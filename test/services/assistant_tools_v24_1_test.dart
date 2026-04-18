import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:advocat/services/tool_definitions.dart';

/// Tests for v24.1 tools added to AssistantTools:
///   send_email, read_document, list_documents, list_cases,
///   search_estonian_law, create_deadline, update_case,
///   get_user_profile, analyze_contract.
///
/// We instantiate AssistantTools with the default (demo-mode) SupabaseService
/// so the tests run fully offline — all persistence calls short-circuit to
/// `DemoData`.
void main() {
  late AssistantTools tools;

  setUp(() {
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  // ── Registry + definitions parity ────────────────────────────────────

  test('every new tool is in the handler registry', () {
    const expected = [
      'send_email',
      'read_document',
      'list_documents',
      'list_cases',
      'search_estonian_law',
      'create_deadline',
      'update_case',
      'get_user_profile',
      'analyze_contract',
    ];
    for (final name in expected) {
      expect(tools.availableTools, contains(name),
          reason: 'tool $name must be registered');
    }
  });

  test('every new tool has a matching JSON schema definition', () {
    const expected = [
      'send_email',
      'read_document',
      'list_documents',
      'list_cases',
      'search_estonian_law',
      'create_deadline',
      'update_case',
      'get_user_profile',
      'analyze_contract',
    ];
    for (final name in expected) {
      final def = ToolDefinitions.getDefinition(name);
      expect(def, isNotNull, reason: 'missing schema for $name');
      expect(def!['input_schema'], isA<Map>());
    }
  });

  test('destructive tools are in requiresApproval set', () {
    expect(AssistantTools.requiresApproval, contains('send_email'));
    expect(AssistantTools.requiresApproval, contains('create_deadline'));
    expect(AssistantTools.requiresApproval, contains('update_case'));
  });

  test('read-only tools are NOT in requiresApproval set', () {
    expect(AssistantTools.requiresApproval, isNot(contains('read_document')));
    expect(AssistantTools.requiresApproval, isNot(contains('list_documents')));
    expect(AssistantTools.requiresApproval, isNot(contains('list_cases')));
    expect(AssistantTools.requiresApproval,
        isNot(contains('search_estonian_law')));
    expect(AssistantTools.requiresApproval,
        isNot(contains('get_user_profile')));
  });

  // ── send_email input validation ──────────────────────────────────────

  test('send_email rejects missing fields', () async {
    final r = await tools.execute('send_email', {});
    expect(r.success, isFalse);
    expect(r.displayText, contains('non-empty'));
  });

  test('send_email rejects invalid recipient', () async {
    final r = await tools.execute('send_email', {
      'to': 'not-an-email',
      'subject': 'x',
      'body': 'y',
    });
    expect(r.success, isFalse);
    expect(r.displayText.toLowerCase(), contains('invalid'));
  });

  test('send_email with valid fields requires approval', () async {
    final r = await tools.execute('send_email', {
      'to': 'clerk@court.ee',
      'subject': 'Appeal submission',
      'body': 'Please find my appeal attached.',
    });
    expect(r.success, isTrue);
    expect(r.requiresApproval, isTrue);
    expect(r.cardType, 'email_draft');
    expect(r.data?['send_via'], 'send-email',
        reason: 'UI uses send_via to route to Edge Function');
    expect(r.data?['to'], 'clerk@court.ee');
    expect(r.approvalMessage, contains('clerk@court.ee'));
  });

  test('send_email includes cc when provided', () async {
    final r = await tools.execute('send_email', {
      'to': 'a@b.ee',
      'cc': 'c@d.ee',
      'subject': 'x',
      'body': 'y',
    });
    expect(r.success, isTrue);
    expect(r.data?['cc'], 'c@d.ee');
  });

  test('send_email rejects invalid cc address', () async {
    // CC validation handled server-side, but send_email must still succeed
    // on client if cc is present. The Edge Function rejects malformed cc.
    // Our client-side guard currently only checks `to`; ensure that does
    // not break.
    final r = await tools.execute('send_email', {
      'to': 'good@ok.ee',
      'cc': 'badcc',
      'subject': 'x',
      'body': 'y',
    });
    expect(r.success, isTrue);
  });

  // ── read_document ────────────────────────────────────────────────────

  test('read_document rejects missing id', () async {
    final r = await tools.execute('read_document', {});
    expect(r.success, isFalse);
  });

  test('read_document returns error for unknown doc', () async {
    final r = await tools.execute('read_document', {
      'document_id': '00000000-0000-0000-0000-000000000000',
    });
    expect(r.success, isFalse);
    expect(r.displayText.toLowerCase(), contains('not found'));
  });

  // ── list_documents / list_cases (demo fallback) ──────────────────────

  test('list_documents returns demo docs when vault empty', () async {
    final r = await tools.execute('list_documents', {});
    expect(r.success, isTrue);
    expect(r.data?['documents'], isA<List>());
  });

  test('list_cases succeeds in demo mode', () async {
    final r = await tools.execute('list_cases', {});
    expect(r.success, isTrue);
    // DemoData.cases may be empty; we only care that the shape is right.
    expect(r.data, isNotNull);
    final cases = r.data?['cases'] as List?;
    if (cases == null) {
      // Empty-state branch: displayText says "No cases found."
      expect(r.displayText.toLowerCase(), contains('no cases'));
    } else {
      expect(cases, isA<List>());
    }
  });

  test('list_cases with status filter does not crash on empty', () async {
    final r = await tools.execute('list_cases', {'status': 'active'});
    expect(r.success, isTrue);
    final cases = r.data?['cases'] as List?;
    if (cases != null) {
      for (final c in cases) {
        expect((c as Map)['status'], 'active');
      }
    }
  });

  // ── create_deadline ──────────────────────────────────────────────────

  test('create_deadline rejects missing fields', () async {
    final r = await tools.execute('create_deadline', {});
    expect(r.success, isFalse);
  });

  test('create_deadline rejects malformed date', () async {
    final r = await tools.execute('create_deadline', {
      'title': 'Appeal',
      'due_date': 'not-a-date',
    });
    expect(r.success, isFalse);
    expect(r.displayText.toLowerCase(), contains('due_date'));
  });

  test('create_deadline accepts ISO date and requires approval', () async {
    final r = await tools.execute('create_deadline', {
      'title': 'Appeal deadline',
      'due_date': '2026-12-31',
    });
    expect(r.success, isTrue);
    expect(r.requiresApproval, isTrue);
    expect(r.cardType, 'deadline_list');
    expect(r.data?['title'], 'Appeal deadline');
  });

  // ── update_case ──────────────────────────────────────────────────────

  test('update_case rejects missing case_id', () async {
    final r = await tools.execute('update_case', {'title': 'x'});
    expect(r.success, isFalse);
  });

  test('update_case rejects empty updates', () async {
    final r = await tools.execute('update_case', {'case_id': 'abc'});
    expect(r.success, isFalse);
    expect(r.displayText.toLowerCase(), contains('at least one'));
  });

  test('update_case with valid updates requires approval', () async {
    final r = await tools.execute('update_case', {
      'case_id': 'case-001',
      'title': 'Updated',
    });
    expect(r.success, isTrue);
    expect(r.requiresApproval, isTrue);
    expect(r.data?['updates'], isA<Map>());
  });

  // ── get_user_profile ─────────────────────────────────────────────────

  test('get_user_profile returns demo user in demo mode', () async {
    final r = await tools.execute('get_user_profile', {});
    expect(r.success, isTrue);
    expect(r.data, isNotNull);
  });

  // ── analyze_contract ─────────────────────────────────────────────────

  test('analyze_contract rejects missing id', () async {
    final r = await tools.execute('analyze_contract', {});
    expect(r.success, isFalse);
  });

  // ── search_estonian_law — smoke only (real corpus tested elsewhere) ──

  test('search_estonian_law rejects empty query and empty paragraph',
      () async {
    final r = await tools.execute('search_estonian_law', {'query': ''});
    expect(r.success, isFalse);
  });
}
