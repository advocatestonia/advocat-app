@Tags(['fast'])
library;

// =============================================================================
// citation_verifier_test.dart — Smart Agent v2: Verified Citations
// =============================================================================
//
// Reviewer's #1 ship recommendation in the consilium synthesis: stop the
// model from hallucinating "KarS § 999" / "HMS § 75 lg 1" numbers. Every
// citation that appears in the final answer MUST be backed by a tool call
// that actually looked up that exact paragraph in this turn — otherwise we
// silently strip the number to "(уточню §)" so trust is preserved.
//
// The verifier is a pure function: regex finds, tool-call list filters,
// stripUnverified rewrites. No IO, no async — fully deterministic.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/citation_verifier.dart';

/// Lightweight test fixture mirroring the shape we need from a real tool
/// call in the agentic loop — only the fields the verifier reads.
CitationToolCall _toolCall(String name, Map<String, dynamic> input) =>
    CitationToolCall(name: name, input: input);

void main() {
  group('CitationVerifier.findCitations', () {
    test('detects KarS § 121 in Russian text', () {
      const text = 'По закону KarS § 121 это уголовное правонарушение.';
      final hits = CitationVerifier.findCitations(text);

      expect(hits, hasLength(1));
      expect(hits.first.actName, equals('KarS'));
      expect(hits.first.paragraph, equals(121));
      expect(hits.first.subParagraph, isNull);
    });

    test('detects HMS § 75 lg 1 in Estonian text', () {
      const text = 'Vaide saab esitada HMS § 75 lg 1 alusel 30 päeva jooksul.';
      final hits = CitationVerifier.findCitations(text);

      expect(hits, hasLength(1));
      expect(hits.first.actName, equals('HMS'));
      expect(hits.first.paragraph, equals(75));
      expect(hits.first.subParagraph, equals(1));
    });

    test('detects multiple citations in same paragraph', () {
      const text =
          'Ссылаюсь на KarS § 121 и HMS § 40 lg 2 — оба применимы.';
      final hits = CitationVerifier.findCitations(text);

      expect(hits, hasLength(2));
      expect(hits.map((c) => c.actName).toSet(), {'KarS', 'HMS'});
    });

    test('detects Finnish Rikoslaki citation with luku', () {
      const text =
          'Tämä kuuluu Rikoslaki 21 luku § 5 alle — törkeä pahoinpitely.';
      final hits = CitationVerifier.findCitations(text);

      expect(hits, hasLength(1));
      expect(hits.first.actName, equals('Rikoslaki'));
      expect(hits.first.paragraph, equals(5));
      expect(hits.first.luku, equals(21));
    });

    test('empty text returns empty list', () {
      expect(CitationVerifier.findCitations(''), isEmpty);
      expect(CitationVerifier.findCitations('   \n  '), isEmpty);
    });

    test('text with no citations returns empty list', () {
      const text = 'Просто разговор без упоминания законов.';
      expect(CitationVerifier.findCitations(text), isEmpty);
    });

    test('detects TLS, VÕS, TsÜS, TsMS, HKMS, Hallintolaki acts', () {
      const text =
          'See on TLS § 5 ja VÕS § 308 lg 3 ja TsÜS § 12, ka TsMS § 200 lg 2, '
          'lisaks HKMS § 41 ning Hallintolaki § 6 a.';
      final hits = CitationVerifier.findCitations(text);

      // We get at least the 5 main ones (Hallintolaki § 6 a uses letter
      // suffix which is fine if regex captures the leading number).
      final acts = hits.map((c) => c.actName).toSet();
      expect(acts, containsAll(['TLS', 'VÕS', 'TsÜS', 'TsMS', 'HKMS']));
    });

    test('charStart and charEnd point at the original substring', () {
      const text = 'Нарушение KarS § 121 повлечёт штраф.';
      final hits = CitationVerifier.findCitations(text);

      expect(hits, hasLength(1));
      final c = hits.first;
      // The matched substring should equal text.substring(start, end)
      // and should contain "KarS" and "121".
      final extracted = text.substring(c.charStart, c.charEnd);
      expect(extracted.contains('KarS'), isTrue,
          reason: 'extracted = "$extracted"');
      expect(extracted.contains('121'), isTrue);
    });
  });

  group('CitationVerifier.filterUnverified', () {
    test('verifies citation when matching search_estonian_law tool was called',
        () {
      const text = 'Согласно KarS § 121, это уголовное правонарушение.';
      final hits = CitationVerifier.findCitations(text);

      final tools = [
        _toolCall('search_estonian_law', {'query': 'KarS § 121 assault'}),
      ];

      final unverified = CitationVerifier.filterUnverified(hits, tools);
      expect(unverified, isEmpty,
          reason: 'tool query mentions KarS and 121 — should be verified');
    });

    test('marks citation unverified when no tool call mentions it', () {
      const text = 'KarS § 999 предусматривает...';
      final hits = CitationVerifier.findCitations(text);

      // Tool call covers a different paragraph
      final tools = [
        _toolCall('search_estonian_law', {'query': 'KarS § 121'}),
      ];

      final unverified = CitationVerifier.filterUnverified(hits, tools);
      expect(unverified, hasLength(1));
      expect(unverified.first.paragraph, equals(999));
    });

    test('unverified when no law-search tool ran at all', () {
      const text = 'KarS § 121 предусматривает уголовное наказание.';
      final hits = CitationVerifier.findCitations(text);

      // Tool calls exist but none are law-search
      final tools = [
        _toolCall('check_company', {'name': 'AS Test'}),
      ];

      final unverified = CitationVerifier.filterUnverified(hits, tools);
      expect(unverified, hasLength(1));
    });

    test('Finnish citation verified by search_finnish_law', () {
      const text = 'Rikoslaki 21 luku § 5 — törkeä pahoinpitely.';
      final hits = CitationVerifier.findCitations(text);

      final tools = [
        _toolCall('search_finnish_law',
            {'query': 'Rikoslaki 21 luku § 5 aggravated assault'}),
      ];

      final unverified = CitationVerifier.filterUnverified(hits, tools);
      expect(unverified, isEmpty);
    });

    test('mixed verified + unverified — only the unverified is returned', () {
      const text =
          'KarS § 121 (уже искали) и KarS § 999 (выдуманная) — обе.';
      final hits = CitationVerifier.findCitations(text);
      expect(hits.length, greaterThanOrEqualTo(2));

      final tools = [
        _toolCall('search_estonian_law', {'query': 'KarS § 121'}),
      ];

      final unverified = CitationVerifier.filterUnverified(hits, tools);
      expect(unverified, hasLength(1));
      expect(unverified.first.paragraph, equals(999));
    });
  });

  group('CitationVerifier.stripUnverified', () {
    test('replaces unverified citation with placeholder, keeps verified', () {
      const text =
          'По KarS § 121 — это нападение, а KarS § 999 — выдумка.';
      final hits = CitationVerifier.findCitations(text);

      // Mark only § 999 as unverified
      final unverified = hits.where((c) => c.paragraph == 999).toList();

      final stripped = CitationVerifier.stripUnverified(text, unverified);

      // § 121 still in the output (verified)
      expect(stripped.contains('KarS § 121'), isTrue);
      // § 999 replaced with placeholder
      expect(stripped.contains('KarS § 999'), isFalse);
      expect(stripped.contains('(уточню §)'), isTrue);
    });

    test('empty unverified list → text unchanged', () {
      const text = 'Согласно KarS § 121 это уголовное.';
      final stripped = CitationVerifier.stripUnverified(text, []);
      expect(stripped, equals(text));
    });

    test('handles overlapping replacements correctly (right-to-left)', () {
      const text = 'Ссылка KarS § 121 и HMS § 40 lg 2 в одной строке.';
      final hits = CitationVerifier.findCitations(text);
      // Mark BOTH as unverified
      final stripped = CitationVerifier.stripUnverified(text, hits);

      expect(stripped.contains('KarS § 121'), isFalse);
      expect(stripped.contains('HMS § 40'), isFalse);
      // Text around citations preserved
      expect(stripped.contains('Ссылка'), isTrue);
      expect(stripped.contains('в одной строке.'), isTrue);
    });

    test('citation with sub-paragraph (lg) is replaced as a whole', () {
      const text = 'HMS § 75 lg 1 — это срок на подачу.';
      final hits = CitationVerifier.findCitations(text);

      final stripped = CitationVerifier.stripUnverified(text, hits);
      expect(stripped.contains('HMS § 75'), isFalse);
      expect(stripped.contains('lg 1'), isFalse,
          reason: 'lg subspec must be stripped together with the §');
      expect(stripped.contains('(уточню §)'), isTrue);
    });
  });
}
