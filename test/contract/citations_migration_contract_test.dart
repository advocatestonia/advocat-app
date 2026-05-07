@Tags(['fast'])
library;

// =============================================================================
// citations_migration_contract_test.dart — Phase 2 Pkg 2 (chat_message_citations)
// =============================================================================
//
// 2026-05-06 — Pkg 2 of the Citations API + Grounding pipeline. Pins the SQL
// contract for the chat_message_citations migration shipped by the backend
// agent in feat(citations) at 4168e96.
//
// Pattern matches phase2_pii_migration_contract_test.dart and
// law_chunks_jurisdiction_contract_test.dart — read the migration file from
// disk and grep load-bearing identifiers. We pin the structural invariants
// that, if silently changed, would break Flutter rendering, eval scoring,
// or the security model.
//
// What this file covers (the implementer didn't write a contract test):
//   1. Idempotency: every CREATE is `if not exists`-guarded. Required by
//      the team's reflex of "supabase db push" multiple times during
//      development.
//   2. RLS: read-own-only via auth.uid() = user_id. Critical — citations
//      can leak case-strategy fragments via the snippet column.
//   3. No INSERT/UPDATE/DELETE policy: the client cannot mint citations
//      directly. Only the proxy (service-role) writes rows — that's what
//      makes the "verified" badge meaningful.
//   4. FK cascade on chat_messages(id), users(id), cases(id) ON DELETE
//      CASCADE — citations follow their message lifecycle.
//   5. FK to law_chunks(id) is ON DELETE SET NULL — corpus refreshes (per
//      reference_scheduled_triggers.md) replace law_chunks rows; we keep
//      historical citation rows around with the snapshot fields.
//   6. Status CHECK constraint enumerates exactly the three documented
//      values ('verified', 'unverified', 'historical'). Adding a new value
//      requires a coordinated client change; renaming silently is a
//      regression.
//   7. occurrences > 0 — verifier never emits zero-occurrence rows.
//   8. message_citations(uuid) RPC: SECURITY DEFINER, explicit search_path
//      pin (defeats schema injection per CVE class for SECURITY DEFINER),
//      auth.uid() null guard, and owner re-check via chat_messages join
//      (NOT trusting the request payload).
//   9. PGRST schema-cache reload at end-of-file — without this, the new
//      table + RPC are unreachable until a manual postgrest restart
//      (memory: reference_pitfalls_chat_infra).
//  10. Indexes: (message_id) for chip-fetch path, (case_id, created_at)
//      for Pkg 4 case-density query, partial (status) where status<>verified
//      for eval/monitoring (the minority subset).
//
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locates the migration whose filename contains `name` and returns its
/// contents. Substring match so renames that adjust the date prefix or
/// numeric ordering still resolve.
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
  setUpAll(() => sql = _readMigration('message_citations'));

  // ---------------------------------------------------------------------------
  // Idempotency — every CREATE is if-not-exists guarded.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — idempotency', () {
    test('table CREATE is if-not-exists-guarded', () {
      expect(
        sql,
        contains('create table if not exists public.chat_message_citations'),
        reason:
            'Re-running the migration with `supabase db push` must not throw '
            'on the table already existing. Owner runs db push multiple times '
            'during development.',
      );
    });

    test('all three indexes are if-not-exists-guarded', () {
      // Three indexes per design §5: message_id, (case_id, created_at desc),
      // partial (status) where status<>verified.
      const wanted = [
        'create index if not exists chat_message_citations_message_idx',
        'create index if not exists chat_message_citations_case_idx',
        'create index if not exists chat_message_citations_status_idx',
      ];
      for (final w in wanted) {
        expect(
          sql,
          contains(w),
          reason: 'Index DDL must be re-runnable: $w',
        );
      }
    });

    test('RLS policy creation is wrapped in pg_policies guard', () {
      // The policy block uses do $$ ... if not exists in pg_policies ...
      // create policy ... end $$. Without this, second db push throws
      // "policy already exists".
      expect(
        sql,
        contains('from pg_policies'),
        reason:
            'Re-running migration must not throw on policy already existing. '
            'The do-block in 20260507050000_pii_redaction_map.sql sets the '
            'precedent — mirror it here.',
      );
      expect(
        sql,
        contains("policyname = 'chat_message_citations_select_own'"),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RLS — owner-only read, no other policy.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — RLS', () {
    test('RLS is enabled on the table', () {
      expect(
        sql,
        contains(
          'alter table public.chat_message_citations enable row level security',
        ),
        reason:
            'Without RLS enabled, anon and authenticated would read all '
            'citations rows. The snippet column carries case-strategy '
            'fragments — leak vector.',
      );
    });

    test('exactly ONE policy is declared (read-own-only)', () {
      // We allow `create policy` to appear inside one do-block (the guarded
      // declaration). Strict count: the literal substring must occur exactly
      // once.
      final occurrences = 'create policy'.allMatches(sql).length;
      expect(
        occurrences,
        1,
        reason:
            'Exactly one policy expected — chat_message_citations_select_own. '
            'INSERT/UPDATE/DELETE policies would let the client mint '
            'citations directly, breaking the "verified" badge meaning.',
      );
    });

    test('SELECT policy filters by auth.uid() = user_id', () {
      expect(
        sql,
        contains('using (auth.uid() = user_id)'),
        reason:
            'Owner check must match the public.chat_messages_select_own '
            'pattern. Anything else (e.g. checking case ownership) would '
            'risk shared-case scenarios in Pkg 4.',
      );
    });

    test('NO insert/update/delete policy exists', () {
      // The migration has a comment block explaining why the absence is
      // load-bearing. The compiled migration text must NOT contain any
      // `for insert`, `for update`, or `for delete` policy clauses on
      // chat_message_citations.
      // Strip comments first so the explanatory comment doesn't false-trip.
      final stripped = sql
          .replaceAll(RegExp(r'--[^\n]*', multiLine: true), '')
          .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      expect(
        stripped.contains('for insert'),
        isFalse,
        reason: 'No INSERT policy — proxy writes via service_role.',
      );
      expect(
        stripped.contains('for update'),
        isFalse,
        reason:
            'No UPDATE policy — citations are immutable per turn.',
      );
      expect(
        stripped.contains('for delete'),
        isFalse,
        reason:
            'No DELETE policy — cleanup happens via FK cascade only.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // FK cascades — load-bearing for cleanup behaviour.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — FK behaviour', () {
    test('message_id FK cascades on chat_messages delete', () {
      expect(
        sql,
        contains(
          'message_id      uuid not null references public.chat_messages(id) on delete cascade',
        ),
        reason:
            'Deleting a chat message must drop its citations. Otherwise '
            'orphan rows accumulate forever.',
      );
    });

    test('user_id FK cascades on users delete', () {
      expect(
        sql,
        contains(
          'user_id         uuid not null references public.users(id) on delete cascade',
        ),
        reason:
            'GDPR-aligned: account deletion must drop citation rows '
            'tagged with the user_id.',
      );
    });

    test('case_id FK cascades on cases delete', () {
      expect(
        sql,
        contains(
          'case_id         uuid not null references public.cases(id) on delete cascade',
        ),
        reason:
            'Pkg 4 case-density signal queries by case_id — case deletion '
            'must drop citations together.',
      );
    });

    test('chunk_id FK is on delete set null (NOT cascade)', () {
      // Corpus refreshes (monthly cron, reference_scheduled_triggers.md)
      // replace law_chunks rows wholesale. We do NOT want historical
      // citations to disappear when the chunk row is replaced — the
      // snapshot fields (act_slug, paragraph, snippet, source_url, in_force)
      // preserve the citation. on delete set null is the design call (§5).
      expect(
        sql,
        contains(
          'chunk_id        text references public.law_chunks(id) on delete set null',
        ),
        reason:
            'Corpus refresh replaces law_chunks rows. CASCADE here would '
            'wipe historical citations — the snapshot columns exist '
            'precisely so we can keep the citation row. Per design §5.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // CHECK constraints — wire contract for client + eval suite.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — CHECK constraints', () {
    test('status CHECK enumerates exactly verified/unverified/historical', () {
      // These three literals are also enumerated in citation_grounder.ts
      // (Citation.status type) and rendered as chip color in Flutter
      // (green/red/amber). Adding/renaming requires a coordinated change.
      expect(
        sql,
        contains(
          "status          text not null check (status in ('verified', 'unverified', 'historical'))",
        ),
        reason:
            'Status enum is the wire contract — Pkg 2 design §3 response '
            'shape locks these three values. Drift between this CHECK and '
            'the verifier output would cause INSERT failures.',
      );
    });

    test('occurrences must be > 0', () {
      // Verifier increments from 1; should never emit zero. Defence-in-
      // depth so a future bug doesn't silently insert 0-row citations.
      expect(
        sql,
        contains('occurrences     int not null default 1 check (occurrences > 0)'),
        reason:
            'occurrences > 0 — the verifier always increments from 1; '
            'zero would mean a marker that never appeared in the reply.',
      );
    });

    test('act_slug and paragraph are NOT NULL (snapshot integrity)', () {
      // The snapshot columns let us preserve the citation when law_chunks
      // is wiped on corpus refresh. act_slug + paragraph are the join key —
      // letting either go null would leave us unable to re-link the
      // citation when the corpus comes back.
      expect(sql, contains('act_slug        text not null'));
      expect(sql, contains('paragraph       text not null'));
    });
  });

  // ---------------------------------------------------------------------------
  // message_citations RPC — security & ownership.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — message_citations RPC', () {
    test('RPC is declared with create-or-replace', () {
      expect(
        sql,
        contains(
          'create or replace function public.message_citations(p_message_id uuid)',
        ),
      );
    });

    test('RPC is SECURITY DEFINER (must bypass RLS)', () {
      expect(sql, contains('security definer'));
    });

    test('RPC pins explicit search_path (injection guard)', () {
      // Per phase2_pii_migration_contract_test.dart G4 — SECURITY DEFINER
      // with dynamic search_path is the classic privilege-escalation
      // vector. Pin search_path at declaration time.
      expect(
        sql,
        contains('set search_path = public'),
        reason:
            'message_citations must pin search_path to defeat schema '
            'injection (CVE class for SECURITY DEFINER functions). Same '
            'standard as read_sensitive_doc, unredact, etc.',
      );
    });

    test('RPC null-guards auth.uid() before doing anything', () {
      expect(sql, contains('if auth.uid() is null then'));
      expect(sql, contains("raise exception 'unauthorized'"));
    });

    test('RPC verifies ownership via chat_messages join (not request payload)',
        () {
      // The owner check resolves user_id from public.chat_messages, NOT
      // from anything the caller passes. This is the same pattern as
      // unredact reading from public.user_cases.
      expect(
        sql,
        contains('from public.chat_messages'),
        reason:
            'Owner check must read user_id from the chat_messages row, '
            'not from a passed-in payload. Mirrors unredact / '
            'read_sensitive_doc patterns.',
      );
      expect(sql, contains('where id = p_message_id'));
    });

    test('RPC raises forbidden on non-owner access', () {
      expect(sql, contains("raise exception 'forbidden'"));
      // The owner mismatch check.
      expect(sql, contains('v_owner <> auth.uid()'));
    });

    test('RPC owner pinned to postgres (project convention B5)', () {
      // SECURITY DEFINER must run as postgres so it can bypass RLS.
      // Project convention from migration 20260507_05 onward.
      expect(
        sql,
        contains(
          'alter function public.message_citations(uuid) owner to postgres',
        ),
        reason:
            'B5 project convention — pin owner on every SECURITY DEFINER '
            'RPC so it bypasses RLS. Without this, a re-run from a non-'
            'postgres role would create a function that fails at runtime.',
      );
    });

    test('RPC is granted to authenticated only (not anon)', () {
      expect(
        sql,
        contains(
          'grant execute on function public.message_citations(uuid) to authenticated',
        ),
      );
      // Anon must NOT be granted — would let unauth callers fish for
      // message_id existence via the unauthorized vs forbidden response.
      expect(
        sql.contains(
          'grant execute on function public.message_citations(uuid) to anon',
        ),
        isFalse,
        reason: 'message_citations must not be reachable by anon role.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PGRST schema cache reload — without it, the RPC + table are invisible.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — PGRST cache reload', () {
    test("notify pgrst, 'reload schema' is the last meaningful line", () {
      // Per memory: reference_pitfalls_chat_infra. Without this, calling
      // the new RPC returns 404 until a manual restart. The convention is
      // EOF.
      expect(
        sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
        isTrue,
        reason:
            'Migration must end with PGRST cache reload — otherwise the '
            'new table and message_citations RPC are unreachable until a '
            'PostgREST restart.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Indexes — query path coverage.
  // ---------------------------------------------------------------------------
  group('chat_message_citations migration — indexes', () {
    test('message_idx covers chip-fetch path', () {
      // Flutter chip render: SELECT * WHERE message_id = $1. Without an
      // index, hot path goes seq-scan on every message render.
      expect(
        sql,
        contains('on public.chat_message_citations (message_id)'),
      );
    });

    test('case_idx covers Pkg 4 case-density query', () {
      // Pkg 4 (Case Workspace) renders citation density per case. Sort by
      // created_at desc so newest citations show up first.
      expect(
        sql,
        contains(
          'on public.chat_message_citations (case_id, created_at desc)',
        ),
      );
    });

    test('status_idx is partial (where status <> verified)', () {
      // Eval/monitoring queries filter for unverified+historical — the
      // minority. Partial index keeps it small.
      expect(
        sql,
        contains(
          'on public.chat_message_citations (status) where status <> ',
        ),
      );
    });
  });
}
