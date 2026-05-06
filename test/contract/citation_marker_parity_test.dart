@Tags(['fast'])
library;

// =============================================================================
// citation_marker_parity_test.dart — Phase 2 Pkg 2 (seam: citations marker)
// =============================================================================
//
// 2026-05-06 — Pkg 2 of the Citations API + Grounding pipeline. Pins the
// Dart-side marker constant `kCitationMarkerPattern` in lockstep with the
// Deno-side `CITATION_MARKER_PATTERN` exported from
// supabase/functions/_shared/citation_grounder.ts. The two regexes MUST
// match byte-for-byte; rendering on the client + verifying on the server
// would otherwise drift silently.
//
// Contract:
//   1. The Dart constant exists at the documented path.
//   2. Dart and Deno regex sources are identical strings.
//   3. The pattern matches every documented form (§2 of the design doc).
//   4. The pattern does NOT match prose-style citations (collision avoidance).
//   5. SystemPrompts.formatLawContext() emits the marker directive + per-
//      chunk slug:paragraph annotation so the model has the data it needs
//      to compose `[[ref:tls:88]]` markers.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/core/citations/marker.dart';
import 'package:advocat/services/law_search_client.dart';
import 'package:advocat/services/system_prompts.dart';

void main() {
  group('marker regex — pattern shape', () {
    test('Dart regex matches every documented form', () {
      final re = RegExp(kCitationMarkerPattern);
      const valid = [
        '[[ref:TLS:88]]',
        '[[ref:tls:88]]',
        '[[ref:KarS:121]]',
        '[[ref:32019L1152:5]]',
        '[[ref:32019L1152:5:en]]',
        '[[ref:HMS:40-1]]',
        '[[ref:tls:5a]]',
      ];
      for (final s in valid) {
        expect(re.hasMatch(s), isTrue, reason: 'expected match: $s');
      }
    });

    test('Dart regex rejects malformed and collision-prone forms', () {
      final re = RegExp(kCitationMarkerPattern);
      const invalid = [
        '[TLS §88]', // prose-style — must NOT collide
        '[[ref:TLS]]', // missing paragraph
        '[[ref:]]', // empty
        '[[notref:TLS:88]]', // wrong keyword
        '[[ref:TLS:88', // unclosed
        '§88 закона о труде', // pure prose
      ];
      for (final s in invalid) {
        expect(re.hasMatch(s), isFalse, reason: 'expected no match: $s');
      }
    });

    test('Dart and Deno regex sources are identical strings', () {
      // Locks the literal string so any drift between the two
      // implementations breaks this test before it ships.
      final repoRoot = Directory.current;
      final denoFile = File(
        '${repoRoot.path}/supabase/functions/_shared/citation_grounder.ts',
      );
      expect(denoFile.existsSync(), isTrue,
          reason:
              'citation_grounder.ts is the source of truth on the server side.');
      final denoSrc = denoFile.readAsStringSync();
      // Match the constant declaration. Use String.raw`...` form per the
      // Deno file. We extract the raw pattern between the backticks.
      final m = RegExp(
        r'export const CITATION_MARKER_PATTERN\s*=\s*'
        r'String\.raw`([^`]+)`',
      ).firstMatch(denoSrc);
      expect(m, isNotNull,
          reason: 'CITATION_MARKER_PATTERN must be declared via String.raw`…`');
      final denoPattern = m!.group(1);
      expect(denoPattern, kCitationMarkerPattern,
          reason: 'Dart and Deno regexes MUST be byte-identical.');
    });

    test('captures act_slug, paragraph, optional lang in three groups', () {
      final re = RegExp(kCitationMarkerPattern);
      final m = re.firstMatch('[[ref:32019L1152:5:en]]');
      expect(m, isNotNull);
      expect(m!.group(1), '32019L1152');
      expect(m.group(2), '5');
      expect(m.group(3), 'en');

      final m2 = re.firstMatch('[[ref:TLS:88]]');
      expect(m2, isNotNull);
      expect(m2!.group(1), 'TLS');
      expect(m2.group(2), '88');
      expect(m2.group(3), isNull);
    });
  });

  group('SystemPrompts.formatLawContext — marker directive', () {
    test('emits the [[ref:slug:para]] directive when chunks have act_slug',
        () {
      final chunks = [
        const LawChunk(
          actName: 'Töölepingu seadus',
          paragraph: '§ 88',
          body: 'Tööandja võib lepingu erakorraliselt üles öelda.',
          similarity: 0.92,
          sourceUrl: 'https://www.riigiteataja.ee/akt/tls',
          actSlug: 'tls',
          id: 'tls-§88-1',
        ),
      ];
      final block = SystemPrompts.formatLawContext(chunks);
      // Per-chunk header still works with the legacy "### <act> <para>"
      // contract from rag_injection_contract_test.
      expect(block, contains('### Töölepingu seadus § 88'));
      // The act_slug + paragraph annotation appears so the model knows
      // what to put in the marker.
      expect(block, contains('act_slug: tls'));
      expect(block, contains('paragraph: 88'));
      // The marker directive itself appears (per design §2 model
      // instruction). We don't pin the exact wording — just that the
      // marker token shape and the literal phrase "[[ref:" are present.
      expect(block, contains('[[ref:'));
    });

    test('paragraph annotation strips leading § sign', () {
      // RAG headers display "§ 88" (with sign); marker syntax uses "88"
      // without it. Per design §2 the verifier joins on (act_slug,
      // paragraph) where paragraph is the raw token — so we MUST emit
      // "paragraph: 88", not "paragraph: § 88", in the chunk header.
      final chunks = [
        const LawChunk(
          actName: 'KarS',
          paragraph: '§ 121',
          body: 'Kehaline väärkohtlemine.',
          similarity: 0.9,
          actSlug: 'kars',
        ),
      ];
      final block = SystemPrompts.formatLawContext(chunks);
      expect(block, contains('paragraph: 121'),
          reason: '§ sign must be stripped for the marker-friendly form.');
    });
  });
}
