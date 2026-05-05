// =============================================================================
// citation_verifier.dart — Smart Agent v2: Verified Citations post-processor.
// =============================================================================
//
// Reviewer's #1 ship recommendation in the consilium synthesis (2026-05-05):
// Claude can fabricate "KarS § 999" / "HMS § 75 lg 1" numbers. Users see plain
// text and trust it. The verifier closes the loop:
//
//   1. After the agentic loop yields the final answer, scan the text for
//      every recognised legal-act citation (Estonian KarS/HMS/HKMS/TLS/VMS/
//      VÕS/TsÜS/TsMS, Finnish Rikoslaki/Hallintolaki, etc.).
//   2. Cross-check each citation against the tool calls that ran THIS turn:
//      a `search_estonian_law` / `search_finnish_law` whose query mentions
//      the same act + paragraph counts as "verified".
//   3. Citations without a backing tool call are silently rewritten to
//      "(уточню §)" — a soft correction the model learns to avoid.
//
// Pure function. No IO, no state, fully unit-testable. Wired into
// `ai_service.dart` after the agentic loop completes.
//
// Wired in: see ai_service.dart::_verifyCitations, called once on the
// fully-assembled response text right before it is returned/yielded.
// =============================================================================

import 'package:flutter/foundation.dart';

/// One legal citation extracted from assistant text.
///
/// Example: "HMS § 75 lg 1" →
///   actName="HMS", paragraph=75, subParagraph=1, charStart=12, charEnd=27
@immutable
class CitationMatch {
  const CitationMatch({
    required this.actName,
    required this.paragraph,
    required this.charStart,
    required this.charEnd,
    this.subParagraph,
    this.luku,
  });

  /// Statute short-name as it appears in text. Always preserved verbatim
  /// (case + diacritics intact: KarS, VÕS, TsÜS).
  final String actName;

  /// The § number, e.g. 121 in "KarS § 121".
  final int paragraph;

  /// The "lg N" sub-paragraph, when present.
  final int? subParagraph;

  /// Finnish "X luku" chapter number, when present.
  final int? luku;

  /// Half-open substring range [charStart, charEnd) in the source text.
  final int charStart;
  final int charEnd;

  @override
  String toString() =>
      'CitationMatch($actName § $paragraph${subParagraph != null ? ' lg $subParagraph' : ''}${luku != null ? ' luku $luku' : ''}, [$charStart..$charEnd))';
}

/// Lightweight tool-call shape consumed by the verifier. The agentic loop
/// already collects `tool_use` blocks per turn — they get adapted into this
/// type so the verifier doesn't depend on the full ToolUseBlock class.
@immutable
class CitationToolCall {
  const CitationToolCall({required this.name, required this.input});
  final String name;
  final Map<String, dynamic> input;
}

/// Pure-function verifier. Three entry points:
///   • [findCitations] — regex extraction of every legal citation.
///   • [filterUnverified] — keep only citations not backed by a tool call.
///   • [stripUnverified] — rewrite the source text replacing unverified
///     citations with the soft-correction placeholder.
class CitationVerifier {
  CitationVerifier._();

  /// Placeholder substituted in for unverified citations. Picked to be
  /// short, neutral, and read-naturally in Russian / Estonian / Finnish
  /// answers. Owner can change it later — single point of truth.
  static const String unverifiedPlaceholder = '(уточню §)';

  /// Estonian + Finnish + cross-jurisdiction act short-names we recognise.
  /// The list is intentionally explicit (no greedy `\w+`) so a stray word
  /// like "TLA" doesn't accidentally match. Add new acts here as the
  /// product expands.
  ///
  /// Order matters for regex alternation only when shorter names are
  /// substrings of longer ones; we sort by length-desc inside the regex
  /// builder to avoid that bug.
  static const List<String> _knownActs = [
    // Estonia
    'KarS', 'KrMS', 'HMS', 'HKMS', 'HKTS', 'TLS', 'VMS', 'VÕS',
    'TsÜS', 'TsMS', 'TÕKS', 'KMS', 'PankrS', 'IKS', 'AvTS',
    'KOKS', 'PerekS', 'PsAS', 'EhS', 'PlanS', 'NPALS', 'KKS',
    // Finland (short forms — long-name regex below catches "Rikoslaki" etc.)
    'RL', 'HL', 'HLL',
  ];

  /// Long-form Finnish act names used in actual Finnish-language answers.
  static const List<String> _finnishLongActs = [
    'Rikoslaki',
    'Hallintolaki',
    'Hallintolainkäyttölaki',
    'Työsopimuslaki',
    'Perustuslaki',
  ];

  static RegExp? _cachedActRegex;
  static RegExp? _cachedFinnishLongRegex;

  /// Regex matching `<Act> § N` with optional `lg M` sub-paragraph.
  /// Allows non-breaking space (U+00A0) and an optional space around §.
  static RegExp get _actRegex {
    final cached = _cachedActRegex;
    if (cached != null) return cached;
    final acts = [..._knownActs]
      ..sort((a, b) => b.length.compareTo(a.length));
    // Word boundary at start so "TLS" doesn't match "ETLS"; we use a
    // negative lookbehind for an alphanumeric or non-breaking dash.
    final actAlt = acts.map(RegExp.escape).join('|');
    // \u00A0 = non-breaking space; we accept either kind of space around §.
    final pattern = r'(?<![A-Za-zÄÖÜÕäöüõ0-9])'
        '($actAlt)'
        r'[\s\u00A0]*§[\s\u00A0]*(\d+)'
        r'(?:[\s\u00A0]+lg[\s\u00A0]*(\d+))?';
    return _cachedActRegex = RegExp(pattern, unicode: true);
  }

