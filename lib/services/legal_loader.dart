// legal_loader.dart
// -----------------------------------------------------------------------------
// Lazy, LRU-cached loader for legal corpora stored as JSON assets under
// `assets/legal/<jurisdiction>/<act>.json`.
//
// Purpose (v24.2 / OMEGA-5):
//   1. Keep first-paint bundle small — legal DB content is loaded only when a
//      user actually queries an act.
//   2. Share a single cache across callers (Finnish law search, Estonian law
//      search, future jurisdictions). LRU eviction keeps memory bounded even
//      if the user crawls through many acts in one session.
//   3. Be resilient — a missing asset returns `null` rather than throwing,
//      and callers can cope with partial coverage (the behaviour that
//      EstonianLawSearch.knownActs already relies on).
//
// Usage:
//
//   final loader = LegalLoader.instance;
//   final kars = await loader.loadAct(
//     jurisdiction: 'estonia',
//     act: 'KarS',
//   );
//   if (kars != null) {
//     for (final section in kars.sections) { ... }
//   }
//
// The loader is intentionally plain Dart (no Riverpod, no DI) so it can be
// used from anywhere — law search, AI tool handlers, test fixtures.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A parsed legal act — a code (KarS, Rikoslaki, etc.) with its sections.
@immutable
class LegalAct {
  const LegalAct({
    required this.code,
    required this.jurisdiction,
    required this.name,
    required this.sections,
    this.sourceUrl,
  });

  /// Act code, e.g. 'KARS', 'RIKOSLAKI', 'ULKOMAALAISLAKI'.
  /// Always stored upper-case to match cache key convention.
  final String code;

  /// ISO 2-letter jurisdiction code, lower-case, e.g. 'ee', 'fi'.
  final String jurisdiction;

  /// Human-friendly long name, e.g. 'Karistusseadustik'.
  final String name;

  /// Parsed sections (paragraph/title/body triples).
  final List<LegalSection> sections;

  /// Optional canonical source URL (e.g. riigiteataja.ee, finlex.fi).
  final String? sourceUrl;

  /// Approximate byte size — used by LRU budget accounting. Computed as
  /// `sum(body.length) + sum(title.length) + sum(paragraph.length)`, which
  /// is a decent proxy for UTF-16 memory weight without per-section work.
  int get approximateBytes {
    var total = 0;
    for (final s in sections) {
      total += s.paragraph.length + s.title.length + s.body.length;
    }
    return total;
  }
}

@immutable
class LegalSection {
  const LegalSection({
    required this.paragraph,
    required this.title,
    required this.body,
  });

  final String paragraph;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {
        'paragraph': paragraph,
        'title': title,
        'body': body,
      };
}

/// Lazy loader with a size-bounded LRU cache. Defaults to 3-act capacity,
/// which keeps the hot working set for a typical user conversation (1 act
/// being quoted, 1 just discussed, 1 being switched to) without holding
/// the entire corpus in RAM.
typedef AssetLoader = Future<String> Function(String assetPath);

class LegalLoader {
  LegalLoader({
    int capacity = 3,
    AssetLoader? assetLoader,
  })  : _capacity = capacity,
        _assetLoader = assetLoader ?? rootBundle.loadString;

  /// Shared instance. Tests can construct their own to isolate cache state.
  static final LegalLoader instance = LegalLoader();

  final int _capacity;

  /// LRU: oldest entries at the front, most-recent at the back. We use
  /// `LinkedHashMap` with `remove` + `put` to bump entries to the tail on
  /// each access.
  final LinkedHashMap<String, LegalAct> _cache = LinkedHashMap();

  /// In-flight load de-duplication — if two callers ask for the same
  /// (jurisdiction, act) while the first fetch is pending, both await the
  /// same Future. Prevents duplicate parsing under parallel load.
  final Map<String, Future<LegalAct?>> _inFlight = {};

  /// Loader for asset files. Swappable so tests can inject fake data.
  final AssetLoader _assetLoader;

