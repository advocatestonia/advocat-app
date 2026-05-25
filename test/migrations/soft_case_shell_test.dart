@Tags(['fast'])
library;

// =============================================================================
// soft_case_shell_test.dart — schema contract for migration 20260525220000
// =============================================================================
//
// P0 fix: the PdfParserService used to set documentId='' whenever
// activeCaseId was null, which meant the pdf-parser edge fn skipped its
// case_documents insert and the deadline-extractor never fired. A first
// upload by an authenticated user thus silently lost the 10-day appeal
// deadline.
//
// This static-text contract pins the soft-case-shell migration so the
// fix can't silently regress. We assert:
//   1. The migration file exists at the expected path.
//   2. It adds the `is_soft_shell BOOLEAN NOT NULL DEFAULT false` column
//      to public.user_cases.
//   3. It defines the `ensure_soft_case_for_user(p_user_id uuid)` RPC.
//   4. The RPC is SECURITY DEFINER (so anon-but-authenticated callers
//      can persist a row even though they bypass the policy-write path
//      for inserts).
//   5. The RPC reuses an existing shell instead of inserting a new row
//      (idempotency — five calls return the same id).
//   6. `is_soft_shell = true` is set on shell inserts.
//   7. RLS is enforced via `auth.uid()` ownership check inside the RPC
//      (no cross-user shell creation).
//   8. Execute grant to `authenticated`.
//   9. PGRST schema reload notification so the RPC is reachable.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('soft-case shell migration (20260525220000)', () {
    final migrationFile = File(
      'supabase/migrations/20260525220000_soft_case_shell.sql',
    );

    late String sql;
    late String sqlLower;

    setUpAll(() {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Migration file missing: ${migrationFile.path}. Restore the '
            'file — pdf_parser_service.dart depends on this RPC for the '
            'first-touch upload deadline fix (P0).',
      );
      sql = migrationFile.readAsStringSync();
      sqlLower = sql.toLowerCase();
    });

    test('adds is_soft_shell BOOLEAN NOT NULL DEFAULT false on user_cases',
        () {
      expect(
        sqlLower,
        contains('add column if not exists is_soft_shell'),
        reason:
            'is_soft_shell column is what the UI uses to render the '
            '"rename your Untitled case" banner — without it the banner '
            'cannot distinguish shells from real cases.',
      );
      // Strict shape — boolean, not null, default false.
      expect(sqlLower, contains('boolean'));
      expect(sqlLower, contains('not null'));
      expect(sqlLower, contains('default false'));
    });

    test('defines ensure_soft_case_for_user(p_user_id uuid) returning uuid',
        () {
      expect(
        sqlLower,
        contains('function public.ensure_soft_case_for_user(p_user_id uuid)'),
        reason:
            'RPC signature is the public contract that pdf_parser_service '
            'and any future first-touch consumer rely on. Renaming requires '
            'a coordinated migration.',
      );
      expect(sqlLower, contains('returns uuid'));
    });

    test('RPC is SECURITY DEFINER', () {
      expect(
        sqlLower,
        contains('security definer'),
        reason:
            'SECURITY DEFINER lets the RPC bypass per-row RLS so a fresh '
            'authenticated user (no prior cases) can still get a shell. '
            'Cross-user creation is blocked separately via auth.uid() check.',
      );
    });

    test('RPC is idempotent — reuses existing shell before inserting', () {
      // We check for the SELECT-then-INSERT shape by name: the function
      // must SELECT the user_cases row WHERE is_soft_shell = true first,
      // and only INSERT when none found. The exact SQL shape is enforced
      // loosely (any SELECT that filters on is_soft_shell + same-user).
      expect(sqlLower, contains('select id'));
      expect(sqlLower, contains('is_soft_shell = true'));
      // Followed by a conditional insert path.
      expect(sqlLower, contains('insert into public.user_cases'));
      expect(
        sqlLower,
        contains('if v_case_id is not null then'),
        reason:
            'Idempotency: when an existing shell is found we MUST return '
            'early. Five consecutive calls must yield the same case_id.',
      );
    });

    test('RPC sets is_soft_shell=true on the insert path', () {
      // Pin the boolean true literal on the insert side.
      final hasInsertWithTrue = RegExp(
        r'insert\s+into\s+public\.user_cases[\s\S]*?values\s*\([\s\S]*?true',
        caseSensitive: false,
      ).hasMatch(sql);
      expect(
        hasInsertWithTrue,
        isTrue,
        reason:
            'The INSERT must set is_soft_shell=true. Otherwise the banner '
            'logic on the client would never trigger and the user would '
            'never be prompted to rename their auto-created case.',
      );
    });

    test('RPC blocks cross-user shell creation via auth.uid() check', () {
      expect(
        sqlLower,
        contains('auth.uid()'),
        reason:
            'Defence in depth: even though SECURITY DEFINER skips RLS, the '
            'RPC body must verify the caller owns the requested p_user_id. '
            'Otherwise any authenticated user could spawn shells on '
            'arbitrary accounts.',
      );
      expect(sqlLower, contains('p_user_id'));
    });

    test('grants execute to authenticated role', () {
      expect(
        sqlLower,
        contains(
          'grant execute on function public.ensure_soft_case_for_user(uuid)',
        ),
        reason:
            'Without GRANT EXECUTE, PostgREST returns 403 for the user '
            'JWT and the client-side fallback silently drops the upload '
            'to the legacy null-case path.',
      );
      expect(sqlLower, contains('authenticated'));
    });

    test('notifies pgrst to reload schema cache', () {
      expect(
        sqlLower,
        contains("notify pgrst, 'reload schema'"),
        reason:
            'Without the cache reload, PostgREST 404s on the new RPC '
            'until the next pod recycle (see reference_pitfalls_chat_infra).',
      );
    });

    test('uses `if not exists` for column and `create or replace` for fn',
        () {
      // Idempotency contract for re-running `supabase db push`.
      expect(sqlLower, contains('add column if not exists'));
      expect(sqlLower, contains('create or replace function'));
    });

    test('default jurisdiction/language are safe non-null fallbacks', () {
      // The user_cases NOT NULL fields (jurisdiction, language) must be
      // populated by the shell insert; the rename screen lets the user
      // change them later.
      expect(sqlLower, contains("'ee'"));
      expect(sqlLower, contains("'en'"));
    });

    test('partial index on (user_id) WHERE is_soft_shell = true exists', () {
      // The SELECT inside the RPC scans user_cases on each call; the
      // partial index keeps that scan O(1) per user even at scale.
      expect(
        sqlLower,
        contains('create index if not exists user_cases_soft_shell_idx'),
      );
      expect(sqlLower, contains('where is_soft_shell = true'));
    });
  });
}
