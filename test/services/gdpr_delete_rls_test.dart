// Test for FIX-2 (Sprint 0) — GDPR Art. 17 right-to-erasure RLS policies.
// -----------------------------------------------------------------------------
// Ref: docs/performance/04-database.md P0 — "Verify and fix chat_messages
// DELETE RLS". Client code calls `.from('chat_messages').delete()` as part
// of account purge, but no delete policy exists, so the delete silently
// fails. This test is a SOURCE-CODE CONTRACT test (like the auth.test.ts
// T14-T18 pattern) — it asserts the migration file exists and declares
// the required policies.
//
// We cannot unit-test live RLS in Dart (no DB); live verification is the
// owner's responsibility via `supabase db push` + the SQL check in
// docs/security/FINAL.md §Action 3.
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FIX-2 — GDPR Art. 17 delete policies migration', () {
    // The migration must live at this exact path so `supabase db push`
    // picks it up in order (timestamp > 20260421).
    final migrationFile = File(
      'supabase/migrations/20260422060000_delete_own_policies.sql',
    );

    test('migration file exists at expected path', () {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Expected supabase/migrations/20260422060000_delete_own_policies.sql to '
            'exist. This migration is required for GDPR Art. 17 '
            '(right to erasure) — see docs/performance/04-database.md P0.',
      );
    });

    final sql = migrationFile.existsSync()
        ? migrationFile.readAsStringSync()
        : '';

    test('declares chat_messages_delete_own policy', () {
      expect(sql, contains('chat_messages_delete_own'));
      expect(sql, contains('on public.chat_messages'));
      // RLS policy must scope to auth.uid() = user_id (never a weaker check).
      expect(
        sql,
        contains(RegExp(r'auth\.uid\(\)\s*=\s*user_id')),
        reason:
            'chat_messages delete policy must scope to auth.uid() = user_id '
            '(no other clause can be weaker — cross-user deletes must be '
            'impossible).',
      );
    });

    test('declares conversation_summaries_delete_own policy', () {
      expect(sql, contains('conversation_summaries_delete_own'));
      // Table may not exist on fresh DB — migration must guard with a check.
      expect(
        sql,
        contains("from pg_tables"),
        reason:
            'conversation_summaries policy creation must be guarded by a '
            "pg_tables existence check, so the migration doesn't fail on a "
            'fresh local DB where the table has not been created yet '
            '(schema-drift — see FIX-3).',
      );
    });

    test('declares checker_reports_delete_own policy', () {
      expect(sql, contains('checker_reports_delete_own'));
      expect(sql, contains('on public.checker_reports'));
    });

    test('migration is idempotent (uses pg_policies existence guards)', () {
      // Every policy creation must be wrapped in a "not exists in pg_policies"
      // check so running `supabase db push` twice is a no-op.
      // Count `policyname = '...'` guards vs `create policy` statements.
      final policyGuards = RegExp(r"policyname\s*=\s*'").allMatches(sql).length;
      final createPolicyStatements = RegExp(
        r'create policy\s*"',
      ).allMatches(sql).length;
      expect(
        policyGuards,
        greaterThanOrEqualTo(createPolicyStatements),
        reason:
            'Every `create policy` must be preceded by a `pg_policies` '
            'existence guard. Found $createPolicyStatements create statements '
            'but only $policyGuards existence guards — migration is NOT '
            'idempotent.',
      );
    });

    test('no DROP or ALTER statements (FIX-2 is additive only)', () {
      // Per Sprint 0 instruction: owner decides applying; migrations must
      // never drop/alter existing structures without explicit request.
      expect(
        sql.toLowerCase(),
        isNot(contains('drop policy')),
        reason: 'FIX-2 must not drop existing policies.',
      );
      expect(
        sql.toLowerCase(),
        isNot(contains('drop table')),
      );
      expect(
        sql.toLowerCase(),
        isNot(contains('alter table')),
        reason: 'FIX-2 must not alter tables. Only `create policy` allowed.',
      );
    });
  });

  group('FIX-2 — supabase_service.dart delete flow sanity', () {
    // The actual source code must still attempt the deletes in the order
    // the migration enables. This is a smoke test that the helper function
    // deleteAllUserData continues to exist and covers the tables the new
    // RLS policies protect. It only verifies the method is callable;
    // behavior is tested by existing supabase_service_test.dart + live
    // Supabase integration.
    final svcFile = File('lib/services/supabase_service.dart');

    test('deleteAllUserData still deletes chat_messages', () {
      final src = svcFile.readAsStringSync();
      expect(
        src,
        contains("from('chat_messages').delete()"),
        reason:
            'supabase_service.dart must still delete chat_messages for the '
            'new RLS policy to take effect on account purge. If this call '
            'is removed, the delete_own policy is dead code.',
      );
    });
  });
}