  /// Regex matching `<FinnishLongAct> [N luku ]§ M`.
  static RegExp get _finnishLongRegex {
    final cached = _cachedFinnishLongRegex;
    if (cached != null) return cached;
    final actAlt = _finnishLongActs.map(RegExp.escape).join('|');
    final pattern = r'(?<![A-Za-zÄÖÜÕäöüõ])'
        '($actAlt)'
        r'(?:[\s\u00A0]+(\d+)[\s\u00A0]+luku)?'
        r'[\s\u00A0]*§[\s\u00A0]*(\d+)';
    return _cachedFinnishLongRegex = RegExp(pattern, unicode: true);
  }

  /// Find every citation in [text]. Pure — no allocations beyond the
  /// returned list. Order: source-position ascending.
  static List<CitationMatch> findCitations(String text) {
    if (text.trim().isEmpty) return const [];

    final hits = <CitationMatch>[];

    for (final m in _actRegex.allMatches(text)) {
      final actName = m.group(1)!;
      final paragraph = int.tryParse(m.group(2) ?? '');
      if (paragraph == null) continue;
      final subStr = m.group(3);
      final subParagraph = subStr == null ? null : int.tryParse(subStr);
      hits.add(CitationMatch(
        actName: actName,
        paragraph: paragraph,
        subParagraph: subParagraph,
        charStart: m.start,
        charEnd: m.end,
      ));
    }

    for (final m in _finnishLongRegex.allMatches(text)) {
      final actName = m.group(1)!;
      final lukuStr = m.group(2);
      final paragraph = int.tryParse(m.group(3) ?? '');
      if (paragraph == null) continue;
      final luku = lukuStr == null ? null : int.tryParse(lukuStr);
      hits.add(CitationMatch(
        actName: actName,
        paragraph: paragraph,
        luku: luku,
        charStart: m.start,
        charEnd: m.end,
      ));
    }

    // De-dupe overlapping spans (Finnish long regex could overlap with
    // short forms). Sort by start, drop any whose start lies inside a
    // previously kept hit's range.
    hits.sort((a, b) => a.charStart.compareTo(b.charStart));
    final dedup = <CitationMatch>[];
    int lastEnd = -1;
    for (final h in hits) {
      if (h.charStart < lastEnd) continue;
      dedup.add(h);
      lastEnd = h.charEnd;
    }
    return dedup;
  }

  /// Tool names that count as legal-corpus lookups for verification.
  /// `search_knowledge` is included because the knowledge router covers
  /// statute references in the Estonian KB too.
  static const Set<String> _verifyingTools = {
    'search_estonian_law',
    'search_finnish_law',
    'search_knowledge',
  };

  /// Returns the subset of [citations] that are NOT backed by any tool
  /// call in [toolCalls]. A citation is "backed" when at least one tool
  /// in [_verifyingTools] was called this turn whose stringified `input`
  /// payload contains BOTH the citation's `actName` AND its paragraph
  /// number as a token.
  ///
  /// We deliberately use a loose substring match rather than parsing the
  /// tool input schema: the model phrases queries differently
  /// ("KarS § 121", "KarS 121", "rape KarS 121"), and any of those count
  /// as evidence the model actually consulted the corpus.
  static List<CitationMatch> filterUnverified(
    List<CitationMatch> citations,
    List<CitationToolCall> toolCalls,
  ) {
    if (citations.isEmpty) return const [];

    // Pre-compute a single big haystack of all verifying tool queries.
    // Faster than re-scanning per citation.
    final buf = StringBuffer();
    for (final c in toolCalls) {
      if (!_verifyingTools.contains(c.name)) continue;
      buf.write(_flatten(c.input));
      buf.write(' ');
    }
    final haystack = buf.toString().toLowerCase();

    if (haystack.isEmpty) {
      // No verifying tool calls at all → every citation is unverified.
      return List.unmodifiable(citations);
    }

    final unverified = <CitationMatch>[];
    for (final c in citations) {
      final actLower = c.actName.toLowerCase();
      final paragraphStr = c.paragraph.toString();
      final actMatch = haystack.contains(actLower);
      final paragraphMatch =
          RegExp(r'(?<!\d)' + paragraphStr + r'(?!\d)').hasMatch(haystack);
      if (!(actMatch && paragraphMatch)) {
        unverified.add(c);
      }
    }
    return unverified;
  }

  /// Replace each unverified citation in [text] with [unverifiedPlaceholder].
  /// Verified citations and surrounding text are preserved verbatim.
  ///
  /// Implementation walks [unverified] right-to-left so earlier offsets
  /// remain valid as later spans are spliced out.
  static String stripUnverified(
    String text,
    List<CitationMatch> unverified,
  ) {
    if (unverified.isEmpty) return text;

    // Defensive copy + sort by charStart desc.
    final ordered = [...unverified]
      ..sort((a, b) => b.charStart.compareTo(a.charStart));

    var out = text;
    for (final c in ordered) {
      // Bounds check — if charEnd > out.length we'd throw. Skip
      // corrupted matches rather than crash the answer pipeline.
      if (c.charStart < 0 ||
          c.charEnd > out.length ||
          c.charStart >= c.charEnd) {
        continue;
      }
      out = out.substring(0, c.charStart) +
          unverifiedPlaceholder +
          out.substring(c.charEnd);
    }
    return out;
  }

  /// Flatten a tool input map into a single space-separated string for
  /// loose substring matching. Recursively descends into nested maps and
  /// lists; primitives are toString()-ed.
  static String _flatten(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value.map(_flatten).join(' ');
    }
    if (value is Map) {
      final buf = StringBuffer();
      value.forEach((k, v) {
        buf.write(k);
        buf.write(' ');
        buf.write(_flatten(v));
        buf.write(' ');
      });
      return buf.toString();
    }
    return value.toString();
  }
}
