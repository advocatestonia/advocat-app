import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// ---------------------------------------------------------------------------
// Estonian law semantic + paragraph search
// ---------------------------------------------------------------------------
//
// Loads JSON corpora from `assets/legal/estonia/<act>.json` on first use and
// exposes two lookup modes:
//
// 1. Paragraph lookup:   search(paragraph: "§ 121", act: "KarS")
// 2. Keyword scoring:    search(query: "koondamise hüvitis")
//
// The keyword scorer is intentionally tiny — Latin+Cyrillic tokenisation,
// case-fold, exact-term TF scoring. It's fast, deterministic, and requires
// no external model. Good enough for law-book lookups where the user supplies
// specific legal terms.
//
// If the asset file for a given act is missing, the search silently skips it.
// Missing acts can be added later via `scripts/ingest_estonian_laws.dart`.
// ---------------------------------------------------------------------------

class LawSection {
  LawSection({
    required this.act,
    required this.actFullName,
    required this.paragraph,
    required this.title,
    required this.body,
    this.sourceUrl,
  });

  final String act;
  final String actFullName;
  final String paragraph;
  final String title;
  final String body;
  final String? sourceUrl;

  String bodyPreview(int maxLen) =>
      body.length > maxLen ? '${body.substring(0, maxLen)}…' : body;

  Map<String, dynamic> toJson() => {
        'act': act,
        'act_full_name': actFullName,
        'paragraph': paragraph,
        'title': title,
        'body': body,
        if (sourceUrl != null) 'url': sourceUrl,
      };
}

/// Cached corpora keyed by act code (upper-case, e.g. "KARS", "HMS").
abstract final class EstonianLawSearch {
  static final Map<String, List<LawSection>> _corpusCache = {};
  static bool _indexBuilt = false;

  /// Known act codes bundled (or soon-to-be bundled) as asset JSONs.
  /// Keep in sync with `scripts/ingest_estonian_laws.dart`.
  static const List<String> knownActs = [
    'HMS', 'HKMS', 'PKS', 'TLS', 'KarS', 'VMS', 'VÕS', 'PärS', 'VõrdKS',
    // v24.1 additions (ingested via scripts/ingest_estonian_laws.dart):
    'MKS', 'TuMS', 'KMS', 'TsMS', 'KrMS', 'ÄS', 'IKS', 'LS', 'LKindlS',
    'TsÜS', 'AsjS',
  ];

  /// Load a single act's JSON from assets. Returns null if missing.
  ///
  /// Expected schema:
  /// ```json
  /// {
  ///   "act": "KarS",
  ///   "name": "Karistusseadustik",
  ///   "source": "https://www.riigiteataja.ee/akt/KarS",
  ///   "sections": [
  ///     {
  ///       "paragraph": "§ 121",
  ///       "title": "Tervisekahjustuse tekitamine",
  ///       "body": "Teise inimese...",
  ///       "subsections": [
  ///         { "id": "lg 1", "text": "..." },
  ///         { "id": "lg 2", "text": "..." }
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<List<LawSection>?> _loadAct(String act) async {
    final key = act.toUpperCase();
    final cached = _corpusCache[key];
    if (cached != null) return cached;

    final candidateFileNames = <String>{
      act.toLowerCase(),
      act.toLowerCase().replaceAll('õ', 'o').replaceAll('ä', 'a')
          .replaceAll('ö', 'o').replaceAll('ü', 'u'),
    };

    for (final fileName in candidateFileNames) {
      final path = 'assets/legal/estonia/$fileName.json';
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final name = decoded['name'] as String? ?? act;
        final source = decoded['source'] as String?;
        final sections = decoded['sections'] as List<dynamic>? ?? [];

        final parsed = <LawSection>[];
        for (final raw in sections) {
          final s = raw as Map<String, dynamic>;
          final paragraph = (s['paragraph'] as String? ?? '').trim();
          final title = (s['title'] as String? ?? '').trim();
          final body = (s['body'] as String? ?? '').trim();
          final subs = s['subsections'] as List<dynamic>? ?? [];
          final subsBody = subs
              .map((sub) {
                final smap = sub as Map<String, dynamic>;
                return '${smap['id'] ?? ''} ${smap['text'] ?? ''}';
              })
              .where((line) => line.trim().isNotEmpty)
              .join('\n');
          final fullBody = [body, subsBody]
              .where((s) => s.isNotEmpty)
              .join('\n');
          if (paragraph.isEmpty && fullBody.isEmpty) continue;
          parsed.add(LawSection(
            act: act,
            actFullName: name,
            paragraph: paragraph,
            title: title,
            body: fullBody,
            sourceUrl: source,
          ));
        }
        _corpusCache[key] = parsed;
        return parsed;
      } catch (_) {
        // Try next candidate filename.
      }
    }

