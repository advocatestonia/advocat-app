@Tags(['fast'])
library;

// =============================================================================
// case_memory_migration_test.dart — schema contract for Pkg 1.A
// =============================================================================
//
// 2026-05-06 — Pkg 1.A of the smart-lawyer rebuild (handoff
// project_handoff_smart_lawyer.md). Pins the migration file so sister
// agents shipping Pkg 1.B (claude-proxy injection), Pkg 1.C (auto-patch
// worker) and Pkg 1.D (Flutter UI) can rely on a stable schema surface.
//
// This is a static-text contract test — no DB connection, no Supabase
// client. It just asserts the migration file:
//   1. exists at the expected path,
//   2. defines all three tables (user_cases, case_documents,
//      case_chat_sessions),
//   3. wires the case_id column onto chat_messages,
//   4. enables RLS on all three tables,
//   5. has owner-only RLS policies (auth.uid() = user_id).
//
// Lightweight by design — runs in the @fast bucket so the pre-commit hook
// catches accidental schema deletions.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pkg 1.A — case memory migration', () {
    final migrationFile = File(
      'supabase/migrations/20260506100000_case_memory.sql',
    );

    late String sql;

    setUpAll(() {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Pkg 1.A migration file is missing: ${migrationFile.path}. '
            'Pkg 1.B/1.C/1.D depend on this schema — restore the file '
            'instead of removing the test.',
      );
      sql = migrationFile.readAsStringSync();
    });

    test('defines user_cases table', () {
      expect(
        sql,
        contains('create table if not exists public.user_cases'),
        reason: 'user_cases is the case-memory root table for Pkg 1.A.',
      );
    });

    test('defines case_documents table', () {
      expect(
        sql,
        contains('create table if not exists public.case_documents'),
        reason: 'case_documents holds parsed PDFs + embeddings for Pkg 2.',
      );
    });

    test('defines case_chat_sessions table', () {
      expect(
        sql,
        contains('create table if not exists public.case_chat_sessions'),
        reason: 'case_chat_sessions groups messages per user visit.',
      );
    });

    test('wires case_id onto chat_messages', () {
      expect(sql, contains('alter table'));
      expect(
        sql,
        contains('add column if not exists case_id'),
        reason:
            'Pkg 1.B filters messages for the active case via this column.',
      );
    });

    test('enables RLS on all three tables (3 statements)', () {
      final rlsCount = 'enable row level security'.allMatches(sql).length;
      expect(
        rlsCount,
        equals(3),
        reason:
            'Expected exactly 3 `enable row level security` statements — '
            'one each for user_cases, case_documents, case_chat_sessions. '
            'Found $rlsCount.',
      );
    });

    test('uses owner-only policies (auth.uid() = user_id)', () {
      expect(
        sql,
        contains('auth.uid() = user_id'),
        reason:
            'RLS policies must be owner-scoped. Cross-user access opens '
            'a privacy hole — see feedback_anti_regression_rules.md.',
      );
    });
  });
}
