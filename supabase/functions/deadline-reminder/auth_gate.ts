// Pure auth-gate helper for deadline-reminder (Sprint 0 — FIX-5).
// -----------------------------------------------------------------------------
// Extracted from index.ts so it can be imported from tests without the
// top-level `serve(...)` side-effect starting an HTTP listener.
// -----------------------------------------------------------------------------

/** Result of the cron-secret gate: either allowed or a ready-to-return 4xx. */
export type CronGateResult =
  | { kind: "allow" }
  | { kind: "deny"; status: number; body: { error: string } };

/** Constant-time string comparison (prevents a timing oracle on the secret). */
export function timingSafeEqualStr(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) {
    r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return r === 0;
}

/**
 * Checks whether a cron caller has presented the expected secret.
 * Fail-closed: if the server is not configured with a secret, refuse.
 */
export function checkCronSecret(
  providedHeader: string | null,
  expectedSecret: string | undefined,
): CronGateResult {
  if (!expectedSecret) {
    return {
      kind: "deny",
      status: 500,
      body: { error: "Cron secret not configured" },
    };
  }
  if (!providedHeader) {
    return {
      kind: "deny",
      status: 401,
      body: { error: "Missing cron secret" },
    };
  }
  if (!timingSafeEqualStr(providedHeader, expectedSecret)) {
    return {
      kind: "deny",
      status: 401,
      body: { error: "Invalid cron secret" },
    };
  }
  return { kind: "allow" };
}
