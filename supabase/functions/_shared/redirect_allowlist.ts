// _shared/redirect_allowlist.ts
// -----------------------------------------------------------------------------
// Wave 1 fix P1-08 (2026-05-28) — open-redirect protection for Stripe
// Checkout `success_url` / `cancel_url`.
//
// Stripe accepts arbitrary URLs for these fields and will 302 the user there
// after payment. If the edge fn passes them through unchecked, a phishing
// attacker can:
//   1. Get a victim to click a real Stripe Checkout URL (legitimate domain,
//      valid TLS, paid flow).
//   2. Victim completes payment.
//   3. Stripe redirects to `success_url = https://attacker.example/fake-receipt`
//      which is pixel-perfect for our receipt page.
//   4. Attacker harvests the post-payment session token / CSRF token / etc.
//
// Mitigation: refuse any success_url / cancel_url whose host is NOT in
// ALLOWED_REDIRECT_HOSTS. The list defaults to advocat.ee + *.advocat.ee.
// localhost is added when ALLOW_LOCALHOST_REDIRECT=true (staging only).
// -----------------------------------------------------------------------------

const DEFAULT_ALLOWED_HOSTS = [
  "advocat.ee",
];

const DEFAULT_ALLOWED_SUFFIXES = [
  ".advocat.ee", // covers app.advocat.ee, admin.advocat.ee, www.advocat.ee
];

/**
 * Parse the comma-separated ALLOWED_REDIRECT_HOSTS env var into exact-match
 * hosts. Each entry is lower-cased and trimmed; empties dropped. If the env
 * var is unset, returns the default advocat.ee allowlist.
 */
function loadAllowedHosts(): { exact: string[]; suffixes: string[] } {
  const raw = (Deno.env.get("ALLOWED_REDIRECT_HOSTS") ?? "").trim();
  if (!raw) {
    return {
      exact: DEFAULT_ALLOWED_HOSTS.slice(),
      suffixes: DEFAULT_ALLOWED_SUFFIXES.slice(),
    };
  }
  const exact: string[] = [];
  const suffixes: string[] = [];
  for (const entry of raw.split(",")) {
    const v = entry.trim().toLowerCase();
    if (!v) continue;
    if (v.startsWith("*.")) {
      // wildcard subdomain — match any host ending with ".rest"
      suffixes.push(v.slice(1)); // "*.example.com" → ".example.com"
    } else {
      exact.push(v);
    }
  }
  return { exact, suffixes };
}

/**
 * Returns true when `url` resolves to a host inside the allowlist. False
 * means the URL is unsafe to forward to Stripe.
 *
 * Rules:
 *   - URL MUST parse; relative URLs and javascript: / data: schemes are rejected.
 *   - Protocol MUST be http or https.
 *   - Host MUST equal an exact-list entry OR end with a suffix-list entry.
 *   - localhost / 127.0.0.1 / ::1 are allowed iff ALLOW_LOCALHOST_REDIRECT=true.
 */
export function isAllowedRedirect(url: string): boolean {
  if (typeof url !== "string" || url.length === 0) return false;

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }

  // Only allow http/https. Block javascript:, data:, file:, etc.
  const proto = parsed.protocol.toLowerCase();
  if (proto !== "https:" && proto !== "http:") return false;

  const host = parsed.hostname.toLowerCase();
  if (!host) return false;

  // Optional localhost allowance for staging.
  const allowLocalhost =
    (Deno.env.get("ALLOW_LOCALHOST_REDIRECT") ?? "false").toLowerCase() ===
      "true";
  if (allowLocalhost) {
    if (host === "localhost" || host === "127.0.0.1" || host === "[::1]") {
      return true;
    }
  }

  const { exact, suffixes } = loadAllowedHosts();
  if (exact.includes(host)) return true;
  for (const suffix of suffixes) {
    if (host.endsWith(suffix)) return true;
  }
  return false;
}

/**
 * Validate the optional success_url / cancel_url body params against the
 * allowlist. Returns either a {ok: true, success, cancel} pair (both resolved
 * to defaults if absent) or {ok: false, reason} for the caller to 400.
 */
export function validateCheckoutRedirects(
  successUrl: unknown,
  cancelUrl: unknown,
  defaults: { success: string; cancel: string },
): { ok: true; success: string; cancel: string } | { ok: false; reason: string } {
  // Defaults MUST themselves be inside the allowlist — if they're not, the
  // operator misconfigured ALLOWED_REDIRECT_HOSTS. Fail loud rather than
  // silently emit an unsafe URL.
  if (!isAllowedRedirect(defaults.success) || !isAllowedRedirect(defaults.cancel)) {
    return { ok: false, reason: "redirect_defaults_not_in_allowlist" };
  }

  let success = defaults.success;
  if (successUrl !== undefined && successUrl !== null && successUrl !== "") {
    if (typeof successUrl !== "string") {
      return { ok: false, reason: "success_url_not_string" };
    }
    if (!isAllowedRedirect(successUrl)) {
      return { ok: false, reason: "success_url_not_in_allowlist" };
    }
    success = successUrl;
  }

  let cancel = defaults.cancel;
  if (cancelUrl !== undefined && cancelUrl !== null && cancelUrl !== "") {
    if (typeof cancelUrl !== "string") {
      return { ok: false, reason: "cancel_url_not_string" };
    }
    if (!isAllowedRedirect(cancelUrl)) {
      return { ok: false, reason: "cancel_url_not_in_allowlist" };
    }
    cancel = cancelUrl;
  }

  return { ok: true, success, cancel };
}
