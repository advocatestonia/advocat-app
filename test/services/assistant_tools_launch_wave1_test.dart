import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';

/// launch/wave1 regression tests — Agent 1-1 (Legal CRITICAL fixes).
///
/// These tests lock down the behaviour of `create_deadline` and the
/// timezone-safe date parser, so that later refactors cannot silently
/// re-introduce the bugs that OMEGA-LEGAL identified for v24.2.3:
///
///   * `due_date` must land on the intended calendar day regardless of
///     the user's local timezone (no 1-day slip east of UTC).
///   * `create_deadline` must return a user-visible error when the
///     persist call fails, not silently succeed with a phantom deadline.
///
/// We run everything in demo mode (`SupabaseService()` default), so
/// persistence short-circuits to DemoData — good enough to prove the
/// contract-level guarantees.
void main() {
  late AssistantTools tools;

  setUp(() {
    tools = AssistantTools(supabaseService: SupabaseService());
  });

  group('create_deadline — timezone-safe due_date', () {
    test('YYYY-MM-DD input stays on the same calendar day in UTC', () async {
      final r = await tools.execute('create_deadline', {
        'title': 'Appeal filing',
        'due_date': '2026-05-01',
      });
      expect(r.success, isTrue);
      final iso = r.data?['due_date'] as String?;
      expect(iso, isNotNull);
      // Must serialise as 2026-05-01 in UTC, i.e. start with the exact date.
      // The previous bug turned this into 2026-04-30T21:00:00.000Z in
      // Tallinn (UTC+3). We lock to UTC noon specifically to avoid that.
      expect(iso!.startsWith('2026-05-01'), isTrue,
          reason: 'due_date must not slip across the date boundary; got $iso');
    });

    test('full ISO-8601 with explicit Z is preserved as UTC', () async {
      final r = await tools.execute('create_deadline', {
        'title': 'Hearing',
        'due_date': '2026-07-15T09:00:00Z',
      });
      expect(r.success, isTrue);
      final iso = r.data?['due_date'] as String?;
      expect(iso, isNotNull);
      expect(iso!.contains('2026-07-15'), isTrue);
    });

    test('malformed date is rejected with a user-facing message', () async {
      final r = await tools.execute('create_deadline', {
        'title': 'x',
        'due_date': '31/12/2026',
      });
      expect(r.success, isFalse);
      expect(r.displayText.toLowerCase(), contains('due_date'));
    });
  });

  group('create_deadline — error-handling contract', () {
    // In demo mode (SupabaseService() default, no real client), the persist
    // call short-circuits to DemoData.addDeadline(...) which succeeds. So we
    // cannot directly test the new error path without a mock SupabaseService.
    //
    // What we CAN lock down here is the shape of the success path: if the
    // persist call claims success, the tool must still expose case_id /
    // description back to the caller so the UI can render the approval card.
    test('success response exposes all input fields for approval UI', () async {
      final r = await tools.execute('create_deadline', {
        'title': 'Appeal deadline',
        'due_date': '2026-12-31',
        'case_id': '11111111-1111-1111-1111-111111111111',
        'description': 'File appeal with Halduskohus',
        'reminder_days_before': 7,
      });
      expect(r.success, isTrue);
      expect(r.requiresApproval, isTrue);
      expect(r.approvalMessage, isNotNull);
      expect(r.data?['title'], 'Appeal deadline');
      expect(r.data?['case_id'], '11111111-1111-1111-1111-111111111111');
      expect(r.data?['description'], 'File appeal with Halduskohus');
      // days_left must be a non-negative integer for future dates
      final daysLeft = r.data?['days_left'] as int?;
      expect(daysLeft, isNotNull);
      expect(daysLeft! >= 0, isTrue);
    });
  });
}
