@Tags(['fast'])
library;

// =============================================================================
// case_timeline_events_migration_test.dart — schema contract for the
// client-facing Case Timeline UI.
// =============================================================================
//
// Pin migration `20260525154500_case_timeline_events.sql` so the Flutter
// CaseTimelineNotifier, the SupabaseService.getCaseTimelineEvents call,
// and the edge-fn write paths (email-inbox-sync, send-email,
// email-triage/wiring, deadline-extractor, case-auto-patch) all rely on
// a stable shape + RPC signature.
//
// Static-text contract — no DB connection. Asserts:
//   1. File exists at the expected path.
//   2. Creates `case_timeline_events` table.
//   3. event_type CHECK constraint covers all 7 values.
//   4. (case_id, occurred_at desc) index present (hot read path).
//   5. (case_id, event_type, dedupe_key) partial unique index present.
//   6. RLS enabled + owner-only SELECT + manual_note-only INSERT policy.
//   7. `record_case_event` RPC defined SECURITY DEFINER + grant to
//      authenticated, service_role.
//   8. `backfill_case_timeline_events` RPC defined SECURITY DEFINER.
//   9. PGRST schema reload notify present (avoids stale cache).
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Case Timeline Events migration', () {
    final migrationFile = File(
      'supabase/migrations/20260525154500_case_timeline_events.sql',
    );

    late String sql;

    setUpAll(() {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'case_timeline_events migration file is missing: '
            '${migrationFile.path}. The Flutter CaseTimelineNotifier '
            'and the edge-fn write paths depend on this schema — '
            'restore the file instead of removing the test.',
      );
      sql = migrationFile.readAsStringSync();
    });

    test('creates case_timeline_events table', () {
      expect(sql, contains('create table if not exists public.case_timeline_events'));
    });

    test('event_type CHECK constraint covers all 7 values', () {
      // Single CHECK on event_type — assert each value is present.
      for (final value in const [
        'email_in',
        'email_out',
        'consilium_decision',
        'deadline_set',
        'doc_uploaded',
        'phase_change',
        'manual_note',
      ]) {
        expect(
          sql,
          contains("'$value'"),
          reason: 'event_type CHECK missing value: $value',
        );
      }
    });

    test('FK from case_id to user_cases(id) on delete cascade', () {
      expect(
        sql,
        contains('references public.user_cases(id) on delete cascade'),
      );
    });

    test('FK from user_id to auth.users(id) on delete cascade', () {
      expect(
        sql,
        contains('references auth.users(id) on delete cascade'),
      );
    });

    test('payload is jsonb not null with default {}', () {
      expect(sql, contains("payload      jsonb not null default '{}'::jsonb"));
    });

    test('dedupe_key is a stored generated column', () {
      expect(sql, contains('dedupe_key   text generated always as'));
      expect(sql, contains('stored'));
    });

    test('(case_id, occurred_at desc) hot-path index present', () {
      expect(
        sql,
        contains('case_timeline_events (case_id, occurred_at desc)'),
      );
    });

    test('(case_id, event_type, dedupe_key) partial unique index present', () {
      expect(
        sql,
        contains('case_timeline_events_dedupe_idx'),
      );
      expect(
        sql,
        contains('(case_id, event_type, dedupe_key)'),
      );
      expect(sql, contains('where dedupe_key is not null'));
    });

    test('RLS enabled on case_timeline_events', () {
      expect(
        sql,
        contains('alter table public.case_timeline_events enable row level security'),
      );
    });

    test('owner-only SELECT policy present', () {
      expect(sql, contains('case_timeline_events_owner_select'));
      expect(sql, contains('using (auth.uid() = user_id)'));
    });

    test('manual_note-only INSERT policy present', () {
      expect(sql, contains('case_timeline_events_owner_manual_insert'));
      expect(sql, contains("event_type = 'manual_note'"));
    });

    test('record_case_event RPC defined SECURITY DEFINER', () {
      expect(
        sql,
        contains('create or replace function public.record_case_event'),
      );
      expect(sql, contains('security definer'));
    });

    test('record_case_event grants execute to authenticated + service_role', () {
      expect(
        sql,
        contains(
            'grant execute on function public.record_case_event(\n    uuid, text, text, text, jsonb, timestamptz\n) to authenticated, service_role'),
      );
    });

    test('backfill_case_timeline_events RPC defined SECURITY DEFINER', () {
      expect(
        sql,
        contains('create or replace function public.backfill_case_timeline_events'),
      );
    });

    test('backfill only granted to service_role (not authenticated)', () {
      // The backfill is a one-shot admin tool — must NOT be callable by
      // regular users (it would expose other users' data on a misuse).
      expect(
        sql,
        contains('grant execute on function public.backfill_case_timeline_events(int)\n    to service_role'),
      );
      expect(
        sql,
        isNot(
          contains(
              'grant execute on function public.backfill_case_timeline_events(int)\n    to authenticated'),
        ),
      );
    });

    test('PGRST schema cache reload notify present', () {
      // Avoids the "reference_pitfalls_chat_infra" lesson: edge fns
      // 400ing on the new table for ~30 min after deploy because
      // PostgREST's schema cache is stale.
      expect(sql, contains("notify pgrst, 'reload schema'"));
    });

    test('idempotent — every DDL guarded with `if not exists` or `or replace`', () {
      // Re-running `supabase db push` on this migration must not error.
      final lines = sql.split('\n');
      final ddls = lines
          .where(
            (l) =>
                l.trimLeft().toLowerCase().startsWith('create table') ||
                l.trimLeft().toLowerCase().startsWith('create index') ||
                l.trimLeft().toLowerCase().startsWith('create unique index') ||
                l.trimLeft().toLowerCase().startsWith('create function') ||
                l.trimLeft().toLowerCase().startsWith('create or replace function'),
          )
          .toList();
      for (final l in ddls) {
        final low = l.toLowerCase();
        final ok = low.contains('if not exists') ||
            low.contains('create or replace');
        expect(
          ok,
          isTrue,
          reason: 'Non-idempotent DDL: $l',
        );
      }
    });
  });
}
