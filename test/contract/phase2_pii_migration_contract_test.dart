@Tags(['fast'])
library;

// =============================================================================
// phase2_pii_migration_contract_test.dart — Phase 2 PII migrations contract
// =============================================================================
//
// 2026-05-07 — Pkg 0 / Track B-2. Pins the SQL contract for the six Phase 2
// migrations that introduce GDPR-aligned PII handling:
//
//   * 20260507010000_sensitive_schema.sql            — encrypted parsed_text + RPC
//   * 20260507020000_audit_log.sql                   — append-only audit trail
//   * 20260507030000_consent_log.sql                 — Art. 9/10 consent ledger
//   * 20260507040000_attorney_privilege_acceptance.sql — onboarding disclaimer
//   * 20260507050000_pii_redaction_map.sql           — per-case PII tokens
//   * (06/07) law_chunks_jurisdiction + lookup_statute — pinned separately
//
// Without these tests, an accidental rename, dropped policy, or reshuffled
// audit-insert order would only show up as a 4xx in production. Pattern
// follows law_chunks_jurisdiction_contract_test.dart and
// case_memory_migration_test.dart — read the migration file from disk and
// grep load-bearing identifiers.
//
// These tests cover security review gates G1..G5 (G6 lives in the
// system_prompts UPL test, G7 lives in the assistant_tools input
// validation test).
//
// Some "post-fix" assertions (B3 / B4 / B6 from the security consilium) are
// gated behind boolean flags; flip them to false once the fix lands.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Flip to `false` once the consent_log immutability trigger lands (B6).
const bool _awaitsFixB6 = true;

/// Flip to `false` once read_sensitive_doc moves the audit insert to AFTER
/// the row-existence check (B3).
const bool _awaitsFixB3 = true;

/// Flip to `false` once unredact moves the audit insert to AFTER the
/// successful plaintext lookup (B4).
const bool _awaitsFixB4 = true;

/// Locates the migration whose filename contains `name` and returns its
/// contents. We match by substring rather than exact name so renames that
/// only adjust the date prefix or numeric ordering still resolve.
///
/// Filenames are normalised by stripping the `YYYYMMDDHHMMSS_` timestamp
/// prefix before substring-matching, and the basename must START with
/// `name` (after the prefix). This prevents `audit_log` from matching
/// sibling files like `backup_audit_log.sql` whose contents have a
/// different SQL contract.
String _readMigration(String name) {
  final dir = Directory('supabase/migrations');
  if (!dir.existsSync()) {
    throw StateError(
      'Migrations directory not found at ${dir.absolute.path}. '
      'flutter test must run from the package root.',
    );
  }
  // Strip the leading `YYYYMMDDHHMMSS_` (or `YYYYMMDD_NN_`) prefix so the
  // match operates on the semantic part of the filename only.
  final timestampPrefix = RegExp(r'^\d{8,14}(?:_\d+)?_');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) {
        final basename = f.uri.pathSegments.last;
        final stripped = basename.replaceFirst(timestampPrefix, '');
        return stripped.startsWith(name);
      })
      .toList();
  if (files.isEmpty) {
    throw StateError('Migration matching "$name" not found in ${dir.path}');
  }
  // Take the most recent file by name (lexicographic ordering matches the
  // YYYYMMDD prefix convention).
  files.sort((a, b) => a.path.compareTo(b.path));
  return files.last.readAsStringSync();
}

