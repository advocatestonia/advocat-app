@Tags(['fast'])
library;

// =============================================================================
// law_chunks_jurisdiction_contract_test.dart — migration shape pin
// =============================================================================
//
// Phase 2 Pkg 1+2 (2026-05-07). Pins the SQL contract for the
// 20260507_06_law_chunks_jurisdiction.sql + 20260507_07_lookup_statute_rpc.sql
// migrations. Without this test, an accidental rename (jurisdiction →
// jurisdiction_code) or constraint drop would only show up in production
// during the routing layer's first 4xx — much later than CI.
//
// We do NOT boot Postgres here — that's what the Supabase migration
// runner does when the owner runs `supabase db push`. Instead we
// static-source-test the migration file: read it, grep for the load-
// bearing identifiers, and assert their presence.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migrationSrc;
  late String lookupSrc;

  setUpAll(() {
    // Test runs from <repo>/app/advocat_project; migrations are at
    // supabase/migrations/. Resolve relative to current dir, which the
    // `flutter test` runner sets to the package root.
    final migrationFile =
        File('supabase/migrations/20260507_06_law_chunks_jurisdiction.sql');
    final lookupFile =
        File('supabase/migrations/20260507_07_lookup_statute_rpc.sql');
    expect(
      migrationFile.existsSync(),
      isTrue,
      reason: 'Migration 20260507_06_law_chunks_jurisdiction.sql must exist',
    );
    expect(
      lookupFile.existsSync(),
      isTrue,
      reason: 'Migration 20260507_07_lookup_statute_rpc.sql must exist',
    );
    migrationSrc = migrationFile.readAsStringSync();
    lookupSrc = lookupFile.readAsStringSync();
  });

  group('20260507_06_law_chunks_jurisdiction.sql — column additions', () {
    test('adds jurisdiction column', () {
      // Must be an ADD COLUMN on jurisdiction.
      expect(
        migrationSrc,
        contains('add column if not exists jurisdiction text'),
        reason: 'must add jurisdiction column',
      );
    });

    test('adds in_force column with default true', () {
      expect(
        migrationSrc,
        contains('add column if not exists in_force boolean'),
        reason: 'must add in_force column',
      );
      // Default true — back-compat with existing 8345 rows.
      expect(
        migrationSrc.contains('in_force boolean not null default true'),
        isTrue,
        reason: 'in_force must default to true',
      );
    });

    test('backfills jurisdiction from lang before NOT NULL', () {
      // Backfill CASE must reference the existing lang values.
      expect(migrationSrc, contains("when lang = 'et'"));
      expect(migrationSrc, contains("when lang in ('eu_en', 'eu_et', 'eu_ru')"));
      // And the NOT NULL flip must come AFTER the backfill block.
      final updateIdx = migrationSrc.indexOf('update public.law_chunks');
      final notNullIdx = migrationSrc.indexOf('alter column jurisdiction set not null');
      expect(
        updateIdx >= 0 && notNullIdx > updateIdx,
        isTrue,
        reason: 'NOT NULL constraint must come after the backfill',
      );
    });

    test('CHECK constraint enforces the jurisdiction whitelist', () {
      expect(
        migrationSrc,
        contains("check (jurisdiction in ('EE', 'FI', 'EU', 'RU', 'DE'))"),
        reason:
            'jurisdiction CHECK must allow exactly EE/FI/EU/RU/DE',
      );
    });

    test('partial unique index enforces one in-force row per (act, §, juris)',
        () {
      // Critical invariant: lookup_statute relies on at most one row.
      expect(migrationSrc, contains('law_chunks_in_force_unique'));
      expect(
        migrationSrc,
        contains('unique index'),
        reason: 'must be a UNIQUE index, not just B-tree',
      );
      expect(
        migrationSrc,
        contains('(act_slug, paragraph, jurisdiction)'),
        reason: 'unique key must be (act_slug, paragraph, jurisdiction)',
      );
      expect(
        migrationSrc,
        contains('where in_force = true'),
        reason: 'must be a partial index gated on in_force',
      );
    });

    test('routing index covers (jurisdiction, in_force)', () {
      expect(
        migrationSrc,
        contains('law_chunks_jurisdiction_in_force_idx'),
      );
      expect(
        migrationSrc,
        contains('(jurisdiction, in_force)'),
      );
    });

    test('law_search RPC gains query_jurisdiction parameter', () {
      // The new signature must include query_jurisdiction with default null.
      expect(
        migrationSrc,
        contains('query_jurisdiction   text default null'),
        reason:
            'law_search must accept an optional query_jurisdiction param',
      );
      // And the WHERE clause must filter on it.
      expect(
        migrationSrc.contains(
          '(query_jurisdiction is null or lc.jurisdiction = query_jurisdiction)',
        ),
        isTrue,
        reason: 'law_search must filter rows by query_jurisdiction',
      );
      // And the WHERE must also include in_force = true so superseded rows
      // never appear in semantic search.
      expect(
        migrationSrc,
        contains('lc.in_force = true'),
        reason: 'law_search must exclude superseded rows',
      );
    });

    test('law_search returns the jurisdiction column', () {
      // Wire-format pin: clients will read row.jurisdiction.
      expect(
        migrationSrc,
        contains('jurisdiction  text,'),
        reason: 'law_search return shape must include jurisdiction',
      );
      expect(
        migrationSrc,
        contains('lc.jurisdiction,'),
      );
    });

    test('drops the old law_search signature before recreating', () {
      // Without DROP, Postgres treats the new signature as an OVERLOAD.
      expect(
        migrationSrc,
        contains('drop function if exists public.law_search'),
        reason:
            'old law_search must be dropped — signature changes are not '
            'in-place',
      );
    });
  });

  group('20260507_07_lookup_statute_rpc.sql — exact-paragraph RPC', () {
    test('declares lookup_statute with the documented param names', () {
      // Param names are LOAD-BEARING — Postgres binds positional and named
      // params separately, and the edge function calls with named args.
      for (final param in ['p_act_slug', 'p_paragraph', 'p_jurisdiction']) {
        expect(
          lookupSrc,
          contains(param),
          reason: 'lookup_statute must declare $param',
        );
      }
      // jurisdiction defaults to 'EE'.
      expect(
        lookupSrc,
        contains("p_jurisdiction  text default 'EE'"),
      );
    });

    test('returns the wire shape the client parses', () {
      // StatuteLookup.fromJson reads these fields; if any disappears,
      // production lookups go silent.
      for (
        final field in [
          'id',
          'act_slug',
          'act_name',
          'paragraph',
          'title',
          'body',
          'source_url',
          'version_date',
          'jurisdiction',
        ]
      ) {
        expect(
          lookupSrc,
          contains(field),
          reason: 'lookup_statute return must include $field',
        );
      }
    });

    test('filters on in_force = true', () {
      expect(
        lookupSrc,
        contains('lc.in_force = true'),
        reason:
            'lookup_statute must skip superseded rows (in_force = false)',
      );
    });

    test('uses ilike for case-insensitive act_slug match', () {
      // Corpus uses lowercase slugs ("kars"); model and users send mixed
      // case ("KarS"). Without ilike, lookups would silently miss.
      expect(
        lookupSrc,
        contains('lc.act_slug ilike p_act_slug'),
      );
    });

    test('grants execute to anon and authenticated', () {
      // The anon Bearer flow needs execute privileges.
      expect(
        lookupSrc,
        contains('grant execute on function public.lookup_statute'),
      );
      expect(lookupSrc, contains('to anon, authenticated'));
    });
  });
}
