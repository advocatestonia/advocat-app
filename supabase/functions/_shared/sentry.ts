// _shared/sentry.ts
// -----------------------------------------------------------------------------
// Single source of truth for Sentry error reporting across all Advocat edge
// functions. Designed for incremental rollout: wrap the top critical fns
// (claude-proxy, email-triage, agent-approve, vault-upload, stripe-webhook,
// apple-iap-verify) first; the rest can be wrapped opportunistically.
//
// Properties enforced by this module:
//
//   1. Backward-compat. Without SENTRY_DSN in the environment, initSentry is
//      a no-op and withSentry collapses to a thin try/throw shim — fns behave
//      exactly as before for local dev / preview deploys.
//
//   2. PII safety > completeness. We never send:
//        - request bodies (may contain chat messages, email bodies, vault
//          file metadata, Stripe customer IDs, Apple receipts)
//        - cookies / Authorization headers
//        - user email/name (only a stable hashed id)
//        - URL query params named after known PII keys
//      And we drop the event entirely if the top-level message smells like
//      PII (free-text email address, FI hetu-style id, etc.).
//
//   3. Never swallow. The wrapped handler captures + flushes + RE-THROWS so
//      the edge runtime still returns its real HTTP status. We do not
//      synthesise a 500 — that breaks the fn's contract with the caller.
//
//   4. Low volume. tracesSampleRate=0.05 — edge fns are high-volume and we
//      only need a representative sample for perf work. Errors are always 1.0.
//
//   5. Idempotent. initSentry uses a module-level `initialized` flag so multiple
//      fns sharing a process won't re-init.
// -----------------------------------------------------------------------------

import * as Sentry from "@sentry/deno";

let initialized = false;

/**
 * Initialize the Sentry client for a given edge function. Idempotent: safe to
 * call on every request — the flag ensures only the first call actually
 * configures the SDK. Without SENTRY_DSN we silently skip (dev mode).
 */
export function initSentry(fnName: string): void {
  if (initialized) return;
  const dsn = Deno.env.get("SENTRY_DSN");
  if (!dsn) {
    // Mark as initialized so we don't repeatedly probe env. Without a DSN
    // Sentry.captureException is a harmless no-op anyway.
    initialized = true;
    return;
  }

  Sentry.init({
    dsn,
    environment: Deno.env.get("SENTRY_ENV") ?? "production",
    release: Deno.env.get("SENTRY_RELEASE") ?? "unknown",
    tracesSampleRate: 0.05, // 5% perf sample — edge fns are high volume
    sendDefaultPii: false,
    maxBreadcrumbs: 30,
    beforeSend: scrubPii,
    initialScope: {
      tags: { fn: fnName, runtime: "deno-edge" },
    },
  });

  initialized = true;
}

/**
 * Keys that, when present as request data / extras / query params, are
 * always redacted. Lowercased; matching is case-insensitive.
 */
const PII_KEYS: ReadonlySet<string> = new Set([
  "email",
  "name",
  "phone",
  "address",
  "case_id",
  "draft_id",
  "vault_doc_id",
  "thread_id",
  "user_message",
  "ai_response",
  "receipt",
  "receipt_data",
  "stripe_customer_id",
  "stripe_subscription_id",
  "transaction_id",
  "authorization",
  "cookie",
  "set-cookie",
  "x-api-key",
  "api_key",
  "apple_iap_shared_secret",
  "anthropic_api_key",
  "supabase_service_role_key",
]);

/** Lowercase header names that must never reach Sentry. */
const SENSITIVE_HEADERS: ReadonlySet<string> = new Set([
  "authorization",
  "cookie",
  "set-cookie",
  "x-api-key",
  "apikey",
  "stripe-signature",
]);

const EMAIL_RE = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/;
// Loose FI/EE national-id / case-number heuristic — e.g. "5500/R/75170/25",
// "R20/123/2025", "010180-123A". We err on the side of dropping events.
const ID_LIKE_RE = /\b[A-Z]{1,5}[\d/]{5,}\b|\b\d{6}-\d{3}[A-Z]\b/;

/**
 * beforeSend hook. Returns null to drop an event entirely (preferred when the
 * top-level message looks like raw user content), otherwise mutates the event
 * in-place to strip identifying data.
 *
 * Typed loosely (Event vs ErrorEvent) so the same function can be used as a
 * plain unit-test helper without forcing callers to construct an ErrorEvent.
 * Sentry's beforeSend signature is structurally compatible.
 */
