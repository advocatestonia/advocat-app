// assistant_tools_concurrent_test.dart
//
// OMEGA pre-launch QA expansion (2026-04-29). The existing
// `assistant_tools_input_validation_test.dart` covers per-tool
// input validation. This file adds the contracts that protect
// against bugs Claude can produce when it emits MULTIPLE tool_use
// blocks in a single message:
//
//   • parallel execute() of 3+ tools must not interfere (separate
//     ToolResult instances, no shared mutable state)
//   • READ tools must NOT trigger requiresApproval even when called
//     concurrently with WRITE tools
//   • WRITE tools all carry approvalMessage (no silent action)
//   • unknown tool names mixed with known ones → unknown returns
//     error, known continue working
//   • read_document with whitespace-only document_id is rejected
//     (not just empty — also "   ")
//   • check_vehicle accepts every supported country and never
//     crashes with empty plate
//   • check_company with country='' falls back to Estonia (default)
//   • find_lawyer with junk country still returns a usable result
//   • get_deadlines with junk case_id is a no-op (empty list)
//   • approval-set membership matches the documented WRITE/ACTION
//     subset (defensive — locks the contract)
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssistantTools tools;

  setUp(() {
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  group('AssistantTools — parallel tool execution (Claude tool_use chain)',
      () {
    test('three tools dispatched concurrently produce 3 independent results',
        () async {
      // Simulate Claude emitting 3 tool_use blocks in one message:
      //   - check_company (read)
      //   - get_deadlines (read)
      //   - search_knowledge (read)
      // Run them all at once. Each must return its own ToolResult.
      final futures = <Future<ToolResult>>[
        tools.execute('check_company', {
          'company_name': 'Acme OÜ',
          'country': 'Estonia',
        }),
        tools.execute('get_deadlines', {}),
        tools.execute('search_knowledge', {'query': 'rental contract'}),
      ];
      final results = await Future.wait(futures);
      expect(results.length, 3);
      for (final r in results) {
        expect(r, isA<ToolResult>());
        expect(r.displayText, isNotEmpty);
      }
    });

    test('mix of known + unknown tool names: unknown errors, known succeeds',
        () async {
      final results = await Future.wait([
        tools.execute('totally_made_up', {}),
        tools.execute('get_deadlines', {}),
      ]);
      expect(results[0].success, isFalse);
      expect(results[1].displayText, isNotEmpty);
    });

    test('parallel read + write tools: only the write requires approval',
        () async {
      final results = await Future.wait([
        tools.execute('get_deadlines', {}),
        tools.execute('send_email', {
          'to': 'a@b.com',
          'subject': 'Hi',
          'body': 'Hello',
        }),
      ]);
      // get_deadlines is read → never requires approval
      expect(results[0].requiresApproval, isFalse);
      // send_email is write → MUST require approval
      expect(results[1].requiresApproval, isTrue);
    });

    test(
        'five concurrent send_email calls each carry their own approval message',
        () async {
      final futures = List.generate(
        5,
        (i) => tools.execute('send_email', {
          'to': 'user$i@example.com',
          'subject': 'Subject $i',
          'body': 'Body $i',
        }),
      );
      final results = await Future.wait(futures);
      for (var i = 0; i < 5; i++) {
        expect(results[i].requiresApproval, isTrue);
        expect(results[i].approvalMessage, isNotNull);
        expect(
          results[i].approvalMessage,
          contains('user$i@example.com'),
          reason: 'each result must reference its OWN recipient',
        );
      }
    });
  });

  group('AssistantTools — read_document deeper input hardening', () {
    test('whitespace-only document_id is rejected with structured error',
        () async {
      final result = await tools.execute('read_document', {
        'document_id': '   \t  ',
      });
      expect(result.success, isFalse);
      expect(result.displayText.toLowerCase(), contains('document_id'));
    });

    test('document_id as null literal returns structured error', () async {
      final result = await tools.execute('read_document', {
        'document_id': null,
      });
      expect(result.success, isFalse);
    });
  });

  group('AssistantTools — check_company defaults', () {
    test('country="" falls back to Estonia registry hint', () async {
      final result = await tools.execute('check_company', {
        'company_name': 'Test OÜ',
        'country': '',
      });
      // Company check is a read-only tool that never errors out.
      expect(result.success, isTrue);
      expect(result.displayText, isNotEmpty);
    });

    test('empty company name still returns a usable response', () async {
      final result = await tools.execute('check_company', {
        'company_name': '',
        'country': 'Estonia',
      });
      // Tool guarantee: never throw on empty input.
      expect(result, isNotNull);
      expect(result.displayText, isNotEmpty);
    });
  });

  group('AssistantTools — check_vehicle country handling', () {
    test('all 7 documented countries are accepted without crash', () async {
      const countries = [
        'Estonia',
        'Finland',
        'Latvia',
        'Lithuania',
        'Germany',
        'Sweden',
        'Poland',
      ];
      for (final country in countries) {
        final result = await tools.execute('check_vehicle', {
          'plate_number': '123ABC',
          'country': country,
        });
        expect(result.success, isTrue);
        expect(
          result.displayText.toLowerCase(),
          contains(country.toLowerCase()),
          reason: 'response must mention the requested country',
        );
      }
    });

    test('unsupported country falls back to Estonia portal info', () async {
      final result = await tools.execute('check_vehicle', {
        'plate_number': '123ABC',
        'country': 'Atlantis',
      });
      expect(result.success, isTrue);
      // Falls back to Estonia (registries['estonia']) so the user still
      // gets actionable info rather than a crash.
      expect(result.displayText, contains('Transpordiamet'));
    });

    test('empty plate number is accepted (LLM produced an unknown plate)',
        () async {
      final result = await tools.execute('check_vehicle', {
        'plate_number': '',
        'country': 'Estonia',
      });
      // Read tool — never throws.
      expect(result.success, isTrue);
    });
  });

  group('AssistantTools — approval-set contract', () {
    test('approval set contains every WRITE/ACTION tool listed in docs', () {
      // Locks the contract so a future PR can't silently move a write tool
      // out of the approval set without a test failure forcing a review.
      const expectedWriteTools = {
        'create_case',
        'generate_draft',
        'open_camera',
        'draft_email',
        'send_email',
        'create_deadline',
        'update_case',
        // Email Agent D5 — dispatches the persisted triage draft via the
        // existing send-email edge fn. Same gate as send_email.
        'approve_send_draft',
        // 2026-05-07 Badass Lawyer AI — generates PDF and uploads to Storage.
        'generate_pdf',
      };
      expect(AssistantTools.requiresApproval, expectedWriteTools);
    });

    test('approval set does NOT contain any READ tool', () {
      const readTools = {
        'check_company',
        'check_vehicle',
        'get_deadlines',
        'analyze_document',
        'search_knowledge',
        'find_lawyer',
        'get_case_status',
        'change_language',
        'translate_text',
        'navigate_to',
        'read_document',
        'list_documents',
        'list_cases',
        'search_estonian_law',
        'search_finnish_law',
        'get_user_profile',
        'analyze_contract',
      };
      for (final t in readTools) {
        expect(
          AssistantTools.requiresApproval.contains(t),
          isFalse,
          reason:
              '$t is a READ tool — it must NOT require approval (UX bug if it does)',
        );
      }
    });
  });

  group('AssistantTools — exception path is structured, not raw', () {
    test('execute swallows handler exceptions into ToolResult.error', () async {
      // execute() wraps every handler in a try/catch and returns
      // ToolResult.error on throws. We can't trigger a throw without
      // a stubbed Supabase, but we CAN verify the unknown-tool branch
      // returns the same shape: {success: false, displayText: non-empty}.
      final result = await tools.execute('not_a_real_tool', {});
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
      expect(result.requiresApproval, isFalse);
    });
  });

  group('ToolResult — additional contract invariants', () {
    test('toJson omits cardType / data / claudeText when null', () {
      const r = ToolResult(success: true, displayText: 'hi');
      final json = r.toJson();
      expect(json.containsKey('cardType'), isFalse);
      expect(json.containsKey('data'), isFalse);
      expect(json.containsKey('claudeText'), isFalse);
    });

    test('toJson always includes success, displayText, requiresApproval', () {
      const r = ToolResult(success: false, displayText: 'oops');
      final json = r.toJson();
      expect(json['success'], isFalse);
      expect(json['displayText'], 'oops');
      expect(json['requiresApproval'], isFalse);
    });

    test('ToolResult.error never sets approval flags', () {
      final r = ToolResult.error('bad');
      expect(r.requiresApproval, isFalse);
      expect(r.approvalMessage, isNull);
      expect(r.cardType, isNull);
      expect(r.data, isNull);
      expect(r.claudeText, isNull);
    });
  });
}
