// Test for FIX-3 (Sprint 0) — schema drift migration.
// -----------------------------------------------------------------------------
// Ref: docs/security/02-auth-authz.md H1 — four tables that Edge Functions
// reference (profiles, subscriptions, notifications, user_oauth_tokens) are
// not in any declared migration. This test verifies the additive migration
// file exists, is idempotent, and does not drop/alter anything.
//
// We cannot exercise live Postgres in Dart. The owner runs
// `supabase db push` after reviewing the migration against the production
// schema (see docs/sprint0/FINAL.md NOT DEPLOYED section).
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migrationFile = File(
    'supabase/migrations/20260422_schema_drift_fix.sql',
  );

  group('FIX-3 — schema drift migration', () {
    test('migration file exists', () {
      expect(migrationFile.existsSync(), isTrue);
    });

    final sql = migrationFile.existsSync()
        ? migrationFile.readAsStringSync()
        : '';

    test('declares profiles table with expected columns', () {
      expect(sql, contains('create table if not exists public.profiles'));
      // Columns that Edge Functions read/write:
      for (final col in [
        'id',
        'email',
        'full_name',
        'preferred_language',
        'is_pro',
        'stripe_customer_id',
        'subscription_tier',
        'subscription_expires_at',
        'subscription_status',
      ]) {
        expect(
          sql,
          contains(col),
          reason: 'profiles must declare column $col (used by Edge Functions)',
        );
      }
    });

    test('declares subscriptions table', () {
      expect(sql, contains('create table if not exists public.subscriptions'));
      expect(sql, contains('status'));
    });

    test('declares notifications table', () {
      expect(sql, contains('create table if not exists public.notifications'));
      expect(sql, contains('read'));
    });

    test('declares user_oauth_tokens table with provider and access_token', () {
      expect(
        sql,
        contains('create table if not exists public.user_oauth_tokens'),
      );
      expect(sql, contains('access_token'));
      expect(sql, contains('provider'));
    });

    test('enables RLS on every new table', () {
      // Tolerant of any amount of whitespace the formatter may introduce.
      final rlsPattern = RegExp(
        r'alter\s+table\s+public\.(\w+)\s+enable\s+row\s+level\s+security',
      );
      final tablesWithRls = rlsPattern
          .allMatches(sql)
          .map((m) => m.group(1))
          .toSet();
      for (final t in [
        'profiles',
        'subscriptions',
        'notifications',
        'user_oauth_tokens',
      ]) {
        expect(
          tablesWithRls,
          contains(t),
          reason:
              'RLS must be enabled on $t — default-off is the schema-drift '
              'security risk we are fixing',
        );
      }
    });

    test('policies use auth.uid() = id or user_id (never weaker)', () {
      // Pattern: every `using (...)` on the four new tables must be either
      // `auth.uid() = id` (profiles, FK to auth.users) or
      // `auth.uid() = user_id` (subscriptions, notifications, tokens).
      // Count matches — we should have multiple policies using auth.uid().
      final authUidMatches =
          RegExp(r'auth\.uid\(\)\s*=\s*(id|user_id)').allMatches(sql).length;
      expect(
        authUidMatches,
        greaterThanOrEqualTo(8),
        reason:
            'Expected at least 8 policy predicates scoped to '
            'auth.uid() = id|user_id across the 4 new tables',
      );
    });

    test('is additive only — no DROP, no ALTER COLUMN, no TRUNCATE', () {
      final lower = sql.toLowerCase();
      expect(lower, isNot(contains('drop table')));
      expect(lower, isNot(contains('drop policy')));
      expect(lower, isNot(contains('drop column')));
      expect(lower, isNot(contains('alter column')));
      expect(lower, isNot(contains('truncate')));
      // `alter table ... enable row level security` is allowed — that's the
      // only legitimate ALTER in an additive migration.
    });

    test('is idempotent — every create guarded by IF NOT EXISTS or pg_policies', () {
      // Strip SQL line comments so doc mentions of "CREATE TABLE" don't
      // trigger the idempotency check.
      final codeOnly = sql
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'--.*$'), ''))
          .join('\n');

      // Every `create policy` must be wrapped in a pg_policies check.
      final createPolicyCount =
          RegExp(r'create policy\s*"').allMatches(codeOnly).length;
      final pgPoliciesGuards =
          RegExp(r"pg_policies.*policyname\s*=\s*'").allMatches(codeOnly).length;
      expect(
        pgPoliciesGuards,
        greaterThanOrEqualTo(createPolicyCount),
        reason:
            'Found $createPolicyCount `create policy` statements but only '
            '$pgPoliciesGuards pg_policies guards — migration is NOT '
            'idempotent. Wrap each create policy in a DO block that checks '
            'pg_policies first.',
      );

      // Every `create table` must use IF NOT EXISTS.
      final createTableWithoutIfNotExists = RegExp(
        r'create\s+table\s+(?!if\s+not\s+exists)',
        caseSensitive: false,
      ).allMatches(codeOnly).length;
      expect(
        createTableWithoutIfNotExists,
        0,
        reason:
            'Every `create table` must use `if not exists` so re-running the '
            'migration is a no-op.',
      );
    });
  });

  group('FIX-3 — Edge Functions reference these tables', () {
    // Contract test: verify the Edge Functions still reference the tables
    // this migration declares. If someone renames the table in code, the
    // migration is dead weight.
    final edgeFiles = {
      'profiles': [
        'supabase/functions/check-ai-quota/index.ts',
        'supabase/functions/customer-portal/index.ts',
        'supabase/functions/deadline-reminder/index.ts',
        'supabase/functions/send-email/index.ts',
        'supabase/functions/stripe-webhook/index.ts',
      ],
      'subscriptions': [
        'supabase/functions/check-ai-quota/index.ts',
      ],
      'notifications': [
        'supabase/functions/deadline-reminder/index.ts',
      ],
      'user_oauth_tokens': [
        'supabase/functions/send-email/index.ts',
      ],
    };

    for (final entry in edgeFiles.entries) {
      final table = entry.key;
      for (final path in entry.value) {
        test('$table is referenced by $path', () {
          final file = File(path);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'Edge Function $path went missing — either restore it or '
                'drop $table from migration 20260422_schema_drift_fix.sql',
          );
          final src = file.readAsStringSync();
          expect(
            src,
            contains(".from(\"$table\")"),
            reason:
                'Edge Function $path no longer references $table. If the '
                'reference was removed intentionally, also drop the table '
                'from the drift-fix migration (avoid dead schema).',
          );
        });
      }
    }
  });
}
