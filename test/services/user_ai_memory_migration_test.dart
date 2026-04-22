// Source-contract tests for the ADR-001 Tier 1 user_ai_memory migration.
// -----------------------------------------------------------------------------
// Ref: supabase/migrations/20260423010000_user_ai_memory.sql
//      docs/learning/ADR-001-three-tier-learning.md
//
// Pattern borrowed from test/services/gdpr_delete_rls_test.dart — we can't
// spin up live Postgres in Dart, so instead we assert that the migration
// file exists at the expected path and declares the columns, constraints,
// policies, and idempotency guards required by the design.
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migrationFile = File(
    'supabase/migrations/20260423010000_user_ai_memory.sql',
  );

  group('ADR-001 Tier 1 — user_ai_memory migration file', () {
    test('migration file exists at expected path', () {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Expected supabase/migrations/20260423010000_user_ai_memory.sql '
            'to exist. Timestamp 20260423 chosen so Supabase applies it '
            'after the 20260422 Sprint 0 series.',
      );
    });

    final sql = migrationFile.existsSync()
        ? migrationFile.readAsStringSync()
        : '';

    test('creates public.user_ai_memory table', () {
      expect(
        sql,
        contains(RegExp(
          r'create table if not exists\s+public\.user_ai_memory',
          caseSensitive: false,
        )),
      );
    });

    test('user_id is a FK to auth.users with ON DELETE CASCADE', () {
      // GDPR: deleting a user must vaporise their AI memory.
      expect(
        sql,
        contains(RegExp(
          r'user_id\s+uuid\s+not\s+null\s+references\s+auth\.users\(id\)\s+on\s+delete\s+cascade',
          caseSensitive: false,
        )),
      );
    });

    test('declares all required columns', () {
      for (final col in const [
        'id uuid primary key',
        'key text not null',
        'value jsonb not null',
        'confidence real not null',
        'source_session_id uuid',
        'created_at timestamptz not null',
        'last_reinforced_at timestamptz not null',
        'expires_at timestamptz',
      ]) {
        expect(
          sql.toLowerCase(),
          contains(col.toLowerCase()),
          reason: 'Missing column declaration: $col',
        );
      }
    });

    test('confidence has CHECK constraint 0..1', () {
      expect(
        sql,
        contains(RegExp(
          r'check\s*\(\s*confidence\s*>=\s*0\s+and\s+confidence\s*<=\s*1\s*\)',
          caseSensitive: false,
        )),
      );
    });

    test('unique index on (user_id, key, value->>text)', () {
      expect(sql, contains('user_ai_memory_user_key_text_uniq'));
      expect(
        sql,
        contains(RegExp(r"value\s*->\s*>\s*'text'")),
        reason:
            'Dedupe key must be the JSONB text attribute so re-extracting '
            'the same fact upserts rather than duplicates.',
      );
    });

    test('hot-path indexes on (user_id, key) and (user_id, confidence desc)', () {
      expect(sql, contains('idx_user_ai_memory_user_key'));
      expect(sql, contains('idx_user_ai_memory_user_confidence'));
      expect(
        sql,
        contains(RegExp(r'confidence\s+desc', caseSensitive: false)),
      );
    });

    test('RLS is enabled on the table', () {
      expect(
        sql,
        contains(RegExp(
          r'alter\s+table\s+public\.user_ai_memory\s+enable\s+row\s+level\s+security',
          caseSensitive: false,
        )),
      );
    });

    test('declares SELECT-own RLS policy scoped to auth.uid()', () {
      expect(sql, contains('user_ai_memory_select_own'));
      expect(
        sql,
        contains(RegExp(r'auth\.uid\(\)\s*=\s*user_id')),
        reason:
            'SELECT policy must scope to auth.uid() = user_id — no weaker '
            'filter allowed (cross-user reads must be impossible).',
      );
    });

    test('declares DELETE-own RLS policy (GDPR Art. 17)', () {
      expect(sql, contains('user_ai_memory_delete_own'));
      // Must reference the delete action explicitly.
      expect(
        sql,
        contains(RegExp(r'for\s+delete', caseSensitive: false)),
      );
    });

    test('NO insert/update policy for regular users', () {
      // Writes go through the Edge Function (service role). Users must
      // not be able to spoof memory for themselves.
      expect(
        sql.toLowerCase(),
        isNot(contains(RegExp(r'for\s+insert'))),
        reason:
            'user_ai_memory must not expose INSERT via RLS. Writes happen '
            'only through the extract-memory Edge Function using the '
            'service role.',
      );
      expect(
        sql.toLowerCase(),
        isNot(contains(RegExp(r'for\s+update'))),
        reason:
            'user_ai_memory must not expose UPDATE via RLS. Reinforcement '
            'is handled by the Edge Function upsert path.',
      );
    });

    test('migration is idempotent (all DDL guarded)', () {
      final createPolicyCount =
          RegExp(r'create\s+policy', caseSensitive: false).allMatches(sql).length;
      final policyGuardCount =
          RegExp(r"policyname\s*=\s*'").allMatches(sql).length;
      expect(
        policyGuardCount,
        greaterThanOrEqualTo(createPolicyCount),
        reason:
            'Every `create policy` must be preceded by a `pg_policies` '
            'existence guard. Found $createPolicyCount create statements but '
            'only $policyGuardCount guards.',
      );
      // Table and indexes use IF NOT EXISTS / pg_indexes guard.
      expect(
        sql,
        contains(RegExp(r'create\s+table\s+if\s+not\s+exists', caseSensitive: false)),
      );
      expect(
        sql,
        contains(RegExp(r'create\s+index\s+if\s+not\s+exists', caseSensitive: false)),
      );
    });

    test('no destructive DDL (additive only)', () {
      final lower = sql.toLowerCase();
      expect(lower, isNot(contains('drop table')));
      expect(lower, isNot(contains('drop policy')));
      expect(lower, isNot(contains('drop index')));
      expect(
        lower,
        isNot(contains('truncate')),
        reason: 'Tier 1 migration must be purely additive.',
      );
    });

    test('key vocabulary is documented in SQL comments', () {
      // The set of allowed keys is not enforced as a DB CHECK (JSON schema
      // is enforced in the Edge Function), but must be documented in the
      // SQL file so future readers know the contract.
      for (final key in const [
        'tone',
        'emotional_state',
        'case_focus',
        'known_party',
        'deadline',
        'user_goal',
        'preference',
        'background',
        'discussed_topic',
      ]) {
        expect(
          sql,
          contains(key),
          reason:
              'Key "$key" must appear in the SQL doc comment so the '
              'bounded vocabulary is discoverable from the migration alone.',
        );
      }
    });
  });
}
