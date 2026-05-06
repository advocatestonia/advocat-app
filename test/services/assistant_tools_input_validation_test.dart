import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

/// OMEGA-QA v1 — AssistantTools input validation regression tests.
///
/// The wow_scenarios_test covers happy-path tool execution. These tests
/// specifically pin the input-hardening contract: tools must never crash
/// on malformed params and must always return a user-presentable
/// [ToolResult] (non-empty displayText, success=false on invalid input).
///
/// Closes gaps around hardening the send_email / read_document / tool-router
/// surfaces called out in docs/qa/02-missing-tests.md and docs/qa/03-e2e-gaps.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssistantTools tools;

  setUp(() {
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  group('AssistantTools — unknown tool names', () {
    test('completely unknown tool returns error, not crash', () async {
      final result = await tools.execute('this_tool_does_not_exist', {});
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });

    test('empty tool name returns error', () async {
      final result = await tools.execute('', {});
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });

    test('tool name with spaces is handled safely', () async {
      final result = await tools.execute('send email', {}); // note the space
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });
  });

  group('AssistantTools — send_email input hardening', () {
    test('empty to/subject/body returns structured error', () async {
      final result = await tools.execute('send_email', {
        'to': '',
        'subject': '',
        'body': '',
      });
      expect(result.success, isFalse);
      expect(result.displayText.toLowerCase(), contains('requires'));
    });

    test('missing "to" key returns structured error', () async {
      final result = await tools.execute('send_email', {
        'subject': 'Hello',
        'body': 'Hi',
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });

    test('malformed email "not-an-email" is rejected', () async {
      final result = await tools.execute('send_email', {
        'to': 'not-an-email',
        'subject': 'Hello',
        'body': 'Hi',
      });
      expect(result.success, isFalse);
      expect(result.displayText.toLowerCase(), contains('invalid'));
    });

    test('email with spaces inside is rejected', () async {
      final result = await tools.execute('send_email', {
        'to': 'user @example.com',
        'subject': 'Hi',
        'body': 'Body',
      });
      expect(result.success, isFalse);
    });

    test('valid email produces approval-gated draft (requiresApproval=true)',
        () async {
      final result = await tools.execute('send_email', {
        'to': 'user@example.com',
        'subject': 'Hi',
        'body': 'Body',
      });
      expect(result.success, isTrue);
      expect(result.requiresApproval, isTrue);
      expect(result.cardType, equals('email_draft'));
      expect(result.displayText.toLowerCase(), contains('email'));
    });
  });

  group('AssistantTools — read_document input hardening', () {
    test('empty document_id returns structured error', () async {
      final result = await tools.execute('read_document', {
        'document_id': '',
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
      expect(result.displayText.toLowerCase(), contains('document_id'));
    });

    test('missing document_id key returns structured error', () async {
      final result = await tools.execute('read_document', {});
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });
  });

  group('AssistantTools — wrong parameter types do not crash', () {
    test('send_email with int instead of string "to" does not crash',
        () async {
      // The cast-to-String path uses `as String?` which returns null for
      // non-string values; the tool should surface a clean error.
      final result = await tools.execute('send_email', {
        'to': 42,
        'subject': 'Hi',
        'body': 'Body',
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });

    test('read_document with int document_id does not crash', () async {
      final result = await tools.execute('read_document', {
        'document_id': 12345,
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // G7 — lookup_statute input validation (security-review gate)
  // ---------------------------------------------------------------------------
  //
  // The handler at lib/services/assistant_tools.dart::_lookupStatute must:
  //   * reject empty act / paragraph with a structured error (no network)
  //   * uppercase the jurisdiction (so 'ee' → 'EE')
  //   * fall back to 'EE' for jurisdictions outside {EE, FI, EU} rather
  //     than POST a guaranteed-4xx request
  //
  // Production has no Supabase wired in this test environment, so the
  // network path returns "not in corpus" (success=true with found=false).
  // We assert on (a) error path for empty inputs and (b) the soft-fail
  // contract for the network path.
  group('AssistantTools — lookup_statute (G7) input hardening', () {
    test('rejects empty act with structured error (no network)', () async {
      final result = await tools.execute('lookup_statute', {
        'act': '',
        'paragraph': '88',
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
      expect(result.displayText.toLowerCase(), contains('act'));
    });

    test('rejects empty paragraph with structured error', () async {
      final result = await tools.execute('lookup_statute', {
        'act': 'TLS',
        'paragraph': '',
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
      expect(result.displayText.toLowerCase(), contains('paragraph'));
    });

    test('rejects both missing act and paragraph keys', () async {
      final result = await tools.execute('lookup_statute', {});
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });

    test('lowercase jurisdiction "ee" is normalized (no crash)', () async {
      // Without normalization the handler would either POST 'ee' (which
      // the edge function rejects, returning null) or local-validate
      // against {EE, FI, EU} and reject. With normalization, lookup
      // either succeeds or soft-fails to a "not in corpus" result.
      final result = await tools.execute('lookup_statute', {
        'act': 'TLS',
        'paragraph': '88',
        'jurisdiction': 'ee',
      });
      // Soft-fail to success+found=false is the documented contract;
      // an explicit error must NOT be returned.
      expect(result.success, isTrue,
          reason: 'lowercase jurisdiction must normalize to EE, not error');
      expect(result.data, isNotNull);
    });

    test('unsupported jurisdiction "XX" falls back to EE (no crash)',
        () async {
      final result = await tools.execute('lookup_statute', {
        'act': 'TLS',
        'paragraph': '88',
        'jurisdiction': 'XX',
      });
      // Same soft-fail contract — handler defaults to EE rather than
      // bubbling a 400 up to the user.
      expect(result.success, isTrue,
          reason: 'unsupported jurisdiction must fall back to EE silently');
      expect(result.data, isNotNull);
      expect(result.data!['jurisdiction'], 'EE',
          reason: 'fallback jurisdiction must be EE');
    });

    test('non-string act value does not crash the handler', () async {
      // The cast `params['act'] as String? ?? ''` returns '' for a
      // non-string value, which then hits the empty-input guard.
      final result = await tools.execute('lookup_statute', {
        'act': 42,
        'paragraph': '88',
      });
      expect(result.success, isFalse);
      expect(result.displayText, isNotEmpty);
    });
  });

  group('ToolResult contract invariants', () {
    test('ToolResult.error produces success=false and non-empty text', () {
      final r = ToolResult.error('something went wrong');
      expect(r.success, isFalse);
      expect(r.displayText, 'something went wrong');
      expect(r.requiresApproval, isFalse);
      expect(r.cardType, isNull);
      expect(r.data, isNull);
    });

    test('ToolResult.toJson includes only non-null optional fields', () {
      final r = const ToolResult(
        success: true,
        displayText: 'ok',
      );
      final json = r.toJson();
      expect(json['success'], isTrue);
      expect(json['displayText'], 'ok');
      expect(json['requiresApproval'], isFalse);
      expect(json.containsKey('cardType'), isFalse);
      expect(json.containsKey('data'), isFalse);
      expect(json.containsKey('claudeText'), isFalse);
    });

    test('ToolResult.toJson round-trips rich fields', () {
      final r = const ToolResult(
        success: true,
        displayText: 'preview',
        cardType: 'email_draft',
        data: {'to': 'a@b.com'},
        requiresApproval: true,
        approvalMessage: 'Send?',
        claudeText: 'Confirmed.',
      );
      final json = r.toJson();
      expect(json['cardType'], 'email_draft');
      expect(json['data'], equals({'to': 'a@b.com'}));
      expect(json['requiresApproval'], isTrue);
      expect(json['approvalMessage'], 'Send?');
      expect(json['claudeText'], 'Confirmed.');
    });
  });
}
