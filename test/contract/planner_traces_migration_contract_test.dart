@Tags(['fast'])
library;

// =============================================================================
// planner_traces_migration_contract_test.dart — Phase 2 Pkg 6
// =============================================================================
//
// 2026-05-07 — Pkg 6 of the planner+executor+critique loop. Pins the SQL
// contract for `chat_planner_traces` and the `planner_trace(uuid)` RPC.
//
// Pattern matches `citations_migration_contract_test.dart` (Pkg 2): read
// the migration file from disk and grep load-bearing identifiers. We pin
// the structural invariants that, if silently changed, would break the
// reasoning-trail UI extension, the eval suite, or the security model.
//
// What this file covers:
//   1. Idempotency: every CREATE / ALTER is `if not exists`-guarded.
//   2. RLS: read-own-only via JOIN to chat_messages.user_id (we deliberately
//      do NOT denormalise user_id onto the trace row — the join enforces
//      ownership and stays consistent if a message is reassigned).
//   3. No INSERT/UPDATE/DELETE policy: writes go through service_role from
//      the legal_planner orchestrator. Anon + authenticated cannot mint
//      traces, which keeps `regenerated_once` / `cost_cents` trustworthy.
//   4. FK cascade on chat_messages(id) ON DELETE CASCADE — traces follow
//      their message lifecycle.
//   5. UNIQUE INDEX on message_id — one trace per message; regen overwrites
//      via service-role upsert, never appends.
//   6. CHECK constraints on latency_ms/cost_cents (>= 0).
//   7. user_settings extension: `enable_planner_for_legal_turns` boolean
//      default false (default-OFF contract — only opted-in users pay the
//      extra latency).
//   8. planner_trace(uuid) RPC: SECURITY DEFINER, explicit search_path
//      pin, auth.uid() null guard, and owner re-check via chat_messages
//      join (NOT trusting the request payload).
//   9. PGRST schema-cache reload at end-of-file.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readMigration(String name) {
  final dir = Directory('supabase/migrations');
  if (!dir.existsSync()) {
    throw StateError(
      'Migrations directory not found at ${dir.absolute.path}. '
      'flutter test must run from the package root.',
    );
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains(name))
      .toList();
  if (files.isEmpty) {
    throw StateError('Migration matching "$name" not found in ${dir.path}');
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files.last.readAsStringSync();
}