  /// Cache-key format: `<jurisdiction>:<ACT>` — matches EstonianLawSearch
  /// upper-case convention for act codes.
  String _key(String jurisdiction, String act) =>
      '${jurisdiction.toLowerCase()}:${act.toUpperCase()}';

  /// Build the likely filename candidates for an act. Estonian acts like
  /// `VõrdKS` sit on disk as `vordks.json` (ASCII-folded); we try both.
  List<String> _candidateFilenames(String act) {
    final lower = act.toLowerCase();
    final folded = lower
        .replaceAll('õ', 'o')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u');
    return lower == folded ? [lower] : [lower, folded];
  }

  /// Load an act. Returns `null` if no asset file matches. Successive calls
  /// for the same (jurisdiction, act) return the cached instance — the LRU
  /// moves the entry to the tail on every read.
  ///
  /// [jurisdiction] — ISO 2-letter code, e.g. 'ee', 'fi'. Case-insensitive.
  /// [act]          — act code, e.g. 'KarS', 'Rikoslaki'. Case-insensitive.
  Future<LegalAct?> loadAct({
    required String jurisdiction,
    required String act,
  }) async {
    final key = _key(jurisdiction, act);

    // Cache hit — move to tail (mark as recently used) and return.
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }

    // Parallel-load dedup — if another caller is already fetching this
    // act, join that Future rather than start a second load.
    final inFlight = _inFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchAndParse(jurisdiction, act);
    _inFlight[key] = future;
    try {
      final parsed = await future;
      if (parsed != null) {
        _insertLru(key, parsed);
      }
      return parsed;
    } finally {
      // Map.remove returns the removed Future<LegalAct?>?; we have already
      // awaited it via `await future` above, so it's safe to discard.
      // Make intent explicit to silence unawaited_futures lint.
      final removed = _inFlight.remove(key);
      if (removed != null) unawaited(removed);
    }
  }

  Future<LegalAct?> _fetchAndParse(String jurisdiction, String act) async {
    final juris = jurisdiction.toLowerCase();
    for (final fileName in _candidateFilenames(act)) {
      final path = 'assets/legal/$juris/$fileName.json';
      try {
        final raw = await _assetLoader(path);
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final name = (decoded['name'] as String?) ?? act;
        final source = decoded['source'] as String?;
        final rawSections = decoded['sections'] as List<dynamic>? ?? const [];
        final sections = <LegalSection>[];
        for (final r in rawSections) {
          final m = r as Map<String, dynamic>;
          final paragraph = (m['paragraph'] as String? ?? '').trim();
          final title = (m['title'] as String? ?? '').trim();
          final body = (m['body'] as String? ?? '').trim();
          final subs = m['subsections'] as List<dynamic>? ?? const [];
          final subsBody = subs
              .map((sub) {
                final smap = sub as Map<String, dynamic>;
                return '${smap['id'] ?? ''} ${smap['text'] ?? ''}';
              })
              .where((line) => line.trim().isNotEmpty)
              .join('\n');
          final fullBody =
              [body, subsBody].where((s) => s.isNotEmpty).join('\n');
          if (paragraph.isEmpty && fullBody.isEmpty) continue;
          sections.add(LegalSection(
            paragraph: paragraph,
            title: title,
            body: fullBody,
          ));
        }
        return LegalAct(
          code: act.toUpperCase(),
          jurisdiction: juris,
          name: name,
          sections: sections,
          sourceUrl: source,
        );
      } catch (_) {
        // Try next candidate filename; swallow so missing assets don't
        // crash the loader — the caller decides on fallback behaviour.
      }
    }
    return null;
  }

  void _insertLru(String key, LegalAct value) {
    _cache[key] = value;
    while (_cache.length > _capacity) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  /// Currently cached act codes, oldest-first (LRU order).
  @visibleForTesting
  List<String> get cachedKeysForTest => _cache.keys.toList(growable: false);

  /// Manual eviction — normally unnecessary, useful for tests and for memory
  /// pressure scenarios (e.g. OS "low memory" signal on mobile).
  void clearCache() {
    _cache.clear();
  }
}
