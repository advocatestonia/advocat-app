// verify-lawyer/registry.ts
// -----------------------------------------------------------------------------
// Bar-association registry adapters.
//
// Two sources, both publicly published as HTML directories:
//   * EE — https://advokatuur.ee/et/advokaadid
//   * FI — https://asianajajaliitto.fi/asianajajat
//
// Both pages are search-style; the actual record we need is a small subset:
//   { name: string, bar_id: string, firm?: string, city?: string, email?: string }
//
// The Edge runtime cannot rely on a stable HTML schema — both sites have
// been redesigned in the past 18 months. Rather than couple the verifier
// to fragile CSS selectors, we fetch the list page (or a per-letter slice)
// and run a tolerant text-pattern match: bar_id token + name token must
// both occur in the same response body, within reasonable proximity.
//
// This is not perfect — false positives are possible if two attorneys
// share a name and one of their IDs accidentally appears as a substring.
// That is why borderline matches (name token found but bar_id NOT found,
// or vice versa, or proximity > 1000 chars) are queued for manual review
// instead of auto-approved.
//
// All network calls are wrapped in a 5s AbortController. A timeout / 5xx
// degrades to MatchOutcome.unknown — never to auto-approve. The audit
// table captures the registry response excerpt for forensic review.
//
// Test seam: the adapters accept an optional `fetchImpl` so the test suite
// can inject a deterministic HTML fixture without hitting the network.
// -----------------------------------------------------------------------------

export type FetchLike = (input: string | URL, init?: RequestInit) => Promise<Response>;

export type MatchOutcome =
  | { kind: "match"; confidence: number; excerpt: string }
  | { kind: "borderline"; reason: string; excerpt: string }
  | { kind: "miss"; reason: string }
  | { kind: "unknown"; reason: string };

export interface RegistryQuery {
  country: "FI" | "EE";
  barId: string;
  fullName: string;
}

const REGISTRY_TIMEOUT_MS = 5_000;

// User-Agent: identify ourselves so the registry operators can reach us if
// scraping ever becomes an issue. The address resolves to the team inbox.
const USER_AGENT =
  "Advocat-VerifyLawyer/1.0 (+https://advocat.ee; verification@advocat.ee)";

const EE_REGISTRY_URL = "https://advokatuur.ee/et/advokaadid";
const FI_REGISTRY_URL = "https://asianajajaliitto.fi/asianajajat";

/**
 * Top-level entry. Picks the country-specific adapter and returns a
 * MatchOutcome the edge handler can act on. Never throws — registry
 * failures degrade to MatchOutcome.unknown.
 */
export async function lookupLawyer(
  q: RegistryQuery,
  fetchImpl: FetchLike = fetch,
): Promise<MatchOutcome> {
  if (q.country === "EE") {
    return await safeLookup(() => lookupEE(q, fetchImpl));
  }
  if (q.country === "FI") {
    return await safeLookup(() => lookupFI(q, fetchImpl));
  }
  return { kind: "miss", reason: "unsupported_country" };
}

async function safeLookup(
  inner: () => Promise<MatchOutcome>,
): Promise<MatchOutcome> {
  try {
    return await inner();
  } catch (e) {
    return {
      kind: "unknown",
      reason: `registry_error: ${String(e).slice(0, 200)}`,
    };
  }
}

// ─── EE: Advokatuur ──────────────────────────────────────────────────────────
//
// The EE list is a single page with ~1.2K rows. We fetch it once per
// invocation. Bar IDs at advokatuur.ee are short numerical strings; the
// full name appears in proximity. A successful match is bar_id and ALL
// name tokens both visible in the response, with the first occurrence
// within 800 chars of each other.

export async function lookupEE(
  q: RegistryQuery,
  fetchImpl: FetchLike,
): Promise<MatchOutcome> {
  const html = await fetchWithTimeout(EE_REGISTRY_URL, fetchImpl);
  if (!html) return { kind: "unknown", reason: "ee_registry_unreachable" };
  return matchInRegistry(html, q);
}

// ─── FI: Asianajajaliitto ────────────────────────────────────────────────────
//
// Same approach. The FI list is paginated alphabetically; we request the
// page corresponding to the surname's first letter (mediated by ?letter=).
// If the surname starts with a non-Latin character the fallback fetches
// the index page and relies on tolerant text matching.

export async function lookupFI(
  q: RegistryQuery,
  fetchImpl: FetchLike,
): Promise<MatchOutcome> {
  const surname = extractSurname(q.fullName);
  const firstLetter = (surname[0] ?? "").toLowerCase();
  const url = /^[a-zåäö]$/.test(firstLetter)
    ? `${FI_REGISTRY_URL}?letter=${encodeURIComponent(firstLetter)}`
    : FI_REGISTRY_URL;
  const html = await fetchWithTimeout(url, fetchImpl);
  if (!html) return { kind: "unknown", reason: "fi_registry_unreachable" };
  return matchInRegistry(html, q);
}