void main() {
  late String sql;
  setUpAll(() => sql = _readMigration('planner_traces'));

  group('chat_planner_traces — idempotency', () {
    test('CREATE TABLE is `if not exists`-guarded', () {
      expect(
        sql.contains(RegExp(
          r'create\s+table\s+if\s+not\s+exists\s+public\.chat_planner_traces',
          caseSensitive: false,
        )),
        isTrue,
        reason: 'Re-applying the migration must not error.',
      );
    });

    test('uniqueness index on message_id is `if not exists`', () {
      expect(
        sql.contains(RegExp(
          r'create\s+unique\s+index\s+if\s+not\s+exists\s+chat_planner_traces_message_uq',
          caseSensitive: false,
        )),
        isTrue,
      );
    });

    test('user_settings ALTER uses `add column if not exists`', () {
      expect(
        sql.contains(RegExp(
          r'alter\s+table\s+public\.user_settings\s+add\s+column\s+if\s+not\s+exists\s+enable_planner_for_legal_turns',
          caseSensitive: false,
        )),
        isTrue,
      );
    });
  });

  group('chat_planner_traces — schema invariants', () {
    test('FK to chat_messages is ON DELETE CASCADE', () {
      expect(
        sql.contains(RegExp(
          r'message_id[^,]*references\s+public\.chat_messages\(id\)\s+on\s+delete\s+cascade',
          caseSensitive: false,
        )),
        isTrue,
      );
    });

    test('latency_ms and cost_cents have non-negative CHECK', () {
      expect(sql.contains(RegExp(r'latency_ms\s+int\s+not\s+null\s+check\s*\(\s*latency_ms\s*>=\s*0\s*\)')),
          isTrue);
      expect(sql.contains(RegExp(r'cost_cents\s+int\s+not\s+null[^,]*check\s*\(\s*cost_cents\s*>=\s*0\s*\)')),
          isTrue);
    });

    test('plan and critique are jsonb (forward-compat for new fields)', () {
      expect(sql.contains(RegExp(r'plan\s+jsonb\s+not\s+null')), isTrue);
      expect(sql.contains(RegExp(r'critique\s+jsonb\s+not\s+null')), isTrue);
    });

    test('regenerated_once defaults to false (loop guard contract)', () {
      expect(
        sql.contains(RegExp(
          r'regenerated_once\s+boolean\s+not\s+null\s+default\s+false',
          caseSensitive: false,
        )),
        isTrue,
      );
    });
  });

  group('chat_planner_traces — RLS', () {
    test('RLS is enabled on the table', () {
      expect(
        sql.contains(RegExp(
          r'alter\s+table\s+public\.chat_planner_traces\s+enable\s+row\s+level\s+security',
          caseSensitive: false,
        )),
        isTrue,
      );
    });

    test('SELECT policy uses JOIN to chat_messages.user_id (not denormalised)', () {
      // The body of the using() clause must reference the chat_messages join
      // pattern. We grep for both auth.uid() and the m.user_id alias (or the
      // unqualified user_id check on chat_messages).
      expect(sql, contains('auth.uid()'));
      expect(
        sql.contains(RegExp(
          r'from\s+public\.chat_messages\s+m\s+where\s+m\.id\s*=\s*chat_planner_traces\.message_id',
          caseSensitive: false,
        )),
        isTrue,
        reason: 'Owner check must JOIN to chat_messages.user_id.',
      );
    });

    test('NO INSERT / UPDATE / DELETE policies (service-role only writes)', () {
      // Negative match — there must be no `for insert`/`for update`/`for delete`
      // policy clauses in the file. (Read policy is `for select`.)
      expect(sql.contains(RegExp(r'for\s+insert', caseSensitive: false)), isFalse);
      expect(sql.contains(RegExp(r'for\s+update', caseSensitive: false)), isFalse);
      expect(sql.contains(RegExp(r'for\s+delete', caseSensitive: false)), isFalse);
    });
  });

  group('user_settings extension', () {
    test('enable_planner_for_legal_turns defaults to false', () {
      expect(
        sql.contains(RegExp(
          r'enable_planner_for_legal_turns\s+boolean[\s\S]*default\s+false',
          caseSensitive: false,
        )),
        isTrue,
        reason: 'Default-OFF contract — only opted-in users pay the latency cost.',
      );
    });
  });

  group('planner_trace(uuid) RPC', () {
    test('declared as SECURITY DEFINER with explicit search_path', () {
      expect(sql, contains('security definer'));
      expect(sql, contains('set search_path = public'));
    });

    test('rejects unauthenticated callers via auth.uid() null guard', () {
      expect(sql.contains(RegExp(r'auth\.uid\(\)\s+is\s+null')), isTrue);
      expect(sql, contains("'unauthorized'"));
    });

    test('owner re-check via chat_messages join (not request payload)', () {
      expect(
        sql.contains(RegExp(
          r'select\s+user_id\s+into\s+v_owner[\s\S]+from\s+public\.chat_messages',
          caseSensitive: false,
        )),
        isTrue,
      );
      expect(sql, contains("'forbidden'"));
    });

    test('grants execute to authenticated', () {
      expect(
        sql,
        contains(
          'grant execute on function public.planner_trace(uuid) to authenticated',
        ),
      );
    });

    test('owner pinned to postgres (B5 convention)', () {
      expect(
        sql.contains(RegExp(
          r'alter\s+function\s+public\.planner_trace\(uuid\)\s+owner\s+to\s+postgres',
          caseSensitive: false,
        )),
        isTrue,
      );
    });
  });

  test('PGRST schema-cache reload at end-of-file', () {
    expect(sql.contains(RegExp(r"notify\s+pgrst,\s*'reload schema'")), isTrue);
  });
}
