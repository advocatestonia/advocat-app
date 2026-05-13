@Tags(['fast'])
library;

// =============================================================================
// shareable_results_migration_test.dart — schema contract for Share feature.
// =============================================================================
//
// 2026-05-14 — pins the migration file so the Flutter ShareResultService and
// the share-result edge function rely on a stable column shape. Static-text
// contract — no DB connection. Asserts:
//   1. file exists at the expected path,
//   2. creates the public.shared_results table,
//   3. share_slug is UNIQUE NOT NULL,
//   4. source_type CHECK constraint lists all three accepted slugs,
//   5. redacted_content is JSONB NOT NULL,
//   6. RLS is enabled,
//   7. public-read policy gates on `is_public = true` AND `expires_at > now()`,
//   8. owner policy grants FOR ALL to authenticated users (`auth.uid() = user_id`),
//   9. expiry default is 90 days,
//  10. SELECT is granted to anon + authenticated.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Share — shareable_results migration', () {
    final migrationFile = File(
      'supabase/migrations/20260514030000_shareable_results.sql',
    );

    late String sql;

    setUpAll(() {
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason:
            'Share migration file is missing: ${migrationFile.path}. '
            'The share-result edge function depends on this schema — '
            'restore the file instead of removing the test.',
      );
      sql = migrationFile.readAsStringSync();
    });

    test('creates public.shared_results table', () {
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.shared_results'));
    });

    test('share_slug is UNIQUE NOT NULL', () {
      expect(sql, contains('share_slug'));
      expect(sql.contains('share_slug          text UNIQUE NOT NULL'), isTrue);
    });

    test('source_type CHECK constraint lists all three accepted slugs', () {
      // The exact ordering inside the IN(...) list doesn't matter, but all
      // three slugs MUST appear.
      expect(sql, contains("'contract_review'"));
      expect(sql, contains("'legal_advice'"));
      expect(sql, contains("'deadline_analysis'"));
      // And the CHECK clause itself must be present.
      expect(sql.toLowerCase(), contains('check (source_type in ('));
    });

    test('redacted_content is JSONB NOT NULL', () {
      expect(sql, contains('redacted_content    jsonb NOT NULL'));
    });

    test('RLS is enabled', () {
      expect(
        sql,
        contains('ALTER TABLE public.shared_results ENABLE ROW LEVEL SECURITY'),
      );
    });

    test('public read policy gates on is_public AND expires_at > now()', () {
      // The policy body must require both gates so an owner-toggled or
      // expired share stops being publicly visible.
      expect(sql, contains('public reads non-expired'));
      expect(sql, contains('is_public = true'));
      expect(sql, contains('expires_at > now()'));
    });

    test('owner FOR ALL policy keyed on auth.uid() = user_id', () {
      expect(sql, contains('owner manages own shares'));
      expect(sql, contains('auth.uid() = user_id'));
    });

    test('expiry default is 90 days', () {
      expect(sql, contains("now() + INTERVAL '90 days'"));
    });

    test('SELECT is granted to anon + authenticated', () {
      expect(
        sql,
        contains('GRANT SELECT ON public.shared_results TO anon, authenticated'),
      );
    });

    test('view_count and signup_attributions default to 0', () {
      expect(sql, contains('view_count          int NOT NULL DEFAULT 0'));
      expect(
        sql,
        contains('signup_attributions int NOT NULL DEFAULT 0'),
      );
    });
  });
}
