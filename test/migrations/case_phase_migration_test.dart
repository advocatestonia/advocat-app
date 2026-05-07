@Tags(['fast'])
library;

// =============================================================================
// case_phase_migration_test.dart — schema contract for Phase 2 Pkg 5
// =============================================================================
//
// 2026-05-06 — Pkg 5 of the Phase 2 advanced track. Pins the migration
// file so the Flutter `CasePhaseService`, the `case-auto-patch` edge fn
// extension, and the workspace UI all rely on a stable column shape +
// the `set_case_phase` RPC.
//
// Static-text contract — no DB connection. Asserts:
//   1. file exists at the expected path,
//   2. adds `phase`, `phase_entered_at`, `phase_metadata` columns,
//   3. CHECK constraint `user_cases_phase_chk` with all 5 phase values,
//   4. backfill rule promotes case_numbers-bearing rows to 'strategy',
//   5. `set_case_phase` RPC defined with security invoker,
//   6. PGRST schema reload notify present (avoids stale schema cache).
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pkg 5 — case phase migration', () {
    final migrationFile = File(
      'supabase/migrations/20260507150000_case_phase.sql',
    );

    late String sql;

    setUpAll(() {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Pkg 5 migration file is missing: ${migrationFile.path}. '
            'The Flutter CasePhaseService and case-auto-patch extension '
            'depend on this schema — restore the file instead of '
            'removing the test.',
      );
      sql = migrationFile.readAsStringSync();
    });

    test('adds phase column on user_cases', () {
      expect(sql, contains('add column if not exists phase'));
    });

    test('adds phase_entered_at column on user_cases', () {
      expect(sql, contains('add column if not exists phase_entered_at'));
    });

    test('adds phase_metadata jsonb column on user_cases', () {
      expect(sql, contains('add column if not exists phase_metadata'));
    });

    test('CHECK constraint named user_cases_phase_chk', () {
      expect(
        sql,
        contains('user_cases_phase_chk'),
        reason: 'Constraint name pinned by edge-fn tests + design doc §3.',
      );
    });

    test('CHECK constraint enumerates all 5 phase values', () {
      // Single-quoted SQL literals.
      for (final phase in const [
        "'intake'",
        "'strategy'",
        "'draft'",
        "'wait'",
        "'closed'",
      ]) {
        expect(
          sql,
          contains(phase),
          reason:
              'Phase value $phase missing from migration — CHECK '
              'constraint or backfill drift.',
        );
      }
    });

    test('backfill promotes case_numbers-bearing rows to strategy', () {
      expect(
        sql,
        contains('jsonb_array_length(case_numbers) > 0'),
        reason:
            'Sulga-class cases that already have a docket must NOT '
            'sit awkwardly in intake — they backfill to strategy.',
      );
      expect(
        sql,
        contains("then 'strategy'"),
        reason: 'Backfill target phase mismatch.',
      );
    });

    test('phase column defaults to intake', () {
      expect(
        sql,
        contains("alter column phase set default 'intake'"),
        reason:
            'New rows inserted without phase must land in intake by '
            'default — pinned by Pkg 3 intake-wizard contract.',
      );
    });

    test('set_case_phase RPC is defined', () {
      expect(
        sql,
        contains('function public.set_case_phase'),
      );
      expect(
        sql,
        contains('security invoker'),
        reason:
            'RPC must use security invoker so RLS applies — users can '
            'only transition their own cases.',
      );
    });

    test('set_case_phase signature: (uuid, text, jsonb)', () {
      expect(sql, contains('p_case_id  uuid'));
      expect(sql, contains('p_phase    text'));
      expect(sql, contains('p_metadata jsonb'));
    });

    test('PGRST schema reload notify present', () {
      // memory: reference_pitfalls_chat_infra — the new RPC is silently
      // unreachable until PGRST refreshes its schema cache.
      expect(sql, contains("notify pgrst, 'reload schema'"));
    });

    test('phase index exists for active-cases hot path', () {
      expect(sql, contains('user_cases_phase_idx'));
      expect(sql, contains("status = 'active'"));
    });
  });
}
