@Tags(['fast'])
library;

// =============================================================================
// email_user_settings_migration_test.dart — D2 sibling contract test
// (Track E, 2026-05-07)
// =============================================================================
//
// Pins the SQL contract for `20260507140000_email_user_settings.sql`. Sibling
// of `email_inbox_migration_test.dart` — same pattern, narrower scope:
// the user_settings table backs the email-triage MemoryBlock (Rule 16.bis
// own_counsel_advisory + Rule 9 dead-address corrections).
//
// Spec ref:
//   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md §D2
//   business/email_agent_handoff_2026-05-06/06_SYSTEM_PROMPT_v1.1-final.md §3.7
//
// What this file covers:
//   1. Table created idempotently.
//   2. RLS enabled with three owner-only policies (select / insert / update).
//      No DELETE policy — settings rows are pruned via auth.users cascade.
//   3. updated_at trigger fires on UPDATE.
//   4. own_counsel_emails (text[]) and dead_address_corrections (jsonb)
//      columns present with sensible defaults.
//
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
  setUpAll(() => sql = _readMigration('email_user_settings'));

  // ---------------------------------------------------------------------------
  // 1. Table created idempotently.
  // ---------------------------------------------------------------------------
  group('email_user_settings migration — table', () {
    test('user_settings table is if-not-exists guarded', () {
      expect(
        sql,
        contains('create table if not exists public.user_settings'),
        reason:
            'Owner runs `supabase db push` multiple times during '
            'development; idempotency is the precondition.',
      );
    });

    test('user_id is primary key referencing auth.users(id) on delete cascade',
        () {
      expect(
        sql,
        contains('user_id                    uuid primary key'),
        reason: 'user_id is the natural PK — one settings row per user.',
      );
      expect(
        sql,
        contains('references auth.users(id) on delete cascade'),
        reason:
            'GDPR-aligned: account deletion drops settings row '
            'automatically; this also obviates the DELETE policy.',
      );
    });

    test('own_counsel_emails column present with empty default', () {
      expect(
        sql,
        contains(
          "own_counsel_emails         text[] not null default '{}'::text[]",
        ),
        reason:
            'own_counsel_emails drives Rule 16.bis own_counsel_advisory '
            'routing in the triage prompt. Default empty array — never '
            'null, the model would key off length and fail on null.',
      );
    });

    test('dead_address_corrections column present with empty jsonb default',
        () {
      expect(
        sql,
        contains(
          "dead_address_corrections   jsonb  not null default '{}'::jsonb",
        ),
        reason:
            'dead_address_corrections is the {dead: preferred} map for '
            'Rule 9 auto-send recipient gate. Default empty object.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. RLS — owner-only.
  // ---------------------------------------------------------------------------
  group('email_user_settings migration — RLS', () {
    test('RLS enabled', () {
      expect(
        sql,
        contains('alter table public.user_settings enable row level security'),
        reason:
            'Without RLS, anon and authenticated would read every user\'s '
            'own_counsel_emails — a privileged-individuals leak.',
      );
    });

    test('three owner-only policies (select / insert / update)', () {
      expect(sql, contains('user_settings_owner_select'));
      expect(sql, contains('user_settings_owner_insert'));
      expect(sql, contains('user_settings_owner_update'));
    });

    test('NO delete policy — cleanup happens via auth.users cascade', () {
      // Sanity: counts of `for delete to`, `for delete\nto`. Strip
      // comments first so a "no delete policy" comment doesn't false-trip.
      final stripped = sql
          .replaceAll(RegExp(r'--[^\n]*'), '')
          .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      expect(
        stripped.contains('for delete'),
        isFalse,
        reason:
            'No DELETE policy by design — user_settings is pruned by the '
            'auth.users(id) on delete cascade FK.',
      );
    });

    test('all three policies guard via auth.uid() = user_id', () {
      // Each policy is wrapped in a do$$ ... if not exists ... block.
      // Strict: at least 4 occurrences of the predicate (1 select using +
      // 1 insert with check + 1 update using + 1 update with check).
      final occurrences = 'auth.uid() = user_id'.allMatches(sql).length;
      expect(
        occurrences,
        greaterThanOrEqualTo(4),
        reason:
            'select.using + insert.with-check + update.using + '
            'update.with-check = 4 minimum predicate occurrences.',
      );
    });

    test('policies are pg_policies-guarded for re-run safety', () {
      // Each `do $$ ... if not exists (select 1 from pg_policies ...)`
      // block protects against "policy already exists" on re-run.
      expect(
        sql,
        contains('from pg_policies'),
        reason:
            'Without the pg_policies guard, the second `supabase db push` '
            'fails with "policy already exists".',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. updated_at trigger.
  // ---------------------------------------------------------------------------
  group('email_user_settings migration — updated_at trigger', () {
    test('touch_user_settings_updated_at function defined', () {
      expect(
        sql,
        contains(
          'create or replace function public.touch_user_settings_updated_at',
        ),
      );
    });

    test('user_settings_updated_at trigger fires before update', () {
      expect(
        sql,
        contains('drop trigger if exists user_settings_updated_at'),
        reason: 'Idempotent: drop-then-create on every db push.',
      );
      expect(
        sql,
        contains(
          'create trigger user_settings_updated_at\n'
          '    before update on public.user_settings',
        ),
      );
    });
  });
}
