// assistant_tools_v2_tier1_test.dart — TDD coverage for v2.1 Tier-1 tools.
// -----------------------------------------------------------------------------
// Refs:
//   business/email_agent_handoff_2026-05-06/v2.1_consilium/TOOLS_INVENTORY.md
//   business/email_agent_handoff_2026-05-06/10_OPERATOR_PROMPT_v2_FI_EE_DEEP.md
//                                                              §4 (toolbelt)
//   lib/services/assistant_tools.dart — _documentExtractFacts /
//                                       _documentExtractDeadlines /
//                                       _documentDetectStateErrors /
//                                       _trackingFetchPosti /
//                                       _deadlineComputeWithHolidays /
//                                       _inboxReadThreadFull /
//                                       _lessonWriteFromMistake /
//                                       _lessonApplyToCurrentTask
//   lib/services/tool_definitions.dart — JSON schemas for the 8 tools
//
// Scope (per spec hard rules):
//   - Tool registration: each tool present on _tools, toolNames, definitions.
//   - Required input fields enforced; bad enums rejected.
//   - Approval semantics: NONE of the 7 Tier-1 tools mutate world state, so
//     none must be in requiresApproval (they are read-only wrappers).
//   - Demo / offline fallbacks return expected card shape so the chat UI
//     renders without live Supabase data.
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

  // ── T1 — Schema registration ────────────────────────────────────────────

  group('v2.1 Tier-1 — schema registration', () {
    const expected = <String>[
      'document_extract_facts',
      'document_extract_deadlines',
      'document_detect_state_errors',
      'tracking_fetch_posti',
      'deadline_compute_with_holidays',
      'inbox_read_thread_full',
      'lesson_write_from_mistake',
      'lesson_apply_to_current_task',
    ];

    test('every Tier-1 tool is registered on availableTools', () {
      for (final name in expected) {
        expect(tools.availableTools, contains(name),
            reason: 'tool $name must be on the AssistantTools registry');
      }
    });

    test('every Tier-1 tool has a JSON schema definition', () {
      for (final name in expected) {
        final def = ToolDefinitions.getDefinition(name);
        expect(def, isNotNull, reason: 'missing schema for $name');
        expect(def!['input_schema'], isA<Map>(),
            reason: '$name input_schema must be a Map');
        expect(ToolDefinitions.toolNames, contains(name),
            reason: 'toolNames must list $name');
      }
    });

    test('all Tier-1 tools are read-only (NOT in requiresApproval)', () {
      for (final name in expected) {
        expect(
          AssistantTools.requiresApproval,
          isNot(contains(name)),
          reason: '$name is a wrapper / read-only tool; only world-mutating '
              'tools (send_email, create_deadline, ...) require approval.',
        );
      }
    });
  });

  // ── T2 — document_extract_facts ─────────────────────────────────────────

  group('document_extract_facts', () {
    test('rejects missing file_path', () async {
      final r =
          await tools.execute('document_extract_facts', <String, dynamic>{});
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('file_path'));
    });

    test('Sulga demo fallback returns 6+ facts and 120-word summary',
        () async {
      final r = await tools.execute('document_extract_facts', {
        'file_path': 'sulga-poytakirja-5500R',
        'multi_pass': true,
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'document_facts');
      expect(r.data, isNotNull);
      final facts =
          (r.data!['facts'] as List).cast<Map<String, dynamic>>();
      expect(facts.length, greaterThanOrEqualTo(6),
          reason: 'Sulga fixture must surface at least the 3 identity '
              'errors + parties + case_numbers + admissions.');
      expect(r.data!['summary_120_words'], isA<String>());
      expect(r.data!['key_quotes'], isA<List>());
      // Identity-error category is the linchpin of Rule 34/35.
      expect(facts.any((f) => f['category'] == 'identity_errors'), isTrue);
    });
  });

  // ── T3 — document_extract_deadlines ─────────────────────────────────────

  group('document_extract_deadlines', () {
    test('rejects missing file_path', () async {
      final r = await tools.execute(
          'document_extract_deadlines', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('Sulga HAO demo returns KHO appeal route with 30 days', () async {
      final r = await tools.execute('document_extract_deadlines', {
        'file_path': 'sulga-hao-paatos.pdf',
        'case_id': '11111111-1111-1111-1111-111111111111',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'deadline_list');
      expect(r.data, isNotNull);
      final route = r.data!['appeal_route'] as Map<String, dynamic>?;
      expect(route, isNotNull);
      expect(route!['forum'], 'KHO');
      expect(route['deadline_days'], 30);
      final deadlines =
          (r.data!['deadlines'] as List).cast<Map<String, dynamic>>();
      expect(deadlines, isNotEmpty);
      expect(deadlines.first['statute_basis'], contains('valitusaika'));
    });
  });

  // ── T4 — document_detect_state_errors ───────────────────────────────────

  group('document_detect_state_errors', () {
    test('rejects missing file_path', () async {
      final r = await tools.execute(
          'document_detect_state_errors', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('Sulga demo flags 3-error pattern + stacking argument', () async {
      final r = await tools.execute('document_detect_state_errors', {
        'file_path': 'sulga-poytakirja-5500R.pdf',
        'user_identity': {
          'name': 'Dmitri Sulga',
          'citizenship': 'Estonia',
          'language_preference': 'ru',
        },
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'state_errors');
      expect(r.data, isNotNull);
      expect(r.data!['pattern_count'], greaterThanOrEqualTo(3));
      final errors =
          (r.data!['errors_found'] as List).cast<Map<String, dynamic>>();
      expect(
        errors.any((e) => e['error_type'] == 'citizenship_defunct_state'),
        isTrue,
      );
      expect(r.data!['stacking_argument'], isA<String>());
      expect((r.data!['stacking_argument'] as String).toLowerCase(),
          contains('hol'));
    });
  });

  // ── T5 — tracking_fetch_posti ───────────────────────────────────────────

  group('tracking_fetch_posti', () {
    test('rejects missing tracking_id', () async {
      final r =
          await tools.execute('tracking_fetch_posti', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('rejects malformed tracking_id', () async {
      final r = await tools.execute('tracking_fetch_posti', {
        'tracking_id': 'not-a-tracking-id',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('tracking_id'));
    });

    test('Sulga RS846423104FI fixture returns 4 events with delivery delay',
        () async {
      final r = await tools.execute('tracking_fetch_posti', {
        'tracking_id': 'RS846423104FI',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'tracking_posti');
      final events =
          (r.data!['events'] as List).cast<Map<String, dynamic>>();
      expect(events.length, 4);
      expect(r.data!['delivered'], isTrue);
      expect(r.data!['first_unsuccessful_at'], isNotNull);
    });

    test('unknown tracking_id falls back to manual-input prompt', () async {
      final r = await tools.execute('tracking_fetch_posti', {
        'tracking_id': 'AB123456789CD',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'tracking_posti_manual');
      expect(r.data!['manual_input_required'], isTrue);
      expect(r.data!['public_url'], contains('AB123456789CD'));
    });
  });

  // ── T6 — deadline_compute_with_holidays ─────────────────────────────────

  group('deadline_compute_with_holidays', () {
    test('rejects missing args', () async {
      final r = await tools.execute(
          'deadline_compute_with_holidays', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('rejects bad jurisdiction', () async {
      final r = await tools.execute('deadline_compute_with_holidays', {
        'start_date': '2026-05-06',
        'days': 30,
        'jurisdiction': 'XYZ',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('jurisdiction'));
    });

    test('FI 30d from 2026-05-06 lands on 2026-06-05 with no shift', () async {
      final r = await tools.execute('deadline_compute_with_holidays', {
        'start_date': '2026-05-06',
        'days': 30,
        'jurisdiction': 'FI',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'deadline_compute');
      expect(r.data!['deadline_naive'], '2026-06-05');
      expect(r.data!['deadline_shifted'], '2026-06-05');
      expect(r.data!['shift_reason'], '');
    });

    test('shifts Saturday deadline to Monday for FI', () async {
      // 2026-05-23 is a Saturday. 14 days from 2026-05-09 = 2026-05-23 (Sat).
      final r = await tools.execute('deadline_compute_with_holidays', {
        'start_date': '2026-05-09',
        'days': 14,
        'jurisdiction': 'FI',
      });
      expect(r.success, isTrue);
      expect(r.data!['deadline_naive'], '2026-05-23');
      expect(r.data!['deadline_shifted'], '2026-05-25');
      expect(r.data!['shift_reason'], 'weekend');
    });

    test('ECtHR does NOT shift on weekends per Protocol 15', () async {
      final r = await tools.execute('deadline_compute_with_holidays', {
        'start_date': '2026-05-09',
        'days': 14,
        'jurisdiction': 'ECtHR',
      });
      expect(r.success, isTrue);
      expect(r.data!['deadline_naive'], '2026-05-23');
      expect(r.data!['deadline_shifted'], '2026-05-23',
          reason: 'ECtHR Protocol 15 — no automatic extension on weekends.');
    });

    test('tiedoksisaanti_7d service basis adds 7 days to start', () async {
      final r = await tools.execute('deadline_compute_with_holidays', {
        'start_date': '2026-05-06',
        'days': 30,
        'jurisdiction': 'FI',
        'service_basis': 'tiedoksisaanti_7d',
      });
      expect(r.success, isTrue);
      // 2026-05-06 + 7d = 2026-05-13, +30d = 2026-06-12.
      expect(r.data!['effective_start'], '2026-05-13');
      expect(r.data!['deadline_shifted'], '2026-06-12');
    });
  });

  // ── T7 — inbox_read_thread_full ─────────────────────────────────────────

  group('inbox_read_thread_full', () {
    test('rejects missing thread_id', () async {
      final r =
          await tools.execute('inbox_read_thread_full', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('Sulga CRITICAL demo thread returns full message + attachment',
        () async {
      final r = await tools.execute('inbox_read_thread_full', {
        'thread_id': '00000000-0000-0000-0000-000000000001',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'thread_full');
      expect(r.data, isNotNull);
      final messages =
          (r.data!['messages'] as List).cast<Map<String, dynamic>>();
      expect(messages, isNotEmpty);
      expect(messages.first['from'], 'kirjaamo@oikeus.fi');
      final atts =
          (r.data!['attachments'] as List).cast<Map<String, dynamic>>();
      expect(atts, isNotEmpty);
      expect(r.data!['privilege_state'], 'open');
    });

    test('unknown thread_id surfaces a graceful error', () async {
      final r = await tools.execute('inbox_read_thread_full', {
        'thread_id': 'ffffffff-ffff-ffff-ffff-ffffffffffff',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('thread'));
    });
  });

  // ── T8 — lesson_write_from_mistake / lesson_apply_to_current_task ───────

  group('lesson_write_from_mistake', () {
    test('rejects missing required fields', () async {
      final r = await tools.execute(
          'lesson_write_from_mistake', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('rejects bad scope enum', () async {
      final r = await tools.execute('lesson_write_from_mistake', {
        'trigger': 'wrong court',
        'what_happened': 'filed at HAO',
        'what_to_do_next_time': 'check HOL § 114 first',
        'scope': 'banana',
        'category': 'legal_cite',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('scope'));
    });

    test('rejects scope=case without case_id', () async {
      final r = await tools.execute('lesson_write_from_mistake', {
        'trigger': 'wrong court',
        'what_happened': 'filed at HAO',
        'what_to_do_next_time': 'check HOL § 114 first',
        'scope': 'case',
        'category': 'legal_cite',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('case_id'));
    });

    test('successful write returns lesson_id + key + scope + category',
        () async {
      final r = await tools.execute('lesson_write_from_mistake', {
        'trigger': 'restoration motion at HAO',
        'what_happened':
            'HAO has no jurisdiction over menetetyn määräajan palauttaminen',
        'what_to_do_next_time':
            'always check HOL § 114-115 forum before filing',
        'scope': 'global',
        'category': 'legal_cite',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'lesson_saved');
      expect(r.data!['lesson_id'], isNotNull);
      expect(r.data!['key'], isA<String>());
      expect(r.data!['scope'], 'global');
      expect(r.data!['category'], 'legal_cite');
    });
  });

  group('lesson_apply_to_current_task', () {
    test('rejects missing task_description', () async {
      final r = await tools
          .execute('lesson_apply_to_current_task', <String, dynamic>{});
      expect(r.success, isFalse);
    });

    test('deadline-themed task surfaces HAO/KHO restoration lesson', () async {
      final r = await tools.execute('lesson_apply_to_current_task', {
        'task_description': 'drafting restoration motion for missed appeal '
            'deadline',
      });
      expect(r.success, isTrue);
      expect(r.cardType, 'lesson_apply');
      final lessons =
          (r.data!['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons, isNotEmpty);
      expect(lessons.first['key'].toString(), contains('hao_kho'));
    });

    test('unrelated task returns empty lesson list gracefully', () async {
      final r = await tools.execute('lesson_apply_to_current_task', {
        'task_description': 'recipe for borscht',
      });
      expect(r.success, isTrue);
      final lessons =
          (r.data!['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons, isEmpty);
    });

    test('honours max_lessons cap (1)', () async {
      final r = await tools.execute('lesson_apply_to_current_task', {
        'task_description': 'compute appeal deadline for HAO päätös',
        'max_lessons': 1,
      });
      expect(r.success, isTrue);
      final lessons =
          (r.data!['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons.length, lessThanOrEqualTo(1));
    });
  });
}
