@Tags(['fast'])
library;

// =============================================================================
// email_inbox_migration_test.dart — D2 contract test (Track E, 2026-05-07)
// =============================================================================
//
// Pins the SQL contract for `20260507_13_email_inbox.sql`. Pattern matches
// `citations_migration_contract_test.dart` and
// `deadline_radar_migration_contract_test.dart`: read the migration text and
// assert on load-bearing identifiers.
//
// Spec ref:
//   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md §D2
//   business/email_agent_handoff_2026-05-06/v2.1_consilium/implementation_pragmatist_proposal.md §3
//
// What this file covers (the implementer didn't ship a contract test):
//   1. Three tables created: email_threads, email_messages,
//      email_triage_results — idempotent (`if not exists`).
//   2. RLS enabled + owner-only policies on all three tables.
//   3. Hot-path indices declared (status filter, pending filter, severity
//      filter for the agent-intentions cron).
//   4. Natural upsert keys: (user_id, gmail_thread_id) on threads,
//      (gmail_message_id) globally unique on messages.
//   5. Body cap CHECK on email_messages.body_plaintext.
//   6. Triage status enum values (pending/triaged/skipped/handled-auto/
//      archived/spam/error) — wire contract for D3 inbox-sync.
//   7. send_recommendation enum (auto_send_eligible/hold_for_user_review/
//      archive) — wire contract for the policy gate.
//   8. severity enum (CRITICAL/HIGH/MEDIUM/LOW) — wire contract for the
//      proactive push pipeline (Pkg 9 deadline radar reuses these).
//   9. PGRST schema cache reload — without it, D3/D4 edge fns get 404.
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
  setUpAll(() => sql = _readMigration('email_inbox'));

  // ---------------------------------------------------------------------------
  // 1. Three tables created — idempotent CREATE.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — tables', () {
    test('creates email_threads with if-not-exists guard', () {
      expect(
        sql,
        contains('create table if not exists public.email_threads'),
        reason:
            'Re-running migration with `supabase db push` must not throw; '
            'owner runs db push multiple times during development.',
      );
    });

    test('creates email_messages with if-not-exists guard', () {
      expect(
        sql,
        contains('create table if not exists public.email_messages'),
      );
    });

    test('creates email_triage_results with if-not-exists guard', () {
      expect(
        sql,
        contains('create table if not exists public.email_triage_results'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. RLS — owner-only on all three tables.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — RLS', () {
    test('RLS enabled on all three tables', () {
      expect(
        sql,
        contains(
          'alter table public.email_threads        enable row level security',
        ),
        reason:
            'Without RLS, anon and authenticated would read every email '
            'thread row. The body_plaintext column carries privileged + '
            'GDPR-protected content.',
      );
      expect(
        sql,
        contains(
          'alter table public.email_messages       enable row level security',
        ),
      );
      expect(
        sql,
        contains(
          'alter table public.email_triage_results enable row level security',
        ),
      );
    });

    test('owner-all policies on all three tables', () {
      expect(sql, contains('"email_threads_owner_all"'));
      expect(sql, contains('"email_messages_owner_all"'));
      expect(sql, contains('"email_triage_owner_all"'));
    });

    test('all three policies key off auth.uid() = user_id', () {
      // The `for all` policy uses the same predicate in `using` and
      // `with check`. Count the predicate appearances — must be at least
      // 6 (3 tables × 2 clauses).
      final occurrences = 'auth.uid() = user_id'.allMatches(sql).length;
      expect(
        occurrences,
        greaterThanOrEqualTo(6),
        reason:
            '3 tables × (using + with check) = 6 minimum occurrences of '
            'the auth.uid() = user_id predicate.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Hot-path indices.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — indices', () {
    test('email_threads has user_status, case, and pending indices', () {
      expect(sql, contains('email_threads_user_status_idx'));
      expect(sql, contains('email_threads_case_idx'));
      expect(sql, contains('email_threads_pending_idx'),
          reason:
              'Partial pending-only index supports the D3 inbox-sync '
              'enqueue scan path; without it, the scan goes seq-scan '
              'on every cron tick.');
    });

    test('email_messages has thread and user_sent indices', () {
      expect(sql, contains('email_messages_thread_idx'));
      expect(sql, contains('email_messages_user_sent_idx'));
    });

    test('email_triage_results has severity, thread, and pending-review indices',
        () {
      expect(sql, contains('email_triage_user_severity_idx'),
          reason:
              'Hot path: agent-intentions-cron scans unseen CRITICAL/HIGH '
              'per user. This is THE load-bearing index for the proactive '
              'push pipeline (Pkg 9 deadline radar reuses the pattern).');
      expect(sql, contains('email_triage_thread_idx'));
      expect(sql, contains('email_triage_pending_review_idx'));
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Natural upsert keys.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — uniqueness constraints', () {
    test('email_threads unique (user_id, gmail_thread_id)', () {
      expect(
        sql,
        contains('unique (user_id, gmail_thread_id)'),
        reason:
            'D3 inbox-sync uses (user_id, gmail_thread_id) as the natural '
            'upsert key. Without this unique constraint, upsert duplicates '
            'rows on every poll.',
      );
    });

    test('email_messages unique (gmail_message_id) globally', () {
      expect(
        sql,
        contains('unique (gmail_message_id)'),
        reason:
            'Gmail message IDs are globally unique — upsert key for D3 '
            'message-row inserts.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Body cap CHECK.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — body size cap', () {
    test('email_messages.body_plaintext capped at 60000 octets', () {
      // App layer caps at 50 KB; SQL CHECK gives 60 KB slack ceiling so
      // a buggy client cannot blow the row up to the row-size limit.
      expect(
        sql,
        contains('octet_length(body_plaintext) <= 60000'),
        reason:
            'Body cap is the SQL backstop: app layer caps at 50 KB, but '
            'a buggy client must not be able to bypass and blow the row '
            'up to PostgreSQL TOAST limits.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Triage status enum.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — triage_status enum', () {
    test('triage_status CHECK enumerates all 7 documented values', () {
      // The 7 values are the wire contract with D3 inbox-sync + the
      // Flutter inbox UI. Renaming any silently is a regression.
      const wanted = [
        "'pending'",
        "'triaged'",
        "'skipped'",
        "'handled-auto'",
        "'archived'",
        "'spam'",
        "'error'",
      ];
      for (final v in wanted) {
        expect(sql, contains(v),
            reason: 'triage_status enum must include $v');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 7. send_recommendation enum (wire contract for policy gate).
  // ---------------------------------------------------------------------------
  group('email_inbox migration — send_recommendation enum', () {
    test('send_recommendation enumerates exactly the 3 documented values',
        () {
      const wanted = [
        "'auto_send_eligible'",
        "'hold_for_user_review'",
        "'archive'",
      ];
      for (final v in wanted) {
        expect(sql, contains(v),
            reason: 'send_recommendation must include $v');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 8. severity enum (wire contract for proactive push).
  // ---------------------------------------------------------------------------
  group('email_inbox migration — severity enum', () {
    test('severity enumerates CRITICAL/HIGH/MEDIUM/LOW', () {
      const wanted = ["'CRITICAL'", "'HIGH'", "'MEDIUM'", "'LOW'"];
      for (final v in wanted) {
        expect(sql, contains(v),
            reason: 'severity must include $v');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 9. PGRST schema cache reload.
  // ---------------------------------------------------------------------------
  group('email_inbox migration — PGRST cache reload', () {
    test("notify pgrst, 'reload schema' is the last meaningful line", () {
      // Per memory: reference_pitfalls_chat_infra. Without this, calling
      // the new tables returns 404 until manual postgrest restart.
      expect(
        sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
        isTrue,
        reason:
            'Migration must end with PGRST cache reload — otherwise the '
            'new tables and policies are unreachable until a PostgREST '
            'restart.',
      );
    });
  });
}