// ─── Generic text matcher ────────────────────────────────────────────────────
//
// Both registries are HTML; we don't parse the DOM. We lowercase the body,
// strip diacritics, collapse whitespace, then test:
//   1. Does the bar_id appear verbatim? (Required — IDs are unique.)
//   2. Do ALL name tokens (>=3 chars) appear?
//   3. Is the first bar_id occurrence within 800 chars of every name token?
//
// 1+2+3 → match (auto-approve).
// 1+2   → borderline (proximity failed; queue for manual review).
// 1 only OR 2 only → borderline (likely OK; queue).
// neither → miss.

const PROXIMITY_WINDOW = 800;

export function matchInRegistry(rawHtml: string, q: RegistryQuery): MatchOutcome {
  const normalised = normalise(rawHtml);
  const id = normalise(q.barId);
  if (id.length === 0) {
    return { kind: "miss", reason: "empty_bar_id" };
  }
  const nameTokens = tokeniseName(q.fullName);
  if (nameTokens.length === 0) {
    return { kind: "miss", reason: "empty_name" };
  }

  const idAt = normalised.indexOf(id);
  const idHit = idAt >= 0;

  const tokenHits = nameTokens.map((t) => ({
    token: t,
    pos: normalised.indexOf(t),
  }));
  const allTokensHit = tokenHits.every((h) => h.pos >= 0);

  if (!idHit && !allTokensHit) {
    return { kind: "miss", reason: "no_id_or_name" };
  }
  if (!idHit) {
    return {
      kind: "borderline",
      reason: "name_found_id_missing",
      excerpt: excerptAround(normalised, tokenHits[0].pos),
    };
  }
  if (!allTokensHit) {
    return {
      kind: "borderline",
      reason: "id_found_name_missing",
      excerpt: excerptAround(normalised, idAt),
    };
  }

  // Both found. Check proximity to filter out coincidental ID-on-page-1 +
  // name-on-page-50 false positives.
  const minTokenPos = Math.min(...tokenHits.map((h) => h.pos));
  const maxTokenPos = Math.max(...tokenHits.map((h) => h.pos));
  const tokenSpread = maxTokenPos - minTokenPos;
  const distance = Math.min(
    Math.abs(idAt - minTokenPos),
    Math.abs(idAt - maxTokenPos),
  );

  if (tokenSpread > PROXIMITY_WINDOW || distance > PROXIMITY_WINDOW) {
    return {
      kind: "borderline",
      reason: "id_and_name_too_far_apart",
      excerpt: excerptAround(normalised, idAt),
    };
  }

  return {
    kind: "match",
    confidence: confidenceScore(distance, tokenSpread),
    excerpt: excerptAround(normalised, idAt),
  };
}

// ─── Helpers ────────────────────────────────────────────────────────────────

async function fetchWithTimeout(
  url: string,
  fetchImpl: FetchLike,
): Promise<string | null> {
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), REGISTRY_TIMEOUT_MS);
  try {
    const res = await fetchImpl(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "en,et,fi",
      },
      signal: ctl.signal,
    });
    if (!res.ok) return null;
    const txt = await res.text();
    return txt;
  } catch {
    return null;
  } finally {
    clearTimeout(t);
  }
}

/** Lowercase, strip diacritics, collapse whitespace. */
export function normalise(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFKD")
    // strip combining marks
    .replace(/[\u0300-\u036f]/g, "")
    // collapse all whitespace runs into single space — keeps proximity
    // measurements meaningful across HTML formatting.
    .replace(/\s+/g, " ");
}

/**
 * Split full_name into searchable tokens. Drops tokens shorter than 3
 * chars (initials and connectives like "de", "von" — too noisy to match
 * on). Returns normalised tokens.
 */
export function tokeniseName(fullName: string): string[] {
  return normalise(fullName)
    .split(/[\s,;]+/)
    .filter((t) => t.length >= 3);
}

/** Pull the (probable) surname for FI registry's letter-paged URL. */
function extractSurname(fullName: string): string {
  const parts = fullName.trim().split(/\s+/);
  return parts.length > 0 ? parts[parts.length - 1] : "";
}

/** ±200-char window around a hit position, capped for audit storage. */
function excerptAround(haystack: string, pos: number): string {
  const start = Math.max(0, pos - 200);
  const end = Math.min(haystack.length, pos + 200);
  return haystack.slice(start, end);
}

/** 0..1 confidence based on tightness of the match. */
function confidenceScore(distance: number, spread: number): number {
  const distScore = 1 - Math.min(distance, PROXIMITY_WINDOW) / PROXIMITY_WINDOW;
  const spreadScore = 1 - Math.min(spread, PROXIMITY_WINDOW) / PROXIMITY_WINDOW;
  // Round to 2 dp; UI never shows it but audit rows are easier to read.
  return Math.round((0.6 * distScore + 0.4 * spreadScore) * 100) / 100;
}
