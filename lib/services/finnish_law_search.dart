// finnish_law_search.dart
// -----------------------------------------------------------------------------
// Finnish legal corpus search (v24.2 / OMEGA-5 Phase 4).
//
// Mirrors EstonianLawSearch's paragraph + keyword-scoring contract, but
// sources content via LegalLoader from `assets/legal/finland/*.json`.
//
// Known acts (5): ulkomaalaislaki, rikoslaki, rikosvahinkolaki,
// oikeudenkäymiskaari, hallintolaki. Each JSON file is a curated subset
// of the most pivotal sections for a migrant-legal-aid use case; see the
// per-file `note` field for scope caveats.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import 'legal_loader.dart';

class FinnishLawSection {
  const FinnishLawSection({
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
        'jurisdiction': 'FI',
        if (sourceUrl != null) 'url': sourceUrl,
      };
}

/// Finnish law search. Stateless facade over LegalLoader; each `search()`
/// call loads (or hits the cache for) the relevant act JSON on demand.
class FinnishLawSearch {
  FinnishLawSearch({LegalLoader? loader})
      : _loader = loader ?? LegalLoader.instance;

  final LegalLoader _loader;

  /// Known act codes bundled under `assets/legal/finland/`.
  static const List<String> knownActs = [
    'Ulkomaalaislaki',
    'Rikoslaki',
    'Rikosvahinkolaki',
    'Oikeudenkaymiskaari', // filename-safe (no umlauts)
    'Hallintolaki',
  ];

  /// Run a search. Either [paragraph] or [query] must be non-empty.
  ///
  /// * If [paragraph] is given (e.g. "§ 21:6", "RL 21:6", or a plain "21:6"),
  ///   returns exact-matching sections (optionally filtered by [act]).
  /// * Otherwise performs multi-term TF scoring across the loaded acts
  ///   (or just [act] if given) and returns the top [limit] sections.
  Future<List<FinnishLawSection>> search({
    required String query,
    String? act,
    String? paragraph,
    int limit = 5,
  }) async {
    final actFilter = act;
    final acts = actFilter != null ? [actFilter] : knownActs;

    // Load every act we plan to search against.
    final loaded = <LegalAct>[];
    for (final a in acts) {
      final corpus = await _loader.loadAct(jurisdiction: 'fi', act: a);
      if (corpus != null) loaded.add(corpus);
    }
    if (loaded.isEmpty) return [];

    // Flatten into a single list with act attribution.
    final all = <FinnishLawSection>[];
    for (final corpus in loaded) {
      for (final s in corpus.sections) {
        all.add(FinnishLawSection(
          act: corpus.code,
          actFullName: corpus.name,
          paragraph: s.paragraph,
          title: s.title,
          body: s.body,
          sourceUrl: corpus.sourceUrl,
        ));
      }
    }
    if (all.isEmpty) return [];

    // Paragraph lookup takes priority.
    if (paragraph != null && paragraph.trim().isNotEmpty) {
      final normalised = _normalizeParagraph(paragraph);
      final exact = all.where((s) {
        return _normalizeParagraph(s.paragraph) == normalised;
      }).toList();
      if (exact.isNotEmpty) return exact.take(limit).toList();
      final prefix = all.where((s) {
        return _normalizeParagraph(s.paragraph).startsWith(normalised);
      }).toList();
      return prefix.take(limit).toList();
    }

    // Keyword TF scoring.
    final terms = _tokenize(query);
    if (terms.isEmpty) return [];

    final scored = <MapEntry<double, FinnishLawSection>>[];
    for (final s in all) {
      final haystack = '${s.paragraph} ${s.title} ${s.body}'.toLowerCase();
      var score = 0.0;
      for (final term in terms) {
        final t = term.toLowerCase();
        if (t.isEmpty) continue;
        var idx = 0;
        var count = 0;
        while (true) {
          final found = haystack.indexOf(t, idx);
          if (found < 0) break;
          count++;
          idx = found + t.length;
        }
        if (count == 0) continue;
        score += count.toDouble();
        if (s.title.toLowerCase().contains(t)) score += 2;
        if (s.paragraph.toLowerCase().contains(t)) score += 3;
      }
      if (score > 0) scored.add(MapEntry(score, s));
    }
    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.take(limit).map((e) => e.value).toList();
  }

  /// Normalise a paragraph string so "RL 21:6", "§ 21:6", "21:6" all match.
  static String _normalizeParagraph(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('paragraph', '§')
        .replaceAll('par.', '§')
        .replaceAll('rl', '')
        .replaceAll('§', '');
  }

  /// Tokenise a Finnish query — Unicode letters (including ä, ö) + digits,
  /// minimum 2 chars per token.
  static List<String> _tokenize(String input) {
    final re = RegExp(r'[A-Za-zÄÖÅäöå0-9§]+', unicode: true);
    return re
        .allMatches(input)
        .map((m) => m.group(0) ?? '')
        .where((t) => t.length >= 2)
        .toList();
  }

  @visibleForTesting
  static List<String> tokenizeForTest(String input) => _tokenize(input);

  /// Diagnostic: how many sections loaded per act. Loads every act to
  /// compute the number — intentional, used from `/debug/fi-law` admin view.
  @visibleForTesting
  Future<Map<String, int>> statistics() async {
    final out = <String, int>{};
    for (final a in knownActs) {
      final corpus = await _loader.loadAct(jurisdiction: 'fi', act: a);
      out[a] = corpus?.sections.length ?? 0;
    }
    return out;
  }
}
