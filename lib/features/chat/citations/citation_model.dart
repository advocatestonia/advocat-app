// =============================================================================
// citation_model.dart — Phase 2 Pkg 2 client-side citation row.
// -----------------------------------------------------------------------------
// Mirror of the JSON shape returned by `claude-proxy` per the architect spec
// at docs/architecture/phase2-pkg2-citations.md §3 ("New response shape").
//
// One Citation == one distinct `[[ref:ACT:PARAGRAPH]]` marker emitted by the
// model in this turn's reply. Repeats of the same marker collapse to a single
// Citation with `occurrences > 1`. The bottom sheet, the inline chip span,
// and the per-message footer all read from the same instance — see widgets
// under lib/features/chat/widgets/citations/.
//
// Pure data class. No Riverpod, no Flutter dependency, no IO.
// =============================================================================

import 'package:flutter/foundation.dart';

/// Outcome of the proxy-side grounding verifier for a single marker.
///
/// Mapping from the verifier's string status (see citation_grounder.ts):
///   * `verified`   — marker matched a chunk that was retrieved THIS turn AND
///                    that chunk is still in force. Green badge in the UI.
///   * `unverified` — model emitted a marker for an act+paragraph that wasn't
///                    in the rag_context. Red badge + "verify before relying"
///                    tooltip in the UI; never silently hidden.
///   * `historical` — chunk WAS retrieved but its `in_force` is false. Amber
///                    badge "no longer in force" in the UI.
///
/// `unknown` is a forward-compat sink for any future status the server adds —
/// the UI degrades to neutral styling rather than crash.
enum CitationStatus { verified, unverified, historical, unknown }

/// Parse a server status string into the typed enum. Tolerant of casing and
/// of brand-new values (folds them to `unknown` instead of throwing).
CitationStatus citationStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'verified':
      return CitationStatus.verified;
    case 'unverified':
      return CitationStatus.unverified;
    case 'historical':
      return CitationStatus.historical;
    default:
      return CitationStatus.unknown;
  }
}

/// One grounded (or attempted-to-be-grounded) citation attached to an
/// assistant chat message.
///
/// Field set is a strict subset of the proxy's `Citation` interface so
/// drift is caught at decode time. All fields except [marker], [actSlug],
/// [paragraph], [status] and [occurrences] may be null when the citation
/// is `unverified` (no chunk to draw `act_name`, `snippet`, etc. from).
@immutable
class Citation {
  const Citation({
    required this.marker,
    required this.status,
    required this.actSlug,
    required this.paragraph,
    required this.occurrences,
    this.chunkId,
    this.actName,
    this.title,
    this.snippet,
    this.sourceUrl,
    this.jurisdiction,
    this.inForce,
  });

  /// Verbatim marker as it appears in the reply text, e.g. `[[ref:TLS:88]]`.
  /// Renderers replace this token in-place with a chip — keep it for the
  /// regex-based marker scan in [CitationMarkerSpan].
  final String marker;

  /// Outcome of the verifier for this marker.
  final CitationStatus status;

  /// `law_chunks.id` of the matched chunk — `null` when unverified.
  final String? chunkId;

  /// Lowercase act slug, e.g. `tls`, `kars`, `32019l1152`. Present even on
  /// unverified rows because the verifier still extracted it from the
  /// marker — the renderer needs it to display "TLS §88" with no chunk.
  final String actSlug;

  /// Paragraph identifier preserved exactly from the marker (e.g. `88`,
  /// `5a`, `art-2`).
  final String paragraph;

  /// Human-readable act name e.g. "Töölepingu seadus". Null when the
  /// citation is unverified or the chunk header carried no act_name.
  final String? actName;

  /// Optional § title, e.g. "Tööandja erakorraline ülesütlemine".
  final String? title;

  /// Up to 400 chars of the chunk body (truncated server-side). Rendered
  /// as a blockquote in the bottom sheet.
  final String? snippet;

  /// Canonical Riigi Teataja / Finlex / EUR-Lex URL — the `Avada Riigi
  /// Teatajas` button uses this when present, otherwise the fallback
  /// builder in [riigi_teataja_url.dart] reconstructs one.
  final String? sourceUrl;

  /// EE / FI / EU / RU — used by the URL builder fallback.
  final String? jurisdiction;

  /// Snapshot of `law_chunks.in_force` at verification time. Drives the
  /// historical badge. Null when unverified (we don't know).
  final bool? inForce;

  /// Number of times the same marker appeared in the reply text (≥1).
  /// The chip span renders one chip per occurrence; the bottom sheet
  /// is opened once per marker key.
  final int occurrences;

  /// Lookup key used by the chip span to find the right Citation when a
  /// chip is tapped. Matches the verifier's index key
  /// (`lower(act_slug):paragraph`).
  String get key => '${actSlug.toLowerCase()}:$paragraph';

  /// Human-readable label rendered on the inline chip — e.g. "TLS §88".
  /// Uppercases the slug because the user-facing form of Estonian act
  /// names is uppercase ("TLS", "KarS"), even though the slug column
  /// is normalised to lowercase. Falls back to the act_name if present
  /// AND the slug is too cryptic (CELEX numbers like `32019l1152`).
  String get displayLabel {
    final slug = actSlug;
    // CELEX-style identifier — show the full ID + paragraph for clarity.
    if (RegExp(r'^[0-9]{4,}[a-z][0-9]+', caseSensitive: false).hasMatch(slug)) {
      return '${slug.toUpperCase()} §$paragraph';
    }
    return '${slug.toUpperCase()} §$paragraph';
  }

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      marker: (json['marker'] as String?) ?? '',
      status: citationStatusFromString(json['status'] as String?),
      chunkId: json['chunk_id'] as String?,
      actSlug: ((json['act_slug'] as String?) ?? '').toLowerCase(),
      paragraph: (json['paragraph'] as String?) ?? '',
      actName: json['act_name'] as String?,
      title: json['title'] as String?,
      snippet: json['snippet'] as String?,
      sourceUrl: json['source_url'] as String?,
      jurisdiction: json['jurisdiction'] as String?,
      inForce: json['in_force'] as bool?,
      occurrences: (json['occurrences'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'marker': marker,
        'status': status.name,
        'chunk_id': chunkId,
        'act_slug': actSlug,
        'paragraph': paragraph,
        'act_name': actName,
        'title': title,
        'snippet': snippet,
        'source_url': sourceUrl,
        'jurisdiction': jurisdiction,
        'in_force': inForce,
        'occurrences': occurrences,
      };

  /// Decode a `citations: [...]` JSON array into typed instances. Tolerant
  /// of malformed entries — drops them silently rather than crashing the
  /// chat render path. The verifier guarantees a valid array, but offline
  /// queue replays / cached responses could be older shapes.
  static List<Citation> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Citation>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final c = Citation.fromJson(item);
        if (c.marker.isEmpty || c.actSlug.isEmpty || c.paragraph.isEmpty) {
          continue;
        }
        out.add(c);
      } else if (item is Map) {
        // Tolerate Map<dynamic, dynamic> too (Supabase REST sometimes
        // hands us this shape on Web).
        out.add(Citation.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return out;
  }
}
