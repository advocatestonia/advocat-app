// _shared/tracing.ts
// -----------------------------------------------------------------------------
// Distributed tracing helper. ONE trace_id per user-initiated request flows
// through every edge fn + RPC + audit row, so debugging one user complaint
// becomes:
//
//   SELECT * FROM app.trace_timeline WHERE trace_id = $1 ORDER BY happened_at;
//
// instead of grep-and-eyeball across agent_runs / agent_audit_log /
// email_triage_results / case_timeline_events / Supabase logs.
//
// Three primitives:
//   getOrCreateTraceId(req)    — read `x-trace-id` from request OR mint a
//                                fresh UUIDv4. Always returns a valid UUID.
//   propagateTraceId(headers, traceId) — write `x-trace-id` into outbound
//                                headers (for internal edge-fn calls).
//   withTrace(traceId, fn)     — run an async block with `[trace=<short>]`
//                                in console output, so log scraping by
//                                trace_id works without extra plumbing.
//
// All three are no-throw / no-effect on bad input — failure mode is just
// "we lose the trace for this request" rather than 500ing the user.
// -----------------------------------------------------------------------------

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Strict UUID validator. */
export function isValidTraceId(s: string | null | undefined): boolean {
  if (!s) return false;
  return UUID_RE.test(s);
}

/** Mint a fresh UUIDv4. Uses crypto.randomUUID when available. */
export function newTraceId(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  // Fallback for older runtimes. Not cryptographically perfect but
  // sufficient for trace_id collision avoidance.
  const r = (n: number) =>
    Array.from(crypto.getRandomValues(new Uint8Array(n)))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  return `${r(4)}-${r(2)}-${r(2)}-${r(2)}-${r(6)}`;
}

/**
 * Read x-trace-id from the request; if missing or malformed, mint a new
 * UUIDv4. NEVER throws. The returned string is always a valid UUID.
 *
 * Header name matches W3C trace-context spirit but uses a simpler single
 * UUID (we don't need spans / parents — Supabase is a flat fan-out).
 */
export function getOrCreateTraceId(req: Request): string {
  try {
    const raw = req.headers.get("x-trace-id");
    if (raw && isValidTraceId(raw)) return raw.toLowerCase();
  } catch (_) { /* fall through */ }
  return newTraceId();
}

/**
 * Write x-trace-id into outbound Headers so internal edge-fn calls (e.g.
 * email-inbox-sync → email-triage, triage-retry-tick → email-triage) carry
 * the same trace_id forward. Idempotent on existing header value.
 */
export function propagateTraceId(
  headers: Headers | Record<string, string>,
  traceId: string,
): void {
  if (!isValidTraceId(traceId)) return;
  try {
    if (headers instanceof Headers) {
      headers.set("x-trace-id", traceId);
    } else {
      headers["x-trace-id"] = traceId;
    }
  } catch (_) { /* no-op */ }
}

/**
 * Short form of a trace_id for log lines: first 8 hex chars.
 * E.g. "deadbeef" — collision-safe enough for grepping a 5-minute window.
 */
export function shortTrace(traceId: string | null | undefined): string {
  if (!traceId || !isValidTraceId(traceId)) return "------";
  return traceId.slice(0, 8);
}

/**
 * Run an async function with `[trace=<short>]` log context. Restores the
 * previous console.log/warn/error on exit so tests are clean.
 *
 * IMPORTANT: this only patches the console object — it does NOT use
 * AsyncLocalStorage (Deno doesn't have native ALS) so concurrent
 * withTrace calls from one isolate would interleave logs. The Supabase
 * Edge runtime spawns one isolate per request which makes this a
 * non-issue in production. For tests, wrap each test in its own block.
 */
export async function withTrace<T>(
  traceId: string,
  fn: () => Promise<T>,
): Promise<T> {
  const tag = `[trace=${shortTrace(traceId)}]`;
  const origLog = console.log;
  const origWarn = console.warn;
  const origError = console.error;
  console.log = (...args: unknown[]) => origLog(tag, ...args);
  console.warn = (...args: unknown[]) => origWarn(tag, ...args);
  console.error = (...args: unknown[]) => origError(tag, ...args);
  try {
    return await fn();
  } finally {
    console.log = origLog;
    console.warn = origWarn;
    console.error = origError;
  }
}

/**
 * Helper: build an Anthropic / Supabase fetch headers object with trace
 * propagation already wired. Call this instead of manually constructing
 * Headers to avoid forgetting the propagation step.
 */
export function tracedHeaders(
  traceId: string,
  base: Record<string, string> = {},
): Record<string, string> {
  return { ...base, "x-trace-id": traceId };
}
