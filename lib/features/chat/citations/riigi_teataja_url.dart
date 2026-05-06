// =============================================================================
// riigi_teataja_url.dart — Phase 2 Pkg 2 source-URL builder.
// -----------------------------------------------------------------------------
// Spec: docs/architecture/phase2-pkg2-citations.md §7.
//
// Convention: corpus stores `act_slug` lowercase. `law_chunks.source_url`
// is already populated by the P0-1 scraper with the canonical RT URL —
// the bottom sheet's "Avada Riigi Teatajas" button uses it directly when
// present. This builder kicks in only when `source_url` is null (legacy
// rows, EU directives, FI/RU placeholders).
//
// Versioned-historical URLs are out of scope (Pkg 9). When a citation is
// `historical` we still link to the in-force version + show the amber
// badge in the UI.
// =============================================================================

/// Build a deep link to the source act for a citation.
///
/// Resolution order:
///   1. If [sourceUrl] is set, use it verbatim. Append `#paraN` only when
///      the URL has no fragment of its own.
///   2. Otherwise pick a host based on [jurisdiction] (EE/EU/FI) and
///      compose a slug-based URL. Anchor `#paraN` is supported by
///      Riigi Teataja's own paragraph IDs (`<a id="para88">`).
///   3. Default fallback is Riigi Teataja (the EE corpus is the primary).
///
/// Returns a non-null, non-empty String — the bottom sheet button is
/// always shown when a citation has any identifying slug.
String buildRiigiTeatajaUrl({
  required String actSlug,
  required String paragraph,
  String? jurisdiction,
  String? sourceUrl,
}) {
  final slug = actSlug.toLowerCase();
  final para = paragraph.trim();

  if (sourceUrl != null && sourceUrl.isNotEmpty) {
    // Don't double-anchor — leave caller-supplied URL as-is when it
    // already pins a section.
    if (sourceUrl.contains('#')) return sourceUrl;
    if (para.isEmpty) return sourceUrl;
    return '$sourceUrl#para$para';
  }

  final j = (jurisdiction ?? '').toUpperCase();

  if (j == 'EU') {
    // CELEX-style act ids (32019L1152) live on EUR-Lex. EUR-Lex doesn't
    // have stable per-article fragment IDs across translations (see
    // architect §10), so we link to the directive landing page.
    return 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:'
        '${slug.toUpperCase()}';
  }

  if (j == 'FI') {
    // Finlex acts — keyword search until Pkg 1's FI corpus expansion
    // gives us per-act stable URLs.
    return 'https://www.finlex.fi/fi/laki/ajantasa/?keyword=$slug';
  }

  // Default: Estonia (EE corpus is the primary).
  final base = 'https://www.riigiteataja.ee/akt/$slug';
  if (para.isEmpty) return base;
  return '$base#para$para';
}