// deno-lint-ignore no-explicit-any
export function scrubPii(event: any): any {
  // 1. Drop the whole event if the headline message smells like PII.
  const msg = event.message ?? "";
  if (msg && looksLikePii(msg)) return null;

  // Also scan exception values — Anthropic / Postgres errors sometimes echo
  // the offending input back. If we find PII there, drop the event.
  const exceptions = event.exception?.values ?? [];
  for (const ex of exceptions) {
    if (ex.value && looksLikePii(ex.value)) return null;
  }

  // 2. User — strip email/name, keep only a stable hashed id.
  if (event.user) {
    const id = event.user.id ?? event.user.email ?? event.user.username;
    event.user = { id: hashUserId(typeof id === "string" ? id : undefined) };
  }

  // 3. Request — drop body & cookies outright, scrub headers & URL query.
  if (event.request) {
    delete event.request.data;
    delete event.request.cookies;

    if (event.request.headers) {
      const safe: Record<string, string> = {};
      for (const [k, v] of Object.entries(event.request.headers)) {
        if (SENSITIVE_HEADERS.has(k.toLowerCase())) {
          safe[k] = "[REDACTED]";
        } else {
          safe[k] = typeof v === "string" ? v : String(v);
        }
      }
      event.request.headers = safe;
    }

    if (typeof event.request.url === "string") {
      event.request.url = scrubUrl(event.request.url);
    }
    // query_string is a separate field in newer SDK versions.
    if (event.request.query_string) {
      delete event.request.query_string;
    }
  }

  // 4. Extras — redact known PII keys by name.
  if (event.extra) {
    for (const key of Object.keys(event.extra)) {
      if (PII_KEYS.has(key.toLowerCase())) {
        event.extra[key] = "[REDACTED]";
      }
    }
  }

  // 5. Breadcrumbs — same redaction on .data, drop messages that look like PII.
  if (event.breadcrumbs) {
    event.breadcrumbs = event.breadcrumbs.map((b: Sentry.Breadcrumb) => {
      const nb: Sentry.Breadcrumb = { ...b };
      if (nb.message && looksLikePii(nb.message)) {
        nb.message = "[REDACTED]";
      }
      if (nb.data) {
        const safeData: Record<string, unknown> = {};
        for (const [k, v] of Object.entries(nb.data)) {
          safeData[k] = PII_KEYS.has(k.toLowerCase()) ? "[REDACTED]" : v;
        }
        nb.data = safeData;
      }
      return nb;
    });
  }

  return event;
}

export function looksLikePii(s: string): boolean {
  if (!s) return false;
  return EMAIL_RE.test(s) || ID_LIKE_RE.test(s);
}

/**
 * Deterministic, fast, dependency-free hash. Not cryptographic — we just need
 * a stable opaque token so the same user maps to the same Sentry user-id
 * across events without revealing the underlying identifier.
 */
export function hashUserId(id?: string): string {
  if (!id) return "anon";
  let h = 0;
  for (let i = 0; i < id.length; i++) {
    h = ((h << 5) - h) + id.charCodeAt(i);
    h |= 0; // force 32-bit
  }
  return Math.abs(h).toString(36).substring(0, 12);
}

export function scrubUrl(url: string): string {
  try {
    const u = new URL(url);
    for (const k of [...u.searchParams.keys()]) {
      if (PII_KEYS.has(k.toLowerCase())) {
        u.searchParams.set(k, "[REDACTED]");
      }
    }
    return u.toString();
  } catch {
    return "[invalid url]";
  }
}

/**
 * Wrap a Deno.serve handler with automatic Sentry error capture.
 *
 * On success: passes the Response through unchanged.
 * On throw:   captureException → flush(2s) → RE-THROW. The Deno edge runtime
 *             will surface its built-in 500 response, preserving existing
 *             error-handling semantics for callers.
 *
 * The handler is also responsible for catching its own expected errors and
 * returning proper HTTP status codes (4xx). This wrapper only fires when an
 * exception escapes — i.e. an unexpected bug.
 */
export function withSentry(
  fnName: string,
  handler: (req: Request) => Promise<Response> | Response,
): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    initSentry(fnName);
    try {
      return await handler(req);
    } catch (err) {
      try {
        Sentry.captureException(err, (scope: Sentry.Scope) => {
          let path = "[invalid url]";
          try {
            path = new URL(req.url).pathname;
          } catch { /* ignore */ }
          scope.setTag("path", path);
          scope.setTag("method", req.method);
          scope.setLevel("error");
          return scope;
        });
        // Best-effort flush. Edge fns can be torn down fast — 2s ceiling.
        await Sentry.flush(2000);
      } catch (sentryErr) {
        // NEVER let Sentry itself break the request path.
        console.error(
          `[sentry] failed to capture in ${fnName}:`,
          sentryErr instanceof Error ? sentryErr.message : String(sentryErr),
        );
      }
      // Re-throw the ORIGINAL error so the runtime returns its real status.
      throw err;
    }
  };
}

export { Sentry };
