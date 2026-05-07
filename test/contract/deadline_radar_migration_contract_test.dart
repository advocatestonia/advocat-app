@Tags(['fast'])
library;

// =============================================================================
// deadline_radar_migration_contract_test.dart — Phase 2 Pkg 9 contract.
// =============================================================================
//
// 2026-05-06 — Pkg 9. Pins the SQL contract for the three Pkg 9 migrations:
//
//   * 20260507100000_case_deadlines.sql            — table + indexes + RLS + RPCs
//   * 20260507110000_deadline_notification_log.sql — idempotency log + RLS
//   * 20260507120000_deadline_extractor_rpcs.sql   — apply_deadline_extraction
//
// Pattern: read the migration file from disk and grep load-bearing
// identifiers. Mirrors phase2_pii_migration_contract_test.dart and
// case_memory_migration_test.dart.
//
// Without these tests, an accidental rename, dropped policy, or reshuffled
// audit-insert order would only show up as a 4xx in production.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locate a migration whose filename contains [name].
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
  // -------------------------------------------------------------------------
  // 1. case_deadlines table
  // -------------------------------------------------------------------------
  group('Pkg 9 migrations contract — case_deadlines (G9-1)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('case_deadlines'));

    test('table declared', () {
      expect(sql, contains('create table if not exists public.case_deadlines'));
    });

    test('FK to user_cases on delete cascade', () {
      expect(
        sql,
        contains(
          'case_id             uuid not null references public.user_cases(id) on delete cascade',
        ),
        reason:
            'case_deadlines.case_id must FK to user_cases with cascade delete '
            '(architect §4 — close the case, drop the deadlines)',
      );
    });

    test('FK to auth.users on delete cascade', () {
      expect(
        sql,
        contains(
          'user_id             uuid not null references auth.users(id) on delete cascade',
        ),
      );
    });

    test('FK to case_documents on delete set null', () {
      // architect §4 — losing the source doc must not delete the deadline.
      expect(
        sql,
        contains(
          'source_doc_id       uuid references public.case_documents(id) on delete set null',
        ),
      );
    });

    test('case_deadline_status enum has 4 values', () {
      expect(sql, contains("'active'"));
      expect(sql, contains("'completed'"));
      expect(sql, contains("'missed'"));
      expect(sql, contains("'archived'"));
    });

    test('case_deadline_priority enum has 4 values', () {
      expect(sql, contains("'critical'"));
      expect(sql, contains("'high'"));
      expect(sql, contains("'medium'"));
      expect(sql, contains("'low'"));
    });

    test('case_deadline_source enum has 6 values', () {
      expect(sql, contains("'pdf'"));
      expect(sql, contains("'intake'"));
      expect(sql, contains("'manual'"));
      expect(sql, contains("'email'"));
      expect(sql, contains("'haiku_extract'"));
      expect(sql, contains("'statutory_template'"));
    });

    test('critical_source check constraint present (Risk #1)', () {
      // Architect §11 #1 — never auto-create a `priority='critical'`
      // deadline from `source='haiku_extract'`. Constraint guards this at
      // the row level.
      expect(
        sql,
        contains('case_deadlines_critical_source_check'),
        reason:
            'critical priority must be source-restricted to '
            '(pdf,intake,manual,email,statutory_template)',
      );
    });

    test('partial cron-scan index on (deadline_at) where status=active', () {
      // Architect §6 — partial index for cron sweep efficiency.
      expect(sql, contains('case_deadlines_cron_scan_idx'));
      expect(
        sql,
        contains("where status = 'active'"),
        reason: 'cron-scan index must be partial on active rows only',
      );
    });

    test('unique-on-natural-key dedupe index (architect §5)', () {
      // case_deadlines_anchor_dedupe_idx prevents two extractions of the
      // same kaebus deadline (from PDF + intake) creating two rows.
      expect(
        sql,
        contains('case_deadlines_anchor_dedupe_idx'),
        reason:
            "natural-key (case_id, anchor_key, (deadline_at AT TIME ZONE 'UTC')::date) "
            'must be uniquely enforced for upsert dedupe',
      );
      expect(
        sql,
        contains('where anchor_key is not null'),
        reason:
            'dedupe index must be partial — manual rows without anchor '
            'are user-controlled and may legitimately duplicate',
      );
      // IMMUTABLE-safe date cast — bare `timestamptz::date` is only STABLE
      // (depends on session TimeZone GUC); Postgres rejects STABLE
      // expressions in index definitions. Pinning to UTC makes it IMMUTABLE.
      expect(
        sql,
        contains("(deadline_at AT TIME ZONE 'UTC')::date"),
        reason:
            'index expression must be IMMUTABLE — wrap timestamptz::date in '
            "AT TIME ZONE 'UTC' so expression is deterministic",
      );
    });

    test('RLS enabled on the table', () {
      expect(sql, contains('alter table public.case_deadlines enable row level security'));
    });

    test('owner-only policy via auth.uid()', () {
      expect(sql, contains('auth.uid() = user_id'));
      expect(sql, contains('with check (auth.uid() = user_id)'));
    });

    test('updated_at trigger present', () {
      expect(sql, contains('case_deadlines_updated_at'));
      expect(sql, contains('before update on public.case_deadlines'));
    });

    test('active_deadlines RPC declared (radar widget RPC)', () {
      expect(
        sql,
        contains('create or replace function public.active_deadlines'),
      );
      expect(
        sql,
        contains('security invoker'),
        reason:
            'active_deadlines must be security invoker so RLS confines '
            "results to the caller's rows",
      );
      expect(sql, contains('set search_path = public'));
    });

    test('case_deadlines_for RPC declared (per-case list RPC)', () {
      expect(
        sql,
        contains('create or replace function public.case_deadlines_for'),
      );
    });

    test('mark_deadline_complete RPC: SECURITY DEFINER + auth check', () {
      expect(
        sql,
        contains('create or replace function public.mark_deadline_complete'),
      );
      expect(sql, contains('security definer'));
      expect(sql, contains('set search_path = public'));
      // architect hard-constraint: explicit auth.uid() is null check.
      expect(
        sql,
        contains('if auth.uid() is null then'),
        reason: 'SECURITY DEFINER mutators must reject anonymous calls',
      );
      expect(sql, contains("raise exception 'unauthorized'"));
      expect(
        sql,
        contains('alter function public.mark_deadline_complete(uuid, text)'),
        reason: 'SECURITY DEFINER fn must alter owner to postgres',
      );
    });

    test('PGRST schema-cache reload at end-of-file', () {
      expect(
        sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
        isTrue,
        reason:
            'every Phase 2 migration that adds RPCs/tables must end with '
            'PGRST cache reload (memory: reference_pitfalls_chat_infra)',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 2. deadline_notification_log
  // -------------------------------------------------------------------------
  group('Pkg 9 migrations contract — deadline_notification_log (G9-2)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('deadline_notification_log'));

    test('table declared', () {
      expect(
        sql,
        contains(
            'create table if not exists public.deadline_notification_log'),
      );
    });

    test('FK to case_deadlines on delete cascade', () {
      expect(
        sql,
        contains(
          'deadline_id     uuid not null references public.case_deadlines(id) on delete cascade',
        ),
      );
    });

    test('threshold CHECK enumerates 5 values', () {
      // Wire contract: cron pusher inserts these literal strings. Any
      // rename silently disables the threshold (CHECK violation on insert).
      expect(sql, contains("'30d'"));
      expect(sql, contains("'7d'"));
      expect(sql, contains("'3d'"));
      expect(sql, contains("'1d'"));
      expect(sql, contains("'morning_of'"));
    });

    test('channel CHECK enumerates 3 channels', () {
      expect(sql, contains("'push'"));
      expect(sql, contains("'email'"));
      expect(sql, contains("'in_app'"));
    });

    test('unique constraint on (deadline_id, threshold, channel) — idempotency', () {
      // Architect §6 + Risk #3: this unique constraint is the at-most-once
      // delivery guarantee. Without it, cron drift causes duplicate pushes.
      expect(
        sql,
        contains('unique (deadline_id, threshold, channel)'),
        reason:
            'idempotency guard — without this unique, cron drift causes '
            'duplicate pushes',
      );
    });

    test('RLS enabled', () {
      expect(
        sql,
        contains('alter table public.deadline_notification_log enable row level security'),
      );
    });

    test('only SELECT policy — service-role-only writes', () {
      // Mirrors audit_log: client roles can read their own rows but never
      // write directly. Cron pusher uses service-role.
      expect(sql, contains('for select'));
      // Verify there's no insert/update/delete policy.
      expect(
        sql.contains('for insert'),
        isFalse,
        reason: 'no client INSERT policy — only service-role can write',
      );
      expect(
        sql.contains('for update'),
        isFalse,
        reason: 'no client UPDATE policy — log rows are append-only',
      );
      expect(
        sql.contains('for delete'),
        isFalse,
        reason: 'no client DELETE policy — log rows are permanent',
      );
    });

    test('PGRST schema-cache reload at end-of-file', () {
      expect(
        sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // 3. deadline_extractor_rpcs — apply_deadline_extraction
  // -------------------------------------------------------------------------
  group('Pkg 9 migrations contract — apply_deadline_extraction (G9-3)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('deadline_extractor_rpcs'));

    test('apply_deadline_extraction RPC declared', () {
      expect(
        sql,
        contains('create or replace function public.apply_deadline_extraction'),
      );
    });

    test('SECURITY DEFINER with explicit search_path', () {
      // Hard-constraint: SECURITY DEFINER + dynamic search_path is a
      // privilege-escalation path. Pinning search_path closes it.
      expect(sql, contains('security definer'));
      expect(
        sql,
        contains('set search_path = public'),
        reason:
            'SECURITY DEFINER fn must pin search_path to defeat schema '
            'injection',
      );
    });

    test('rejects auth.uid() is null', () {
      expect(
        sql,
        contains('if auth.uid() is null then'),
        reason:
            'SECURITY DEFINER fn must reject anonymous calls (belt-and-'
            'braces beyond PostgREST JWT enforcement)',
      );
      expect(sql, contains("raise exception 'unauthorized'"));
    });

    test('verifies ownership via user_cases', () {
      // Owner check resolves user_id from public.user_cases (RLS-protected),
      // not from any client-supplied payload. Same anti-tamper pattern as
      // public.unredact (G5 from Pkg 0).
      expect(sql, contains('from public.user_cases'));
      expect(sql, contains('where id = p_case_id'));
      expect(
        sql,
        contains("raise exception 'forbidden'"),
        reason: 'must reject calls where caller is not the case owner',
      );
    });

    test('upserts on natural key (case_id, anchor_key, deadline_at::date)', () {
      // The dedupe rule from architect §5. Without this, two extractions of
      // the same kaebus deadline create two rows.
      expect(
        sql,
        contains('anchor_key = (v_row->>'),
        reason: 'must look up existing row by anchor_key',
      );
      expect(
        sql,
        contains("deadline_at::date = ((v_row->>'deadline_at')::timestamptz)::date"),
        reason: 'natural-key match must be on date portion',
      );
    });

    test('Risk #5: completed deadlines are not reopened', () {
      // Architect §11 #5 — if a row already has status='completed', the
      // extractor must skip it (do not reopen).
      expect(
        sql,
        contains("v_existing_status = 'completed'"),
        reason:
            'must guard upsert against reopening a completed deadline',
      );
    });

    test('owner is altered to postgres (privilege boundary)', () {
      expect(
        sql,
        contains('alter function public.apply_deadline_extraction(uuid, jsonb)'),
      );
      expect(sql, contains('owner to postgres'));
    });

    test('PGRST schema-cache reload at end-of-file', () {
      expect(
        sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // 4. Cross-migration filename slot ordering (architect §1 hard rule)
  // -------------------------------------------------------------------------
  group('Pkg 9 — migration filename slots', () {
    test('takes _10/_11/_12 (pkg 2 closeout owns _09)', () {
      final files = Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList()
        ..sort();

      expect(
        files.any((f) => f.contains('20260507100000_case_deadlines')),
        isTrue,
        reason: 'Pkg 9 must occupy slot _10 (timestamp 20260507100000)',
      );
      expect(
        files.any(
            (f) => f.contains('20260507110000_deadline_notification_log')),
        isTrue,
        reason: 'Pkg 9 must occupy slot _11 (timestamp 20260507110000)',
      );
      expect(
        files.any((f) => f.contains('20260507120000_deadline_extractor_rpcs')),
        isTrue,
        reason: 'Pkg 9 must occupy slot _12 (timestamp 20260507120000)',
      );
    });
  });
}
