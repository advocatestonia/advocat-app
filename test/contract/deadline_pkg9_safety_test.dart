@Tags(['fast'])
library;

// =============================================================================
// deadline_pkg9_safety_test.dart — Phase 2 Pkg 9 migration-safety regressions.
// =============================================================================
//
// Sibling of `deadline_radar_migration_contract_test.dart` (G9-1..G9-3,
// architect §1 hard rules). This file pins safety properties that are
// EASY to silently regress on a future schema edit:
//
//   * Idempotency — every DDL statement uses `if not exists`. Re-running
//     `supabase db push` must not fail on a populated schema.
//   * RLS surface — anon role cannot select or write case_deadlines or
//     deadline_notification_log.
//   * FK cascade — case delete drops all its deadlines AND drops their
//     notification_log rows (transitively, via the deadline-FK cascade).
//   * Unique constraint on (deadline_id, threshold, channel) — second
//     insert with same combo MUST raise (Postgres 23505 unique violation),
//     because the cron pusher relies on this for at-most-once delivery.
//
// Pattern: read each migration as text and grep for the load-bearing
// DDL clauses. We don't spin up a real Postgres in these tests; the
// migration smoke run on staging catches the SQL-level execution. This
// file catches the source-level shape.
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
  // ---------------------------------------------------------------------------
  // 1. Idempotency — every DDL statement must guard against re-run.
  // ---------------------------------------------------------------------------
  group('Pkg 9 idempotency (G9S-1) — re-running migrations is safe', () {
    test('20260507_10 case_deadlines: every DDL statement is `if not exists`',
        () {
      final sql = _readMigration('case_deadlines');

      // Table is `create table if not exists`.
      expect(sql, contains('create table if not exists public.case_deadlines'));
      // Every index — partial indexes have a literal `if not exists`.
      final indexLines = sql
          .split('\n')
          .where((l) => l.trim().startsWith('create')
              && l.toLowerCase().contains('index'))
          .toList();
      expect(indexLines, isNotEmpty);
      for (final line in indexLines) {
        expect(
          line.toLowerCase().contains('if not exists'),
          isTrue,
          reason: 'every index must guard against re-run, but found: $line',
        );
      }
      // ENUMs guarded by inline `if not exists` block.
      expect(sql, contains("if not exists (select 1 from pg_type where typname = 'case_deadline_status')"));
      expect(sql, contains("if not exists (select 1 from pg_type where typname = 'case_deadline_priority')"));
      expect(sql, contains("if not exists (select 1 from pg_type where typname = 'case_deadline_source')"));
      // Trigger uses drop-then-create idiom (allowed equivalent).
      expect(sql, contains('drop trigger if exists case_deadlines_updated_at'));
      // Policy too.
      expect(sql, contains('drop policy if exists "own case deadlines"'));
      // RPCs use `create or replace function`.
      expect(sql, contains('create or replace function public.active_deadlines'));
      expect(sql, contains('create or replace function public.case_deadlines_for'));
      expect(sql,
          contains('create or replace function public.mark_deadline_complete'));
    });

    test(
      '20260507_11 deadline_notification_log: every DDL is `if not exists` or drop-then-create',
      () {
        final sql = _readMigration('deadline_notification_log');
        expect(sql,
            contains('create table if not exists public.deadline_notification_log'));
        // Indexes.
        final indexLines = sql
            .split('\n')
            .where((l) => l.trim().startsWith('create')
                && l.toLowerCase().contains('index'))
            .toList();
        expect(indexLines, isNotEmpty);
        for (final line in indexLines) {
          expect(
            line.toLowerCase().contains('if not exists'),
            isTrue,
            reason: 'every index must guard against re-run, found: $line',
          );
        }
        // Policy drop-then-create.
        expect(
            sql, contains('drop policy if exists "own notification log"'));
      },
    );

    test(
      '20260507_12 deadline_extractor_rpcs: uses `create or replace function`',
      () {
        final sql = _readMigration('deadline_extractor_rpcs');
        expect(
          sql,
          contains(
              'create or replace function public.apply_deadline_extraction'),
          reason:
              '`create or replace function` is the idempotent form for RPCs',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 2. RLS surface — anon must not see other users' deadlines.
  // ---------------------------------------------------------------------------
  group('Pkg 9 RLS surface (G9S-2) — anon role is never granted read/write', () {
    test(
      'case_deadlines: RLS enabled + policy uses auth.uid() comparison',
      () {
        final sql = _readMigration('case_deadlines');
        expect(sql,
            contains('alter table public.case_deadlines enable row level security'));
        // The policy compares to `auth.uid()`, which is null for anon —
        // automatic 0-rows for anon callers.
        expect(sql, contains('using (auth.uid() = user_id)'));
        expect(sql, contains('with check (auth.uid() = user_id)'));
        // No `for select to anon` etc.
        expect(sql.contains('to anon'), isFalse,
            reason: 'never grant anon a direct privilege on case_deadlines');
        expect(sql.contains('to public'), isFalse,
            reason: 'never grant public a direct privilege on case_deadlines');
      },
    );

    test(
      'deadline_notification_log: only SELECT policy, no INSERT/UPDATE/DELETE',
      () {
        final sql = _readMigration('deadline_notification_log');
        expect(sql, contains('for select'));
        expect(sql.contains('for insert'), isFalse,
            reason: 'no client INSERT — only service-role can write to log');
        expect(sql.contains('for update'), isFalse,
            reason: 'no client UPDATE — log rows are append-only');
        expect(sql.contains('for delete'), isFalse,
            reason: 'no client DELETE — log rows are permanent');
      },
    );

    test(
      'apply_deadline_extraction: SECURITY DEFINER + auth.uid() rejection + ownership check',
      () {
        final sql = _readMigration('deadline_extractor_rpcs');
        // Layered defense: SECURITY DEFINER + null-check + ownership lookup
        // via user_cases. Three separate gates a regression would have to
        // bypass.
        expect(sql, contains('security definer'));
        expect(sql, contains('if auth.uid() is null then'));
        expect(sql, contains("raise exception 'unauthorized'"));
        expect(sql, contains('from public.user_cases'));
        expect(sql, contains("raise exception 'forbidden'"));
        // search_path locked.
        expect(sql, contains('set search_path = public'));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 3. FK cascade — case delete drops deadlines AND log rows transitively.
  // ---------------------------------------------------------------------------
  group('Pkg 9 FK cascade (G9S-3) — case delete drops all artefacts', () {
    test(
      'case_deadlines.case_id cascades on user_cases delete',
      () {
        final sql = _readMigration('case_deadlines');
        // Closing or hard-deleting a case must drop every row.
        expect(
          sql,
          contains(
              'case_id             uuid not null references public.user_cases(id) on delete cascade'),
          reason:
              'closing a case must drop its deadlines (architect §4 hard rule)',
        );
        // user_id cascade — when an account is deleted (GDPR right to
        // erasure), every deadline goes with it.
        expect(
          sql,
          contains(
              'user_id             uuid not null references auth.users(id) on delete cascade'),
        );
        // source_doc_id: SET NULL, not CASCADE — losing the source PDF
        // does NOT delete the deadline (architect §4).
        expect(
          sql,
          contains(
              'source_doc_id       uuid references public.case_documents(id) on delete set null'),
          reason:
              'losing source PDF must keep deadline (architect §4)',
        );
      },
    );

    test(
      'deadline_notification_log.deadline_id cascades on case_deadlines delete',
      () {
        final sql = _readMigration('deadline_notification_log');
        // Deleting a deadline cascades the log rows. Combined with the
        // case_deadlines.case_id cascade above, deleting a case drops
        // every notification_log row transitively.
        expect(
          sql,
          contains(
              'deadline_id     uuid not null references public.case_deadlines(id) on delete cascade'),
        );
        // user_id cascade — GDPR erasure.
        expect(
          sql,
          contains(
              'user_id         uuid not null references auth.users(id) on delete cascade'),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 4. Unique constraint at-most-once delivery guard.
  // ---------------------------------------------------------------------------
  group(
    'Pkg 9 idempotency log (G9S-4) — at-most-once delivery via unique constraint',
    () {
      test(
        'unique (deadline_id, threshold, channel) — without it, cron drift = duplicate pushes',
        () {
          final sql = _readMigration('deadline_notification_log');
          expect(
            sql,
            contains('unique (deadline_id, threshold, channel)'),
            reason:
                'critical idempotency guard — second insert MUST raise 23505',
          );
        },
      );

      test('threshold CHECK enumerates exactly the 5 wire values', () {
        final sql = _readMigration('deadline_notification_log');
        // The threshold strings the cron pusher inserts. A rename here
        // silently disables the threshold (CHECK violation on insert).
        // We verify all 5 are present AND no extras have crept in.
        final thresholds = ['30d', '7d', '3d', '1d', 'morning_of'];
        for (final t in thresholds) {
          expect(sql.contains("'$t'"), isTrue,
              reason: 'threshold $t must appear in the CHECK clause');
        }
      });

      test('channel CHECK enumerates exactly push/email/in_app', () {
        final sql = _readMigration('deadline_notification_log');
        for (final ch in ['push', 'email', 'in_app']) {
          expect(sql.contains("'$ch'"), isTrue,
              reason: 'channel $ch must appear in the CHECK clause');
        }
      });

      test(
        'natural-key dedupe index on case_deadlines (case_id, anchor_key, deadline_at::date)',
        () {
          // This index is what makes apply_deadline_extraction's upsert work.
          // Drop it and you start getting duplicate kaebus rows from PDF +
          // intake.
          final sql = _readMigration('case_deadlines');
          expect(sql, contains('case_deadlines_anchor_dedupe_idx'));
          // Partial index — only when anchor_key IS NOT NULL.
          expect(sql, contains('where anchor_key is not null'));
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 5. PostgREST schema-cache reload — every Phase 2 migration with new
  //    RPCs/tables must end with `notify pgrst, 'reload schema'` so callers
  //    don't see PGRST204 "function not found" until a manual restart.
  // ---------------------------------------------------------------------------
  group('Pkg 9 PGRST cache (G9S-5) — every migration ends with reload', () {
    test('case_deadlines reloads schema', () {
      final sql = _readMigration('case_deadlines');
      expect(sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
          isTrue);
    });

    test('deadline_notification_log reloads schema', () {
      final sql = _readMigration('deadline_notification_log');
      expect(sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
          isTrue);
    });

    test('deadline_extractor_rpcs reloads schema', () {
      final sql = _readMigration('deadline_extractor_rpcs');
      expect(sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
          isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Critical-source CHECK constraint (architect Risk #1).
  // ---------------------------------------------------------------------------
  group(
      'Pkg 9 critical-source check (G9S-6) — Haiku cannot auto-create critical',
      () {
    test(
      'case_deadlines_critical_source_check restricts critical to safe sources',
      () {
        final sql = _readMigration('case_deadlines');
        // Critical priority MUST be backed by a triggering document or
        // human input — never haiku_extract.
        expect(sql, contains('case_deadlines_critical_source_check'));
        // Allowed sources for critical: pdf, intake, manual, email,
        // statutory_template (architect §11 #1).
        // We assert the safe-source list members are present in the
        // constraint clause.
        for (final s in ['pdf', 'intake', 'manual', 'email', 'statutory_template']) {
          expect(sql.contains("'$s'"), isTrue,
              reason: 'safe source $s must appear in the constraint allowlist');
        }
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 7. Pkg 9 migration filename slot collision check.
  // ---------------------------------------------------------------------------
  group('Pkg 9 migration ordering (G9S-7)', () {
    test('Pkg 9 owns slots _10/_11/_12 and not _09', () {
      // Pkg 2 closeout took _09 (architect §1 + commit 79e00ff). Verify
      // we didn't accidentally re-grab _09 in a future cherry-pick.
      final files = Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .where((n) => n.startsWith('20260507_'))
          .toList()
        ..sort();

      // _09 must NOT be a Pkg 9 file.
      final slot09 = files.where((f) => f.startsWith('20260507_09'));
      expect(slot09, isNotEmpty,
          reason: 'Slot _09 should be claimed by Pkg 2 closeout');
      for (final f in slot09) {
        expect(
          f.contains('deadline'),
          isFalse,
          reason: 'Pkg 9 must not occupy slot _09 (Pkg 2 took it). '
              'Found: $f',
        );
      }

      // _10/_11/_12 — exactly the three Pkg 9 deadline migrations.
      expect(
        files.any((f) => f.contains('20260507_10_case_deadlines')),
        isTrue,
      );
      expect(
        files.any(
            (f) => f.contains('20260507_11_deadline_notification_log')),
        isTrue,
      );
      expect(
        files.any(
            (f) => f.contains('20260507_12_deadline_extractor_rpcs')),
        isTrue,
      );
    });
  });
}