    _corpusCache[key] = const []; // Negative cache to avoid repeated I/O.
    return null;
  }

  /// Ensure every known act is at least attempted to load.
  static Future<void> _buildIndex() async {
    if (_indexBuilt) return;
    for (final act in knownActs) {
      await _loadAct(act);
    }
    _indexBuilt = true;
  }

  /// Run a search. Either [paragraph] or [query] must be non-empty.
  ///
  /// * If [paragraph] is given (e.g. "§ 121" or "§ 40 lg 3"), returns exact
  ///   matches (optionally filtered by [act]).
  /// * Otherwise performs case-insensitive multi-term scoring across all
  ///   loaded acts (or just [act] if given) and returns the top [limit]
  ///   sections.
  static Future<List<LawSection>> search({
    required String query,
    String? act,
    String? paragraph,
    int limit = 5,
  }) async {
    await _buildIndex();

    final actFilter = act?.toUpperCase();
    final allSections = <LawSection>[];
    _corpusCache.forEach((k, v) {
      if (actFilter == null || k == actFilter) {
        allSections.addAll(v);
      }
    });
    if (allSections.isEmpty) return [];

    // Paragraph lookup takes priority when supplied.
    if (paragraph != null && paragraph.trim().isNotEmpty) {
      final normalized = _normalizeParagraph(paragraph);
      final exact = allSections.where((s) {
        return _normalizeParagraph(s.paragraph) == normalized;
      }).toList();
      if (exact.isNotEmpty) return exact.take(limit).toList();
      // Fallback: prefix (e.g. "§ 121" matches "§ 121 lg 1").
      final prefix = allSections.where((s) {
        return _normalizeParagraph(s.paragraph).startsWith(normalized);
      }).toList();
      return prefix.take(limit).toList();
    }

    // Keyword scoring.
    final terms = _tokenize(query);
    if (terms.isEmpty) return [];

    final scored = <MapEntry<double, LawSection>>[];
    for (final s in allSections) {
      final haystack = '${s.paragraph} ${s.title} ${s.body}'.toLowerCase();
      double score = 0;
      for (final term in terms) {
        final t = term.toLowerCase();
        if (t.isEmpty) continue;
        // Count occurrences (simple TF).
        int idx = 0;
        int count = 0;
        while (true) {
          final found = haystack.indexOf(t, idx);
          if (found < 0) break;
          count++;
          idx = found + t.length;
        }
        if (count == 0) continue;
        // Weight title hits double, paragraph identifier triple.
        score += count.toDouble();
        if (s.title.toLowerCase().contains(t)) score += 2;
        if (s.paragraph.toLowerCase().contains(t)) score += 3;
      }
      if (score > 0) scored.add(MapEntry(score, s));
    }
    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.take(limit).map((e) => e.value).toList();
  }

  /// Normalise a paragraph string ("§ 121 lg 1" → "§121lg1").
  static String _normalizeParagraph(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('paragraph', '§')
        .replaceAll('par.', '§');
  }

  /// Split by whitespace / punctuation, keep tokens with length ≥ 2.
  static List<String> _tokenize(String input) {
    final re = RegExp(r"[A-Za-zÀ-ž0-9§ÕÄÖÜõäöü]+", unicode: true);
    return re
        .allMatches(input)
        .map((m) => m.group(0) ?? '')
        .where((t) => t.length >= 2)
        .toList();
  }

  /// For tests / debug — returns how many sections were indexed per act.
  static Future<Map<String, int>> statistics() async {
    await _buildIndex();
    return _corpusCache.map((k, v) => MapEntry(k, v.length));
  }

  /// Reset cache — used by tests.
  static void resetForTests() {
    _corpusCache.clear();
    _indexBuilt = false;
  }
}