void main() {
  // -------------------------------------------------------------------------
  // G1 — consent_log
  // -------------------------------------------------------------------------
  group('Phase 2 PII migrations contract — consent_log (G1)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('consent_log'));

    test('grant_consent RPC declared', () {
      expect(
        sql,
        contains('create or replace function public.grant_consent'),
        reason: 'consent_log migration must declare grant_consent RPC',
      );
    });

    test('check_consent RPC declared', () {
      expect(
        sql,
        contains('create or replace function public.check_consent'),
        reason: 'consent_log migration must declare check_consent RPC',
      );
    });

    test('consent_type CHECK enumerates all 5 values', () {
      // These five strings ARE the wire contract — check_consent callers
      // pass them as text[]. Adding/removing requires a coordinated client
      // change; renaming silently is a regression.
      expect(sql, contains("'art9_health'"));
      expect(sql, contains("'art10_criminal'"));
      expect(sql, contains("'us_transfer'"));
      expect(sql, contains("'cookies'"));
      expect(sql, contains("'marketing'"));
    });

    test('client INSERT is sealed (RPC-only path)', () {
      // The "no client insert" policy with check (false) is what forces
      // every consent insert through the SECURITY DEFINER RPC.
      expect(
        sql,
        contains('for insert with check (false)'),
        reason:
            'consent_log must reject direct client INSERTs — only the '
            'grant_consent RPC may write rows',
      );
    });

    test(
      'immutability trigger present (post-fix B6)',
      () {
        // The B6 fix prevents UPDATEs from changing anything other than
        // revoked_at. Today the WITH CHECK clause guards this at the
        // policy level; the trigger is a defence-in-depth layer for
        // service_role writes that bypass RLS.
        expect(
          sql,
          anyOf(
            contains('consent_log_immutability'),
            contains('before update on public.consent_log'),
          ),
          reason: 'B6 fix: trigger must enforce immutability for non-revoke '
              'updates (defence-in-depth beyond the RLS WITH CHECK)',
        );
      },
      skip: _awaitsFixB6
          ? 'awaits B6 immutability trigger — flip _awaitsFixB6 to false '
              'once the trigger lands'
          : null,
    );

    test('PGRST schema-cache reload at end-of-file', () {
      // notify pgrst, 'reload schema'; MUST be the last meaningful line —
      // see memory: reference_pitfalls_chat_infra. Without this, the new
      // RPCs are unreachable until a manual restart.
      expect(
        sql.trimRight().endsWith("notify pgrst, 'reload schema';"),
        isTrue,
        reason: 'consent_log migration must end with PGRST cache reload',
      );
    });
  });

  // -------------------------------------------------------------------------
  // G2 — attorney_privilege_acceptance
  // -------------------------------------------------------------------------
  group(
    'Phase 2 PII migrations contract — attorney_privilege_acceptance (G2)',
    () {
      late String sql;
      setUpAll(() => sql = _readMigration('attorney_privilege'));

      test('user_id is the primary key (one row per user)', () {
        expect(
          sql,
          contains('user_id         uuid primary key'),
          reason:
              'one acceptance row per user — no history table, no multiple '
              'acceptances per user',
        );
      });

      test('idempotent INSERT via on conflict do nothing', () {
        expect(
          sql,
          contains('on conflict (user_id) do nothing'),
          reason: 'accept_privilege_disclaimer must be safely re-callable',
        );
      });

      test('no UPDATE policy — record is append-only', () {
        // RLS with no `for update` policy = updates denied. The contract
        // is that the disclaimer text the user accepted is preserved
        // verbatim for the lifetime of the record.
        expect(
          sql.contains('for update'),
          isFalse,
          reason: 'attorney_privilege_acceptance must have no UPDATE policy',
        );
      });

      test('no DELETE policy — record is permanent', () {
        // Acceptance survives even account-deletion-by-user — the user_id
        // FK has on delete cascade, but no policy lets a user delete the
        // row directly.
        expect(
          sql.contains('for delete'),
          isFalse,
          reason: 'attorney_privilege_acceptance must have no DELETE policy',
        );
      });
    },
  );

  // -------------------------------------------------------------------------
  // G3 — audit_log
  // -------------------------------------------------------------------------
  group('Phase 2 PII migrations contract — audit_log (G3)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('audit_log'));

    test('RLS is enabled on the table', () {
      expect(
        sql,
        contains('enable row level security'),
        reason: 'audit_log RLS must be ON so client roles see nothing',
      );
    });

    test('zero create-policy statements (service-role-only access)', () {
      // The whole point of audit_log is that no client role can read or
      // write directly. Every row arrives through SECURITY DEFINER RPCs
      // owned by service_role. ANY policy is a hole in the wall.
      final occurrences = 'create policy'.allMatches(sql).length;
      expect(
        occurrences,
        0,
        reason: 'audit_log must have NO policies — RLS denies all client '
            'access; every write comes from a SECURITY DEFINER RPC',
      );
    });

    test('action CHECK enumerates all 10 audited actions', () {
      // Wire contract: edge functions and SECURITY DEFINER RPCs INSERT
      // rows with one of these literals. Renaming silently breaks the
      // INSERT (CHECK violation).
      const actions = [
        'read_sensitive',
        'export_data',
        'delete_account',
        'consent_grant',
        'consent_revoke',
        'privilege_accept',
        'pdf_upload',
        'case_create',
        'case_close',
        'admin_access',
      ];
      for (final action in actions) {
        expect(
          sql,
          contains("'$action'"),
          reason: 'audit_log.action CHECK must permit "$action"',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // G4 — sensitive schema + read_sensitive_doc RPC
  // -------------------------------------------------------------------------
  group('Phase 2 PII migrations contract — sensitive_schema (G4)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('sensitive_schema'));

    test('sensitive schema is created (if not exists)', () {
      expect(sql, contains('create schema if not exists sensitive'));
    });

    test('schema access is REVOKED from authenticated', () {
      // If authenticated had usage, PostgREST would happily expose
      // sensitive.* to clients. `revoke all` (current shape) and
      // `revoke usage` both lock the schema; either is acceptable.
      expect(
        sql,
        anyOf(
          contains('revoke all on schema sensitive from authenticated'),
          contains('revoke usage on schema sensitive from authenticated'),
        ),
        reason: 'authenticated role must not see the sensitive schema',
      );
    });

    test('schema access is REVOKED from anon', () {
      expect(
        sql,
        anyOf(
          contains('revoke all on schema sensitive from anon'),
          contains('revoke usage on schema sensitive from anon'),
        ),
        reason: 'anon role must not see the sensitive schema',
      );
    });

    test('schema usage is GRANTED to service_role', () {
      // Edge functions running with the service-role key need to read/
      // write sensitive.* through the SECURITY DEFINER RPCs.
      expect(
        sql,
        contains('grant usage on schema sensitive to service_role'),
      );
    });

    test('read_sensitive_doc has explicit search_path (injection guard)', () {
      // SECURITY DEFINER + dynamic search_path is a classic privilege
      // escalation path. Pinning search_path at function definition
      // prevents an attacker who controls a schema from shadowing
      // public tables.
      expect(
        sql,
        contains('set search_path = public, sensitive'),
        reason: 'read_sensitive_doc must pin search_path to defeat schema '
            'injection (CVE class for SECURITY DEFINER functions)',
      );
    });

    test('read_sensitive_doc raises on null auth.uid()', () {
      // Belt-and-braces: even though anon can't reach the function via
      // PostgREST without a JWT, the function itself rejects null uid.
      expect(
        sql,
        contains("if auth.uid() is null then"),
      );
      expect(
        sql,
        contains("raise exception 'unauthorized'"),
      );
    });

    test(
      'audit-after-found pattern (post-fix B3)',
      () {
        // The B3 fix re-orders the body so the audit_log INSERT happens
        // AFTER the row-existence check, preventing an attacker from
        // inflating the audit table by hammering the RPC with random
        // doc_ids they don't own (the ownership check rejects them, but
        // pre-B3 the audit row was already written).
        final auditIdx = sql.indexOf('insert into public.audit_log');
        final foundIdx = sql.indexOf('if v_found then');
        expect(
          foundIdx,
          greaterThan(0),
          reason: 'B3 fix: must check existence (`if v_found then`) before '
              'auditing',
        );
        expect(
          auditIdx,
          greaterThan(foundIdx),
          reason: 'B3 fix: audit insert must come AFTER the existence check',
        );
      },
      skip: _awaitsFixB3
          ? 'awaits B3 audit-ordering fix — flip _awaitsFixB3 to false once '
              'read_sensitive_doc reorders audit-after-found'
          : null,
    );
  });

  // -------------------------------------------------------------------------
  // G5 — pii_redaction_map + unredact RPC
  // -------------------------------------------------------------------------
  group('Phase 2 PII migrations contract — pii_redaction_map (G5)', () {
    late String sql;
    setUpAll(() => sql = _readMigration('pii_redaction'));

    test('composite primary key is (case_id, token)', () {
      // Tokens like PERSON_1 / ADDRESS_2 are scoped per-case; the same
      // PERSON_1 in two different cases must coexist.
      expect(
        sql,
        contains('primary key (case_id, token)'),
        reason: 'pii_redaction_map PK must scope tokens per-case',
      );
    });

    test('unredact verifies ownership via user_cases', () {
      // The owner check resolves user_id from public.user_cases (which
      // is RLS-protected), NOT from the request payload.
      expect(
        sql,
        contains('from public.user_cases'),
        reason: 'unredact must read ownership from user_cases (RLS-backed)',
      );
      expect(sql, contains('where id = p_case_id'));
    });

    test(
      'audit-on-success pattern (post-fix B4)',
      () {
        // The B4 fix re-orders the body so the audit_log INSERT happens
        // AFTER the plaintext lookup succeeds — same anti-inflation
        // rationale as B3.
        expect(
          sql,
          anyOf(
            contains('if v_plain is null then'),
            contains('if not found then'),
          ),
          reason: 'B4 fix: unredact must guard the audit INSERT on a '
              'successful plaintext lookup',
        );
      },
      skip: _awaitsFixB4
          ? 'awaits B4 audit-on-success fix — flip _awaitsFixB4 to false '
              'once unredact reorders audit-after-decrypt'
          : null,
    );
  });
}
