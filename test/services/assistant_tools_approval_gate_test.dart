import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

/// OMEGA-QA — AssistantTools write-tool consent-gate regression tests.
///
/// Locks in the invariant that WRITE/ACTION tools are consent-gated: they
/// must surface `requiresApproval == true` so the chat UI is *obligated* to
/// render an approval card before the action is acted upon.
///
/// Two layers are pinned here:
///   1. Static membership of [AssistantToolExecutor.requiresApproval] — the
///      declarative gate set. A future refactor must not silently drop a
///      write-tool (create_case / create_deadline / update_case / …) from
///      this set.
///   2. Executor-level contract — `execute('<write_tool>', …)` returns a
///      [ToolResult] with `requiresApproval == true`, even for handlers that
///      forget to set the flag themselves (the executor stamps it post-hoc
///      for any tool in the set — see assistant_tools.dart lines ~213-224).
///
/// KNOWN CONSENT GAP (documented, intentionally NOT asserted as safe here):
///   The DB INSERT currently happens *inside* the handler (e.g. _createCase
///   calls _supabase.createCase(...) before returning). The runtime gate that
///   actually withholds the side effect until the user taps "Approve" lives in
///   chat_screen.dart's _executeToolCall / onApprove path (Zone A), NOT in this
///   executor. In demo mode (SupabaseService uninitialized → isDemo) the write
///   is an in-memory no-op, so these tests exercise the contract without a live
///   DB. This suite guards the *executor-level* contract only: that the
///   approval flag survives — so a refactor cannot quietly regress the gate set
///   and let a write-tool through without an approval card.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssistantTools tools;

  setUp(() {
    // Uninitialized SupabaseService → isDemo == true. Write handlers
    // (createCase / createDeadline / updateCase) degrade to in-memory /
    // no-op behavior, so execute() completes without a live backend.
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  group('AssistantTools.requiresApproval — gate set membership', () {
    test('contains the core write tools (create_case / create_deadline / '
        'update_case)', () {
      expect(AssistantTools.requiresApproval, contains('create_case'));
      expect(AssistantTools.requiresApproval, contains('create_deadline'));
      expect(AssistantTools.requiresApproval, contains('update_case'));
    });

    test('contains the email/dispatch write tools', () {
      // draft_email / send_email / approve_send_draft all trigger outbound
      // mail and MUST stay gated.
      expect(AssistantTools.requiresApproval, contains('draft_email'));
      expect(AssistantTools.requiresApproval, contains('send_email'));
      expect(AssistantTools.requiresApproval, contains('approve_send_draft'));
    });

    test('contains generate_pdf (writes a file to Storage)', () {
      expect(AssistantTools.requiresApproval, contains('generate_pdf'));
    });

    test('does NOT gate read-only tools (they must execute immediately)', () {
      // Read-only tools must never require approval — a regression that adds
      // them to the set would break the "act immediately" UX for reads.
      expect(AssistantTools.requiresApproval, isNot(contains('get_deadlines')));
      expect(AssistantTools.requiresApproval,
          isNot(contains('get_case_status')));
      expect(
          AssistantTools.requiresApproval, isNot(contains('search_knowledge')));
      expect(AssistantTools.requiresApproval, isNot(contains('list_cases')));
      expect(
          AssistantTools.requiresApproval, isNot(contains('list_documents')));
    });
  });

  group('AssistantTools.execute — write tools return requiresApproval', () {
    test('create_case returns ToolResult with requiresApproval == true',
        () async {
      final result = await tools.execute('create_case', {
        'title': 'Deportation appeal',
        'description': 'Migri negative decision, appeal to HAO',
        'case_type': 'deportation',
        'country': 'Finland',
      });

      expect(result.success, isTrue);
      expect(result.requiresApproval, isTrue,
          reason: 'UI is obligated to show an approval card for create_case');
      // A gated result must carry a human-readable prompt for the card.
      expect(result.approvalMessage, isNotNull);
      expect(result.approvalMessage, isNotEmpty);
    });

    test('create_deadline returns ToolResult with requiresApproval == true',
        () async {
      final result = await tools.execute('create_deadline', {
        'title': 'File appeal to HAO',
        'due_date': '2027-01-15',
      });

      expect(result.success, isTrue);
      expect(result.requiresApproval, isTrue,
          reason:
              'UI is obligated to show an approval card for create_deadline');
      expect(result.approvalMessage, isNotNull);
      expect(result.approvalMessage, isNotEmpty);
    });

    test('update_case returns ToolResult with requiresApproval == true',
        () async {
      final result = await tools.execute('update_case', {
        'case_id': 'case-123',
        'status': 'closed',
      });

      expect(result.success, isTrue);
      expect(result.requiresApproval, isTrue,
          reason: 'UI is obligated to show an approval card for update_case');
      expect(result.approvalMessage, isNotNull);
      expect(result.approvalMessage, isNotEmpty);
    });
  });
}
