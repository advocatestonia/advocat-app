// Phase 2 Pkg 2 — citation marker regex (Dart side).
// -----------------------------------------------------------------------------
// Mirrors the Deno-side `CITATION_MARKER_PATTERN` exported from
// supabase/functions/_shared/citation_grounder.ts. The two regex SOURCES
// MUST be byte-identical — the parity is enforced by
// test/contract/citation_marker_parity_test.dart.
//
// Why mirror instead of share: the chat client renders inline `[[ref:…]]`
// markers as tappable chips (CitationMarkerSpan, Pkg 2 widget), which means
// the same scan happens client-side AND server-side. Drift would mean a
// chip that appears on screen but has no matching server-side citation row,
// or vice versa.
//
// Shape (verbatim — DO NOT diverge from the Deno constant without updating
// the Deno side and the parity test):
//   \[\[ref:([A-Za-z0-9_-]+):([A-Za-z0-9_-]+)(?::([a-z_]+))?\]\]
// Capture groups:
//   1 — act_slug (case-insensitive; the verifier normalises to lowercase)
//   2 — paragraph (preserved exactly, e.g. '88', '5a', 'art-2')
//   3 — optional locale suffix for EU directives (e.g. 'en')
// -----------------------------------------------------------------------------

/// Single canonical regex source — pure pattern string, not a `RegExp`.
/// Callers build their own `RegExp` instance with whatever flags they need.
const String kCitationMarkerPattern =
    r'\[\[ref:([A-Za-z0-9_-]+):([A-Za-z0-9_-]+)(?::([a-z_]+))?\]\]';
